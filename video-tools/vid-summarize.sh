#!/usr/bin/env bash

# Maakt een samenvatting van het transcript van een mediabestand.

# shellcheck disable=SC2034  # VID_ANALYSE_BACKEND wordt via lib/common.sh gelezen

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

AUTEUR="${VID_AUTEUR:-}"
TITEL="${VID_TITEL:-}"
PROFIEL="${VID_PROFIEL:-}"
RUBRIEK="${VID_RUBRIEK:-}"

VID_UIT="${VID_UIT:-}"
VID_FORCE="${VID_FORCE:-false}"

usage() {
    cat <<EOF
Gebruik: $(basename "$0") [OPTIES] <mediabestand|werkmap>

Analyseert <werkmap>/transcript.tsv en schrijft <werkmap>/samenvatting.md:
kernboodschap, opbouw en de punten die de opname draagt.

OPTIES:
    -u, --uit MAP      Werkmap (standaard: <map van bron>/<naam zonder ext>)
    -a, --auteur NAAM  Naam van de spreker, voor de kop
    -t, --titel TITEL  Titel van de bron, voor de kop en de analyse
    -p, --profiel NAAM Rubriek uit prompts/<NAAM>.md (standaard: samenvatting)
    -r, --rubriek FILE Eigen rubriekbestand
    -b, --backend CLI  claude of opencode (standaard: auto)
    -m, --model MODEL  Model voor de CLI; gaat ongewijzigd mee
    -f, --force        Maak opnieuw, ook als de samenvatting er al staat
    -h, --help         Toon deze hulptekst

OMGEVINGSVARIABELEN:
    VID_ANALYSE_BACKEND      claude, opencode of auto (standaard: auto)
    VID_MODEL                Model voor de CLI
    VID_ANALYSE_TIMEOUT      Timeout in seconden (standaard: 600)
    VID_PROFIEL              Rubriek uit prompts/<naam>.md
    VID_RUBRIEK              Pad naar een eigen rubriekbestand
    VID_AUTEUR               Naam van de spreker
    VID_TITEL                Titel van de bron

VOORBEELDEN:
    $(basename "$0") interview.mp4
    $(basename "$0") --force interview/
EOF
}

while [[ $# -gt 0 ]]; do
    if vid_parse_common "$@"; then
        shift "$VID_CONSUMED"
        continue
    fi
    case "$1" in
        -a|--auteur)  AUTEUR="$2"; shift 2 ;;
        -t|--titel)   TITEL="$2"; shift 2 ;;
        -p|--profiel) PROFIEL="$2"; shift 2 ;;
        -r|--rubriek) RUBRIEK="$2"; shift 2 ;;
        -b|--backend) VID_ANALYSE_BACKEND="$2"; shift 2 ;;
        -m|--model)   VID_MODEL="$2"; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        --)           shift; break ;;
        -*)           usage >&2; die "Onbekende optie: $1" ;;
        *)            break ;;
    esac
done

[ $# -ge 1 ] || { usage >&2; die "Geef een mediabestand of werkmap op."; }

INVOER="${1%/}"
BRON=""
if [ -d "$INVOER" ]; then
    WORKMAP="$INVOER"
    for kandidaat in "$WORKMAP"/video.mp4 "$WORKMAP"/video.mkv "$WORKMAP"/video.webm; do
        [ -f "$kandidaat" ] && { BRON="$kandidaat"; break; }
    done
elif [ -f "$INVOER" ]; then
    BRON="$INVOER"
    WORKMAP="${VID_UIT:-$(werkmap_voor "$BRON")}"
else
    die "Bestaat niet: $INVOER"
fi

[ -n "$VID_UIT" ] && WORKMAP="$VID_UIT"
mkdir -p "$WORKMAP"
WORKMAP="$(cd "$WORKMAP" && pwd)"

TSV="$WORKMAP/transcript.tsv"
DOC="$WORKMAP/samenvatting.md"

[ -f "$TSV" ] || die "Transcript ontbreekt: $TSV — draai eerst vid-transcribe.sh"

if [ -f "$DOC" ] && [ "$VID_FORCE" = false ]; then
    log_skip "Samenvatting staat er al: $DOC"
    exit 0
fi

if [ -z "$RUBRIEK" ]; then
    RUBRIEK="$SCRIPT_DIR/prompts/${PROFIEL:-samenvatting}.md"
fi
[ -f "$RUBRIEK" ] || die "Rubriek ontbreekt: $RUBRIEK"

BACKEND="$(vid_analyse_backend)"
if [ -z "$BACKEND" ]; then
    die "Geen analyse-backend gevonden. Installeer de Claude Code CLI of de OpenCode CLI, of kies er een met --backend."
fi
if [ -z "${VID_MODEL:-}" ]; then
    VID_MODEL="$(vid_standaard_model "$BACKEND")"
fi
require_tools awk timeout "$BACKEND"

SEGMENTEN=$(( $(wc -l < "$TSV") - 1 ))
[ "$SEGMENTEN" -gt 0 ] || die "Transcript bevat geen segmenten: $TSV"

DUUR=""
if [ -n "$BRON" ] && [ -f "$BRON" ] && command -v ffprobe >/dev/null 2>&1; then
    DUUR="$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$BRON" 2>/dev/null || echo "")"
