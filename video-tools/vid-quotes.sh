#!/usr/bin/env bash

# Kiest losse quotes uit het transcript, gestuurd door de samenvatting.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

RENDERER="$SCRIPT_DIR/lib/render-quotes.awk"
MIN_S="${VID_QUOTE_MIN:-5}"
MAX_S="${VID_QUOTE_MAX:-30}"
MAX_AANTAL="${VID_QUOTE_MAX_AANTAL:-20}"
AUTEUR="${VID_AUTEUR:-}"
TITEL="${VID_TITEL:-}"
PROFIEL="${VID_PROFIEL:-}"
RUBRIEK="${VID_RUBRIEK:-}"

# shellcheck disable=SC2034  # VID_ANALYSE_BACKEND wordt via lib/common.sh gelezen
VID_UIT="${VID_UIT:-}"
VID_FORCE="${VID_FORCE:-false}"

usage() {
    cat <<EOF
Gebruik: $(basename "$0") [OPTIES] <mediabestand|werkmap>

Leest <werkmap>/transcript.tsv en <werkmap>/samenvatting.md en schrijft
<werkmap>/quotes.md: hoogstens ${MAX_AANTAL} losse uitspraken met tijdcode,
duur, letterlijke tekst en de verwijzing naar de samenvatting.

Ontbreekt de samenvatting, dan wordt die eerst gemaakt.

OPTIES:
    -u, --uit MAP      Werkmap (standaard: <map van bron>/<naam zonder ext>)
    -a, --auteur NAAM  Naam van de spreker, voor de titels
    -t, --titel TITEL  Titel van de bron, als context voor de selectie
    -p, --profiel NAAM Rubriek uit prompts/<NAAM>.md (standaard: quotes)
    -r, --rubriek FILE Eigen rubriekbestand
    -b, --backend CLI  claude of opencode (standaard: auto)
    -m, --model MODEL  Model voor de CLI; gaat ongewijzigd mee
    -f, --force        Maak de samenvatting opnieuw
    -h, --help         Toon deze hulptekst

OMGEVINGSVARIABELEN:
    VID_QUOTE_MIN            Ondergrens quoteduur in seconden (standaard: ${MIN_S})
    VID_QUOTE_MAX            Bovengrens quoteduur in seconden (standaard: ${MAX_S})
    VID_QUOTE_MAX_AANTAL     Maximaal aantal quotes (standaard: ${MAX_AANTAL})
    VID_ANALYSE_BACKEND      claude, opencode of auto (standaard: auto)
    VID_MODEL                Model voor de CLI
    VID_ANALYSE_TIMEOUT      Timeout in seconden (standaard: 600)
    VID_PROFIEL              Rubriek uit prompts/<naam>.md
    VID_RUBRIEK              Pad naar een eigen rubriekbestand
    VID_AUTEUR               Naam van de spreker
    VID_TITEL                Titel van de bron

VOORBEELDEN:
    $(basename "$0") interview.mp4
    VID_QUOTE_MAX_AANTAL=10 $(basename "$0") --backend opencode interview/
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
SAMENVATTING="$WORKMAP/samenvatting.md"
DOC="$WORKMAP/quotes.md"

[ -f "$TSV" ] || die "Transcript ontbreekt: $TSV — draai eerst vid-transcribe.sh"

if [ -z "$RUBRIEK" ]; then
    RUBRIEK="$SCRIPT_DIR/prompts/${PROFIEL:-quotes}.md"
fi
[ -f "$RUBRIEK" ] || die "Rubriek ontbreekt: $RUBRIEK"
[ -f "$RENDERER" ] || die "Renderer ontbreekt: $RENDERER"

# --- Samenvatting als sturende context -----------------------------------

SU_ARGS=(--uit "$WORKMAP")
[ -n "$TITEL" ]  && SU_ARGS+=(--titel "$TITEL")
[ -n "$AUTEUR" ] && SU_ARGS+=(--auteur "$AUTEUR")
[ -n "${VID_ANALYSE_BACKEND:-}" ] && SU_ARGS+=(--backend "$VID_ANALYSE_BACKEND")
[ -n "${VID_MODEL:-}" ] && SU_ARGS+=(--model "$VID_MODEL")
[ "$VID_FORCE" = true ] && SU_ARGS+=(--force)

DOEL="${BRON:-$WORKMAP}"
if ! "$SCRIPT_DIR/vid-summarize.sh" "${SU_ARGS[@]}" -- "$DOEL"; then
    die "De samenvatting kon niet gemaakt worden; $DOC is niet aangepast."
fi
[ -f "$SAMENVATTING" ] || die "Samenvatting ontbreekt na vid-summarize.sh: $SAMENVATTING"

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
    [ -n "$AUTEUR" ] && echo "Spreker: $AUTEUR"
    [ -n "$BRON" ]  && echo "Bestand: $(basename -- "$BRON")"
    [ -n "$DUUR" ]  && echo "Duur: $(hhmmss "${DUUR%.*}")"
    echo
    echo "Maximaal ${MAX_AANTAL} quotes; per quote ${MIN_S} tot ${MAX_S} seconden."
    echo
    echo "# Samenvatting van deze opname"
    echo
    cat "$SAMENVATTING"
    echo
} > "$TMP_META"

