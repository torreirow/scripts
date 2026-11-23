#!/usr/bin/env bash

# Analyseert het transcript van een mediabestand en levert inspirations.md op:
# de knipopdracht voor de videoeditor.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

RENDERER="$SCRIPT_DIR/lib/render-inspirations.awk"
MIN_S="${VID_SHORT_MIN:-30}"
MAX_S="${VID_SHORT_MAX:-90}"
AUTEUR="${VID_AUTEUR:-}"
TITEL="${VID_TITEL:-}"
PROFIEL="${VID_PROFIEL:-}"
RUBRIEK="${VID_RUBRIEK:-}"

VID_UIT="${VID_UIT:-}"
VID_FORCE="${VID_FORCE:-false}"

usage() {
    cat <<EOF
Gebruik: $(basename "$0") [OPTIES] <mediabestand|werkmap>

Analyseert <werkmap>/transcript.tsv en schrijft <werkmap>/inspirations.md:
shortvoorstellen met tijdcodes voor de videoeditor.

Draait altijd opnieuw; inspirations.md wordt overschreven, tenzij de analyse
niets bruikbaars oplevert.

OPTIES:
    -u, --uit MAP      Werkmap (standaard: <map van bron>/<naam zonder ext>)
    -a, --auteur NAAM  Naam van de spreker, voor de titelsuggesties
    -t, --titel TITEL  Titel van de bron, als context voor de selectie
    -p, --profiel NAAM Rubriek uit prompts/<NAAM>.md (standaard: algemeen)
    -r, --rubriek FILE Eigen rubriekbestand
    -b, --backend CLI  claude of opencode (standaard: auto)
    -m, --model MODEL  Model voor de CLI; gaat ongewijzigd mee
                       (opencode gebruikt standaard een opencode-go-model)
    -h, --help         Toon deze hulptekst

De backend draait vanuit een lege map, zodat projectbestanden en
projectinstructies de analyse niet beïnvloeden.

OMGEVINGSVARIABELEN:
    VID_SHORT_MIN            Ondergrens shortduur (standaard: ${MIN_S})
    VID_SHORT_MAX            Bovengrens shortduur (standaard: ${MAX_S})
    VID_ANALYSE_BACKEND      claude, opencode of auto (standaard: auto)
    VID_MODEL                Model voor de CLI
    VID_OPENCODE_MODEL       Standaardmodel bij backend opencode
                             (standaard: opencode-go/deepseek-v4.1-flash)
    VID_ANALYSE_TIMEOUT      Timeout in seconden (standaard: 600)
    VID_PROFIEL              Rubriek uit prompts/<naam>.md
    VID_RUBRIEK              Pad naar een eigen rubriekbestand
    VID_AUTEUR               Naam van de spreker
    VID_TITEL                Titel van de bron

VOORBEELDEN:
    $(basename "$0") interview.mp4
    $(basename "$0") --backend opencode --model opencode-go/deepseek-v4.1-flash interview.mp4
    $(basename "$0") --auteur "Bertwin Wijnholds" --titel "Zie onze God" preken/2026-09-13
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
    [ -n "$BRON" ] || BRON="$(find "$WORKMAP" -maxdepth 1 -type f \
        \( -name '*.mp4' -o -name '*.mkv' -o -name '*.webm' -o -name '*.m4a' -o -name '*.wav' -o -name '*.mp3' \) \
        2>/dev/null | sort | head -1)"
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
DOC="$WORKMAP/inspirations.md"

[ -f "$TSV" ] || die "Transcript ontbreekt: $TSV — draai eerst vid-transcribe.sh"

if [ -z "$RUBRIEK" ]; then
    RUBRIEK="$SCRIPT_DIR/prompts/${PROFIEL:-algemeen}.md"
fi
[ -f "$RUBRIEK" ] || die "Rubriek ontbreekt: $RUBRIEK"
[ -f "$RENDERER" ] || die "Renderer ontbreekt: $RENDERER"

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

# --- Metadata verzamelen -------------------------------------------------

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
    [ -n "$TITEL" ]  && echo "Titel: $TITEL"
    [ -n "$BRON" ]   && echo "Bestand: $(basename -- "$BRON")"
    [ -n "$DUUR" ]   && echo "Duur: $(hhmmss "${DUUR%.*}")"
    echo
    if [ -n "$AUTEUR" ]; then
        echo "Spreker: $AUTEUR"
        echo
        echo "Gebruik deze naam in de titelsuggesties."
    else
        echo "De spreker is niet bekend. Laat de naam weg uit de"
        echo "titelsuggesties en verzin er geen."
    fi
    echo
} > "$TMP_META"

