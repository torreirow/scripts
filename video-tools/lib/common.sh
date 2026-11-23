#!/usr/bin/env bash

# Gedeelde helpers voor de inspirations-pijplijn.
# Bedoeld om te sourcen, niet om zelf uit te voeren.

# Kleuren alleen als we naar een terminal schrijven
if [ -t 2 ]; then
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[1;33m'
    C_BLUE='\033[0;34m'
    C_DIM='\033[2m'
    C_OFF='\033[0m'
else
    C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_DIM='' C_OFF=''
fi

log_info()    { echo -e "${C_BLUE}[INFO]${C_OFF} $*" >&2; }
log_success() { echo -e "${C_GREEN}[OK]${C_OFF} $*" >&2; }
log_warning() { echo -e "${C_YELLOW}[LET OP]${C_OFF} $*" >&2; }
log_error()   { echo -e "${C_RED}[FOUT]${C_OFF} $*" >&2; }
log_skip()    { echo -e "${C_DIM}[OVERGESLAGEN]${C_OFF} $*" >&2; }

die() {
    log_error "$*"
    exit 1
}

# require_tools <commando>...
# Meldt per ontbrekend commando wat er mist en stopt als er iets ontbreekt.
require_tools() {
    local tool
    local -a missing=()

    for tool in "$@"; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Ontbrekende tools: ${missing[*]}"
        for tool in "${missing[@]}"; do
            case "$tool" in
                ffmpeg)              log_error "  ffmpeg              — nodig om audio om te zetten en te knippen" ;;
                ffprobe)             log_error "  ffprobe             — onderdeel van ffmpeg" ;;
                whisper-cli)         log_error "  whisper-cli         — whisper.cpp, of gebruik VID_WHISPER_BACKEND=openai" ;;
                whisper)             log_error "  whisper             — pip install openai-whisper" ;;
                whisper-ctranslate2) log_error "  whisper-ctranslate2 — pip install whisper-ctranslate2" ;;
                claude)              log_error "  claude              — Claude Code CLI, of kies --backend opencode" ;;
                opencode)            log_error "  opencode            — OpenCode CLI, of kies --backend claude" ;;
                python3)             log_error "  python3             — nodig voor het omzetten van tijdcodes" ;;
                jq)                  log_error "  jq                  — JSON-verwerking" ;;
                timeout)             log_error "  timeout             — onderdeel van coreutils" ;;
                *)                   log_error "  $tool" ;;
            esac
        done
        exit 1
    fi
}

# repo_root — pad naar de repo, afgeleid van de locatie van dit bestand
repo_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# hhmmss <seconden> — 2534 -> 42:14, 4210 -> 1:10:10
hhmmss() {
    local total=${1%.*}
    if [ "$total" -ge 3600 ]; then
        printf '%d:%02d:%02d' $((total/3600)) $((total%3600/60)) $((total%60))
    else
        printf '%d:%02d' $((total/60)) $((total%60))
    fi
}