fi
if [ -z "$DUUR" ]; then
    DUUR_MS="$(awk -F'\t' 'NR>1 { if ($2+0 > max) max=$2+0 } END { print max+0 }' "$TSV")"
    DUUR="$(awk -v ms="$DUUR_MS" 'BEGIN { printf "%.0f", ms/1000 }')"
fi

NAAM="$TITEL"
[ -n "$NAAM" ] || { [ -n "$BRON" ] && NAAM="$(basename "${BRON%.*}")"; }
[ -n "$NAAM" ] || NAAM="$(basename "$WORKMAP")"

TMP_META="$(mktemp)"; TMP_OUT="$(mktemp)"; TMP_DOC="$(mktemp)"
trap 'rm -f "$TMP_META" "$TMP_OUT" "$TMP_DOC"' EXIT

{
    echo "# Metadata van deze bron"
    echo
    [ -n "$TITEL" ] && echo "Titel: $TITEL"
    [ -n "$BRON" ]  && echo "Bestand: $(basename -- "$BRON")"
    [ -n "$DUUR" ]  && echo "Duur: $(hhmmss "${DUUR%.*}")"
    echo
    if [ -n "$AUTEUR" ]; then
        echo "Spreker: $AUTEUR"
        echo
        echo "Gebruik deze naam waar dat natuurlijk is; verzin geen andere namen."
    else
        echo "De spreker is niet bekend. Noem geen naam en verzin er geen."
    fi
    echo
} > "$TMP_META"

log_info "Samenvatten: $TSV ($SEGMENTEN segmenten)"
log_info "  Backend: ${BACKEND}${VID_MODEL:+, model: $VID_MODEL}"
log_info "  Rubriek: $(basename "$RUBRIEK")"

if ! cat "$TMP_META" "$RUBRIEK" "$TSV" | analyseer "$BACKEND" > "$TMP_OUT"; then
    die "De analyse is mislukt; $DOC is niet aangepast."
fi

if [ ! -s "$TMP_OUT" ]; then
    die "De analyse gaf lege uitvoer; $DOC is niet aangepast."
fi

if ! grep -qE '^##[[:space:]]*Kernboodschap' "$TMP_OUT"; then
    log_error "De analyse leverde geen herkenbare samenvatting op."
    log_error "Eerste regels van wat er wel kwam:"
    head -5 "$TMP_OUT" | sed 's/^/       /' >&2
    die "$DOC is niet aangepast."
fi

{
    echo "# Samenvatting — ${NAAM}"
    echo
    if [ -n "$TITEL" ]; then
        echo "**${TITEL}**"
        [ -n "$AUTEUR" ] && echo "door ${AUTEUR}"
        echo
    elif [ -n "$AUTEUR" ]; then
        echo "**${NAAM}** door ${AUTEUR}"
        echo
    fi
    [ -n "$BRON" ] && echo "- Bron: \`${BRON}\`"
    [ -n "$DUUR" ] && echo "- Duur: $(hhmmss "${DUUR%.*}")"
    echo "- Transcript: \`${TSV}\`"
    echo
    cat "$TMP_OUT"
} > "$TMP_DOC"

mv "$TMP_DOC" "$DOC"

log_success "Samenvatting klaar"
echo "  $DOC"