log_info "Quotes kiezen: $TSV ($SEGMENTEN segmenten)"
log_info "  Backend: ${BACKEND}${VID_MODEL:+, model: $VID_MODEL}"
log_info "  Rubriek: $(basename "$RUBRIEK")"
log_info "  Maximaal ${MAX_AANTAL} quotes, ${MIN_S}-${MAX_S} s"

if ! cat "$TMP_META" "$RUBRIEK" "$TSV" | analyseer "$BACKEND" > "$TMP_OUT"; then
    die "De analyse is mislukt; $DOC is niet aangepast."
fi

if [ ! -s "$TMP_OUT" ]; then
    die "De analyse gaf lege uitvoer; $DOC is niet aangepast."
fi

if ! grep -qE '^##[[:space:]]*Quote' "$TMP_OUT"; then
    log_error "De analyse leverde geen herkenbare quotes op."
    log_error "Eerste regels van wat er wel kwam:"
    head -5 "$TMP_OUT" | sed 's/^/       /' >&2
    die "$DOC is niet aangepast."
fi

# --- Document opbouwen ---------------------------------------------------

{
    echo "# Quotes — ${NAAM}"
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
    echo "- Samenvatting: \`${SAMENVATTING}\`"
    echo "- Transcript: \`${TSV}\`"
    echo
    echo "## Hoe je dit leest"
    echo
    echo "Elke quote hieronder is een **losse uitspraak** uit de opname, gekozen"
    echo "omdat hij een punt uit de samenvatting draagt. De volgorde is sterkte,"
    echo "niet chronologie."
    echo
    echo "De tijdcode verwijst naar het moment in de bron; de tekst is letterlijk"
    echo "wat er gezegd wordt en bruikbaar als caption of ondertitel. Tijdcodes"
    echo "liggen op zinsgrenzen uit een automatische transcriptie: reken op"
    echo "ongeveer een halve seconde speling."
    echo
    echo "Quotes buiten de band van ${MIN_S} tot ${MAX_S} seconden zijn gemarkeerd"
    echo "met ⚠. Het maximum is ${MAX_AANTAL}."
} > "$TMP_DOC"

if ! awk -f "$RENDERER" \
        -v MIN_S="$MIN_S" -v MAX_S="$MAX_S" -v MAX_AANTAL="$MAX_AANTAL" \
        "$TSV" "$TMP_OUT" >> "$TMP_DOC" 2>/dev/null; then
    die "Geen bruikbare quotes uit de analyse; $DOC is niet aangepast."
fi

mv "$TMP_DOC" "$DOC"
AANTAL=$(grep -cE '^## Quote' "$DOC" || true)

log_success "Quotes klaar: $AANTAL voorstellen"
echo "  $DOC"
