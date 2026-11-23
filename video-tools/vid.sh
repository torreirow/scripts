#!/usr/bin/env bash

# Voert de hele pijplijn uit: transcriberen en analyseren.
# Slaat over wat er al ligt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

AUTEUR="${VID_AUTEUR:-}"
TITEL="${VID_TITEL:-}"
PROFIEL="${VID_PROFIEL:-}"
RUBRIEK="${VID_RUBRIEK:-}"
A_BACKEND=""
A_MODEL=""
FORCE_TRANSCRIBE=false
FORCE_ANALYSE=false

VID_UIT="${VID_UIT:-}"
VID_TAAL="${VID_TAAL:-auto}"
VID_VAN="${VID_VAN:-}"
VID_TOT="${VID_TOT:-}"
VID_FORCE="${VID_FORCE:-false}"

usage() {
    cat <<EOF
Gebruik: $(basename "$0") [OPTIES] <mediabestand>

Voert de hele keten uit voor één mediabestand:

    1. transcriberen  Whisper              (vid-transcribe.sh)
    2. analyseren     inspirations.md      (vid-inspire.sh)

Elke stap wordt overgeslagen als het resultaat er al staat.

OPTIES:
    -u, --uit MAP        Werkmap (standaard: <map van bron>/<naam zonder ext>)
        --taal TAAL      Taal van de audio (standaard: auto)
        --van TIJD       Begin pas hier (u:mm:ss, mm:ss of seconden)
        --tot TIJD       Stop hier
    -a, --auteur NAAM    Naam van de spreker, voor de titelsuggesties
    -t, --titel TITEL    Titel van de bron, als context voor de selectie
    -p, --profiel NAAM   Rubriek uit prompts/<NAAM>.md (standaard: algemeen)
    -r, --rubriek FILE   Eigen rubriekbestand
    -b, --backend CLI    claude of opencode (standaard: auto)
    -m, --model MODEL    Model voor de CLI; gaat ongewijzigd mee
                         (opencode gebruikt standaard een opencode-go-model)
        --force-transcribe  Transcribeer opnieuw
        --force-analyse     Analyseer opnieuw
        --force-all         Beide opnieuw
    -h, --help           Toon deze hulptekst

Bij een opname waar maar een deel van telt, geef je met --van en --tot het
tijdvak op. De tijdcodes in het transcript blijven gerekend vanaf het begin
van het bestand.

VOORBEELDEN:
    $(basename "$0") interview.mp4
    $(basename "$0") --backend opencode --model opencode-go/deepseek-v4.1-flash \\
        --auteur "Jan Jansen" --titel "Over verwachtingen" gesprek.mkv
EOF
}

while [[ $# -gt 0 ]]; do
    if vid_parse_common "$@"; then
        shift "$VID_CONSUMED"
        continue
    fi
    case "$1" in
        -a|--auteur)        AUTEUR="$2"; shift 2 ;;
        -t|--titel)         TITEL="$2"; shift 2 ;;
        -p|--profiel)       PROFIEL="$2"; shift 2 ;;
        -r|--rubriek)       RUBRIEK="$2"; shift 2 ;;
        -b|--backend)       A_BACKEND="$2"; shift 2 ;;
        -m|--model)         A_MODEL="$2"; shift 2 ;;
        --force-transcribe) FORCE_TRANSCRIBE=true; shift ;;
        --force-analyse)    FORCE_ANALYSE=true; shift ;;
        --force-all)        FORCE_TRANSCRIBE=true; FORCE_ANALYSE=true; shift ;;
        -h|--help)          usage; exit 0 ;;
        --)                 shift; break ;;
        -*)                 usage >&2; die "Onbekende optie: $1" ;;
        *)                  break ;;
    esac
done

[ $# -ge 1 ] || { usage >&2; die "Geef een mediabestand op."; }

BRON="${1%/}"
[ -f "$BRON" ] || die "Bestand bestaat niet: $BRON"

WORKMAP="${VID_UIT:-$(werkmap_voor "$BRON")}"
mkdir -p "$WORKMAP"
WORKMAP="$(cd "$WORKMAP" && pwd)"

# --- Stap 1: transcriberen ----------------------------------------------

echo >&2
log_info "── Stap 1/2: transcriberen ──"

TR_ARGS=(--uit "$WORKMAP")
[ -n "$VID_TAAL" ] && TR_ARGS+=(--taal "$VID_TAAL")
[ -n "$VID_VAN" ]  && TR_ARGS+=(--van "$VID_VAN")
[ -n "$VID_TOT" ]  && TR_ARGS+=(--tot "$VID_TOT")
{ [ "$FORCE_TRANSCRIBE" = true ] || [ "$VID_FORCE" = true ]; } && TR_ARGS+=(--force)

if ! "$SCRIPT_DIR/vid-transcribe.sh" "${TR_ARGS[@]}" -- "$BRON"; then
    die "Stap 1 (transcriberen) is mislukt — de keten stopt hier."
fi

# --- Stap 2: analyseren -------------------------------------------------

echo >&2
log_info "── Stap 2/2: analyseren ──"

DOC="$WORKMAP/inspirations.md"
if [ -f "$DOC" ] && [ "$FORCE_ANALYSE" = false ] && [ "$VID_FORCE" = false ] \
   && [ "$FORCE_TRANSCRIBE" = false ]; then
    log_skip "Inspiraties staan er al: $DOC"
    log_info "Gebruik --force-analyse om opnieuw te analyseren."
else
    AN_ARGS=(--uit "$WORKMAP")
    [ -n "$AUTEUR" ]    && AN_ARGS+=(--auteur "$AUTEUR")
    [ -n "$TITEL" ]     && AN_ARGS+=(--titel "$TITEL")
    [ -n "$PROFIEL" ]   && AN_ARGS+=(--profiel "$PROFIEL")
    [ -n "$RUBRIEK" ]   && AN_ARGS+=(--rubriek "$RUBRIEK")
    [ -n "$A_BACKEND" ] && AN_ARGS+=(--backend "$A_BACKEND")
    [ -n "$A_MODEL" ]   && AN_ARGS+=(--model "$A_MODEL")

    if ! "$SCRIPT_DIR/vid-inspire.sh" "${AN_ARGS[@]}" -- "$BRON"; then
        die "Stap 2 (analyseren) is mislukt."
    fi
fi

echo >&2
log_success "Klaar — inspiraties staan in:"
echo "  $DOC"