# naar_seconden u:mm:ss, mm:ss of seconden -> seconden
naar_seconden() {
    local t="$1"
    case "$t" in
        *:*:*) IFS=: read -r h m s <<<"$t"; echo $((10#$h * 3600 + 10#$m * 60 + 10#${s%.*})) ;;
        *:*)   IFS=: read -r m s   <<<"$t"; echo $((10#$m * 60 + 10#${s%.*})) ;;
        *)     echo "${t%.*}" ;;
    esac
}

# werkmap_voor <bestand> — pad zonder extensie naast de bron
#   ~/Videos/interview.mp4 -> ~/Videos/interview
werkmap_voor() {
    local bron="$1" map base
    map="$(dirname -- "$bron")"
    base="$(basename -- "$bron")"
    if [ "${base#.}" != "$base" ] && [ "${base#*.}" = "$base" ]; then
        : # verborgen bestand zonder verdere punt: naam ongewijzigd laten
    else
        base="${base%.*}"
    fi
    [ -n "$base" ] || base="$(basename -- "$bron")"
    printf '%s/%s' "${map%/}" "$base"
}

# neutrale_map — tijdelijke lege map, zodat een CLI geen projectcontext vindt
neutrale_map() {
    mktemp -d "${TMPDIR:-/tmp}/vid-analyse.XXXXXXXX"
}

# shellcheck disable=SC2034  # de VID_*-globals worden door de aanroeper gebruikt
# vid_parse_common <optie> [waarde]
# Verwerkt de opties die de scripts delen. Geeft 0 terug als de optie bekend
# is en zet dan VID_CONSUMED op het aantal gebruikte argumenten; 1 als hij
# onbekend is.
vid_parse_common() {
    VID_CONSUMED=0
    case "$1" in
        -u|--uit)   VID_UIT="${2:-}"; VID_CONSUMED=2; return 0 ;;
        --taal)     VID_TAAL="${2:-}"; VID_CONSUMED=2; return 0 ;;
        --van)      VID_VAN="${2:-}"; VID_CONSUMED=2; return 0 ;;
        --tot)      VID_TOT="${2:-}"; VID_CONSUMED=2; return 0 ;;
        -f|--force) VID_FORCE=true; VID_CONSUMED=1; return 0 ;;
        *)          return 1 ;;
    esac
}

# vid_analyse_backend — claude, opencode, of een lege string als geen van
# beide beschikbaar is. Respecteert VID_ANALYSE_BACKEND.
vid_analyse_backend() {
    case "${VID_ANALYSE_BACKEND:-auto}" in
        claude|opencode) printf '%s' "$VID_ANALYSE_BACKEND" ;;
        auto)
            if command -v claude >/dev/null 2>&1; then
                printf 'claude'
            elif command -v opencode >/dev/null 2>&1; then
                printf 'opencode'
            fi
            ;;
        *) die "Onbekende analyse-backend: ${VID_ANALYSE_BACKEND} (kies claude of opencode)" ;;
    esac
}

# vid_standaard_model <backend> — model als de gebruiker er geen opgeeft.
# Voor opencode moet dat een opencode-go-model zijn: het algemene
# provider-model valt buiten het abonnement en faalt met een saldomelding.
vid_standaard_model() {
    case "$1" in
        opencode) printf '%s' "${VID_OPENCODE_MODEL:-opencode-go/deepseek-v4.1-flash}" ;;
        *)        printf '' ;;
    esac
}

# analyseer <backend> — leest de prompt van stdin, schrijft de respons naar
# stdout. De CLI draait vanuit een lege map, zodat projectbestanden en
# projectinstructies de analyse niet beïnvloeden.
analyseer() {
    local backend="$1" rc=0 timeout_s="${VID_ANALYSE_TIMEOUT:-600}"
    local model="${VID_MODEL:-}"
    local map
    local -a args=()

    [ -n "$model" ] || model="$(vid_standaard_model "$backend")"

    case "$backend" in
        claude)
            args=(-p --output-format text)
            [ -n "$model" ] && args+=(--model "$model")
            map="$(neutrale_map)"
            if ( cd "$map" && timeout "$timeout_s" claude "${args[@]}" ); then
                rc=0
            else
                rc=$?
            fi
            rm -rf -- "$map"
            ;;
        opencode)
            map="$(neutrale_map)"
            args=(run --auto)
            [ -n "$model" ] && args+=(-m "$model")
            if ( cd "$map" && timeout "$timeout_s" opencode "${args[@]}" ); then
                rc=0
            else
                rc=$?
            fi
            rm -rf -- "$map"
            ;;
        *)
            log_error "Onbekende analyse-backend: $backend"
            return 2
            ;;
    esac

    if [ "$rc" -eq 124 ]; then
        log_error "De analyse-backend ($backend) stopte niet binnen ${timeout_s} s."
        log_error "Verhoog VID_ANALYSE_TIMEOUT of controleer of de CLI nog werkt."
    elif [ "$rc" -ne 0 ]; then
        log_error "De analyse-backend ($backend) gaf exitcode $rc."
    fi
    return "$rc"
}