# --- Analyse door de gekozen CLI ----------------------------------------

log_info "Analyseren: $TSV ($SEGMENTEN segmenten)"
log_info "  Backend: ${BACKEND}${VID_MODEL:+, model: $VID_MODEL}"
log_info "  Rubriek: $(basename "$RUBRIEK")"
log_info "  Duurband: ${MIN_S}-${MAX_S} s"

# Metadata, rubriek en transcript worden geconcateneerd en gepipet: er gaat
# niets door shell-expansie heen, dus er kan niets mangelen.
if ! cat "$TMP_META" "$RUBRIEK" "$TSV" | analyseer "$BACKEND" > "$TMP_OUT"; then
    die "De analyse is mislukt; $DOC is niet aangepast."
fi

if [ ! -s "$TMP_OUT" ]; then
    die "De analyse gaf lege uitvoer; $DOC is niet aangepast."
fi

if ! grep -qE '^##[[:space:]]*Short' "$TMP_OUT"; then
    log_error "De analyse leverde geen herkenbare shortblokken op."
    log_error "Eerste regels van wat er wel kwam:"
    head -5 "$TMP_OUT" | sed 's/^/       /' >&2
    die "$DOC is niet aangepast."
fi

# --- Document opbouwen ---------------------------------------------------

{
    echo "# Inspiraties — ${NAAM}"
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
    echo "## Hoe je dit leest"
    echo
    echo "Elke short hieronder is **samengesteld uit losse fragmenten** die"
    echo "verspreid door de bron liggen. De tabel staat in de volgorde waarin"
    echo "je ze monteert, niet in de volgorde waarin ze zijn uitgesproken; staat"
    echo "er een waarschuwing boven de tabel, dan wijken die twee van elkaar af."
    echo
    echo "Elk fragment heeft een functie in het geheel:"
    echo
    echo "| Functie | Wat het doet |"
    echo "|---------------|-----------------------------------------------|"
    echo "| Hook | opent en trekt de kijker binnen |"
    echo "| Kernboodschap | de stelling waar alles om draait |"
    echo "| Verdieping | geeft de grond onder die stelling |"
    echo "| Punchline | de zin die blijft hangen |"
    echo
    echo "Tijdcodes hebben de vorm \`uu:mm:ss.mmm\` vanaf het begin van de"
    echo "opname. Ze liggen op zinsgrenzen uit een automatische transcriptie,"
    echo "niet op woordgrenzen: **trim de in- en uitpunten op gehoor bij, reken"
    echo "op ongeveer een halve seconde speling.** De tekst in de tabel is"
    echo "letterlijk wat er gezegd wordt en bruikbaar als ondertitelscript."
    echo
    echo "De voorstellen staan op volgorde van sterkte. Shorts buiten de band van"
    echo "${MIN_S} tot ${MAX_S} seconden zijn gemarkeerd met ⚠."
} > "$TMP_DOC"

if ! awk -f "$RENDERER" \
        -v VIDEO_ID="" -v MIN_S="$MIN_S" -v MAX_S="$MAX_S" \
        "$TSV" "$TMP_OUT" >> "$TMP_DOC" 2>/dev/null; then
    die "Geen bruikbare shorts uit de analyse; $DOC is niet aangepast."
fi

mv "$TMP_DOC" "$DOC"
AANTAL=$(grep -cE '^## Short' "$DOC" || true)

log_success "Inspiraties klaar: $AANTAL shortvoorstellen"
echo "  $DOC"
