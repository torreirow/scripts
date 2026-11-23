#!/usr/bin/env bash

# Voert de hele pijplijn uit: transcriberen, samenvatten, inspireren, quoten.
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
FORCE_SAMENVATTING=false
FORCE_ANALYSE=false
FORCE_QUOTES=false

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
    2. samenvatten    samenvatting.md      (vid-summarize.sh)
    3. inspireren     inspirations.md      (vid-inspire.sh)
    4. quoten         quotes.md            (vid-quotes.sh)

Elke stap wordt overgeslagen als het resultaat er al staat.

OPTIES:
    -u, --uit MAP        Werkmap (standaard: <map van bron>/<naam zonder ext>)
        --taal TAAL      Taal van de audio (standaard: auto)
        --van TIJD       Begin pas hier (u:mm:ss, mm:ss of seconden)
        --tot TIJD       Stop hier
    -a, --auteur NAAM    Naam van de spreker, voor de titels
    -t, --titel TITEL    Titel van de bron, als context voor de selectie
    -p, --profiel NAAM   Rubriek voor de inspirations uit prompts/<NAAM>.md
    -r, --rubriek FILE   Eigen rubriekbestand (voor de inspirations)
    -b, --backend CLI    claude of opencode (standaard: auto)
    -m, --model MODEL    Model voor de CLI; gaat ongewijzigd mee
                         (opencode gebruikt standaard een opencode-go-model)
        --force-transcribe   Transcribeer opnieuw
        --force-samenvatting Maak de samenvatting opnieuw
        --force-analyse      Analyseer de inspirations opnieuw
        --force-quotes       Kies de quotes opnieuw
        --force-all          Alle vier opnieuw
    -h, --help           Toon deze hulptekst

Bij een opname waar maar een deel van telt, geef je met --van en --tot het
tijdvak op. De tijdcodes blijven gerekend vanaf het begin van het bestand.

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
        -a|--auteur)         AUTEUR="$2"; shift 2 ;;
        -t|--titel)          TITEL="$2"; shift 2 ;;
        -p|--profiel)        PROFIEL="$2"; shift 2 ;;
        -r|--rubriek)        RUBRIEK="$2"; shift 2 ;;
        -b|--backend)        A_BACKEND="$2"; shift 2 ;;
        -m|--model)          A_MODEL="$2"; shift 2 ;;
        --force-transcribe)  FORCE_TRANSCRIBE=true; shift ;;
        --force-samenvatting) FORCE_SAMENVATTING=true; shift ;;
        --force-analyse)     FORCE_ANALYSE=true; shift ;;
        --force-quotes)      FORCE_QUOTES=true; shift ;;
        --force-all)         FORCE_TRANSCRIBE=true; FORCE_SAMENVATTING=true
                             FORCE_ANALYSE=true; FORCE_QUOTES=true; shift ;;
        -h|--help)           usage; exit 0 ;;
        --)                  shift; break ;;
        -*)                  usage >&2; die "Onbekende optie: $1" ;;
        *)                   break ;;
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
log_info "── Stap 1/4: transcriberen ──"

TR_ARGS=(--uit "$WORKMAP")
[ -n "$VID_TAAL" ] && TR_ARGS+=(--taal "$VID_TAAL")
[ -n "$VID_VAN" ]  && TR_ARGS+=(--van "$VID_VAN")
[ -n "$VID_TOT" ]  && TR_ARGS+=(--tot "$VID_TOT")
{ [ "$FORCE_TRANSCRIBE" = true ] || [ "$VID_FORCE" = true ]; } && TR_ARGS+=(--force)

if ! "$SCRIPT_DIR/vid-transcribe.sh" "${TR_ARGS[@]}" -- "$BRON"; then
    die "Stap 1 (transcriberen) is mislukt — de keten stopt hier."
fi

# Gedeelde argumenten voor de analysestappen
ANA_ARGS=()
[ -n "$TITEL" ]     && ANA_ARGS+=(--titel "$TITEL")
[ -n "$AUTEUR" ]    && ANA_ARGS+=(--auteur "$AUTEUR")
[ -n "$A_BACKEND" ] && ANA_ARGS+=(--backend "$A_BACKEND")
[ -n "$A_MODEL" ]   && ANA_ARGS+=(--model "$A_MODEL")

# --- Stap 2: samenvatten -------------------------------------------------

echo >&2
log_info "── Stap 2/4: samenvatten ──"

SU_ARGS=(--uit "$WORKMAP" "${ANA_ARGS[@]}")
{ [ "$FORCE_SAMENVATTING" = true ] || [ "$VID_FORCE" = true ]; } && SU_ARGS+=(--force)

if ! "$SCRIPT_DIR/vid-summarize.sh" "${SU_ARGS[@]}" -- "$BRON"; then
    die "Stap 2 (samenvatten) is mislukt — de keten stopt hier."
fi

# --- Stap 3: inspireren -------------------------------------------------

echo >&2
log_info "── Stap 3/4: inspireren ──"

DOC_INSP="$WORKMAP/inspirations.md"
if [ -f "$DOC_INSP" ] && [ "$FORCE_ANALYSE" = false ] && [ "$VID_FORCE" = false ] \
   && [ "$FORCE_TRANSCRIBE" = false ]; then
    log_skip "Inspiraties staan er al: $DOC_INSP"
    log_info "Gebruik --force-analyse om opnieuw te analyseren."
else
    IN_ARGS=(--uit "$WORKMAP" "${ANA_ARGS[@]}")
    [ -n "$PROFIEL" ] && IN_ARGS+=(--profiel "$PROFIEL")
    [ -n "$RUBRIEK" ] && IN_ARGS+=(--rubriek "$RUBRIEK")

    if ! "$SCRIPT_DIR/vid-inspire.sh" "${IN_ARGS[@]}" -- "$BRON"; then
        die "Stap 3 (inspireren) is mislukt."
    fi
fi

# --- Stap 4: quoten ------------------------------------------------------

echo >&2
log_info "── Stap 4/4: quoten ──"

DOC_QUOTES="$WORKMAP/quotes.md"
if [ -f "$DOC_QUOTES" ] && [ "$FORCE_QUOTES" = false ] && [ "$VID_FORCE" = false ] \
   && [ "$FORCE_TRANSCRIBE" = false ] && [ "$FORCE_SAMENVATTING" = false ]; then
    log_skip "Quotes staan er al: $DOC_QUOTES"
    log_info "Gebruik --force-quotes om opnieuw te kiezen."
else
    QU_ARGS=(--uit "$WORKMAP" "${ANA_ARGS[@]}")
    # De samenvatting is hierboven al gemaakt of overgeslagen; vid-quotes hoeft
    # hem niet nog eens te forceren.
    if ! "$SCRIPT_DIR/vid-quotes.sh" "${QU_ARGS[@]}" -- "$BRON"; then
        die "Stap 4 (quoten) is mislukt."
    fi
fi

echo >&2
log_success "Klaar — de documenten staan in $WORKMAP"
for f in samenvatting.md inspirations.md quotes.md; do
    [ -f "$WORKMAP/$f" ] && echo "  $WORKMAP/$f"
done
