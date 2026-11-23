#!/usr/bin/env bash

# Transcribeert een mediabestand naar een transcript in een werkmap.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

BACKEND="${VID_WHISPER_BACKEND:-cpp}"
MODEL="${VID_WHISPER_MODEL:-large-v3}"
COMPUTE_TYPE="${VID_COMPUTE_TYPE:-float32}"
THREADS="${VID_WHISPER_THREADS:-$(nproc)}"
SILENCE="${VID_SILENCE_THRESHOLD:-2}"
CPP_MODEL_DIR="${VID_CPP_MODEL_DIR:-$HOME/.cache/whisper-cpp}"
CARRY_PROMPT="${VID_CARRY_PROMPT:-false}"
VOCAB="${VID_VOCAB:-}"
SHIFTER="$SCRIPT_DIR/lib/shift-timestamps.py"

# Seconden audio maal deze factor. Gemeten op een Ryzen 7 PRO 7840U,
# 16 threads, large-v3: openai-whisper 11,4x; ctranslate2 float32 2,8-3,6x;
# whisper.cpp op de Radeon 780M (Vulkan) 0,24x.
case "$BACKEND" in
    cpp)         SPEED_FACTOR="${VID_SPEED_FACTOR:-0.3}" ;;
    openai)      SPEED_FACTOR="${VID_SPEED_FACTOR:-12}" ;;
    ctranslate2) SPEED_FACTOR="${VID_SPEED_FACTOR:-4}" ;;
    *)           SPEED_FACTOR="${VID_SPEED_FACTOR:-12}" ;;
esac

VID_UIT="${VID_UIT:-}"
VID_TAAL="${VID_TAAL:-auto}"
VID_VAN="${VID_VAN:-}"
VID_TOT="${VID_TOT:-}"
VID_FORCE="${VID_FORCE:-false}"

usage() {
    cat <<EOF
Gebruik: $(basename "$0") [OPTIES] <mediabestand>

Transcribeert een mediabestand naar transcript.tsv, .txt, .json, .srt en
.vtt in de werkmap. Standaard is dat een map naast de bron, genoemd naar
het bestand zonder extensie.

OPTIES:
    -u, --uit MAP     Werkmap (standaard: <map van bron>/<naam zonder ext>)
    -t, --taal TAAL   Taal van de audio (standaard: auto, laten detecteren)
        --van TIJD    Begin pas op dit moment (u:mm:ss, mm:ss of seconden)
        --tot TIJD    Stop op dit moment
    -f, --force       Transcribeer opnieuw, ook als het transcript er al staat
    -h, --help        Toon deze hulptekst

BACKENDS (via VID_WHISPER_BACKEND):
    cpp           standaard; whisper.cpp, op de GPU via Vulkan
    ctranslate2   dezelfde modellen op de CPU
    openai        de referentie-implementatie van OpenAI

OMGEVINGSVARIABELEN:
    VID_WHISPER_BACKEND      cpp, ctranslate2 of openai (standaard: ${BACKEND})
    VID_WHISPER_MODEL        Whisper-model (standaard: ${MODEL})
    VID_TAAL                 Taal (standaard: ${VID_TAAL})
    VID_COMPUTE_TYPE         float32, int8_float32 of int8 (standaard: ${COMPUTE_TYPE})
    VID_WHISPER_THREADS      Aantal CPU-threads (standaard: alle cores)
    VID_SILENCE_THRESHOLD    Stiltedrempel in seconden (standaard: ${SILENCE})
    VID_VOCAB                Pad naar een vocabulairebestand (optioneel)
    VID_CARRY_PROMPT         true: vocabulaire bij elk venster van 30 s (cpp)
    VID_CPP_MODEL_DIR        Map met ggml-modellen (standaard: ${CPP_MODEL_DIR})
    VID_SPEED_FACTOR         Factor voor de tijdsindicatie

VOORBEELDEN:
    $(basename "$0") interview.mp4
    $(basename "$0") --taal nl --uit /tmp/analyse gesprek.mkv
    $(basename "$0") --van 0:47:02 --tot 1:25:55 dienst.mp4
EOF
}

while [[ $# -gt 0 ]]; do
    if vid_parse_common "$@"; then
        shift "$VID_CONSUMED"
        continue
    fi
    case "$1" in
        -t|--taal) VID_TAAL="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        --)        shift; break ;;
        -*)        usage >&2; die "Onbekende optie: $1" ;;
        *)         break ;;
    esac
done

[ $# -ge 1 ] || { usage >&2; die "Geef een mediabestand op."; }

case "$BACKEND" in
    cpp)         require_tools ffprobe ffmpeg python3 timeout ;;
    openai)      require_tools whisper ffprobe timeout ;;
    ctranslate2) require_tools ffprobe ffmpeg python3 timeout ;;
    *)           die "Onbekende backend: $BACKEND (kies cpp, ctranslate2 of openai)" ;;
esac

BRON="${1%/}"
[ -f "$BRON" ] || die "Bestand bestaat niet: $BRON"

WORKMAP="${VID_UIT:-$(werkmap_voor "$BRON")}"
mkdir -p "$WORKMAP"
WORKMAP="$(cd "$WORKMAP" && pwd)"
TSV="$WORKMAP/transcript.tsv"

if [ -f "$TSV" ] && [ "$VID_FORCE" = false ]; then
    log_skip "Transcript staat er al: $TSV"
    exit 0
fi

DUUR="$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$BRON" 2>/dev/null || echo 0)"
DUUR_INT="${DUUR%.*}"

VAN_S=0
TOT_S=0
if [ -n "$VID_VAN" ] || [ -n "$VID_TOT" ]; then
    VAN_S=$(naar_seconden "${VID_VAN:-0}")
    if [ -n "$VID_TOT" ]; then
        TOT_S=$(naar_seconden "$VID_TOT")
        [ "$TOT_S" -gt "$VAN_S" ] || die "--tot ($VID_TOT) ligt niet na --van ($VID_VAN)"
        DUUR_INT=$(( TOT_S - VAN_S ))
    else
        TOT_S=$DUUR_INT
        DUUR_INT=$(( DUUR_INT - VAN_S ))
    fi
fi

log_info "Transcriberen: $BRON"
log_info "  Backend: ${BACKEND}, model: ${MODEL}, taal: ${VID_TAAL}, threads: ${THREADS}"
[ "$BACKEND" = ctranslate2 ] && log_info "  compute_type: ${COMPUTE_TYPE}"
[ "$VAN_S" -gt 0 ] || [ "$TOT_S" -gt 0 ] && \
    log_info "  Alleen ${VID_VAN:-begin} tot ${VID_TOT:-eind}"
log_info "  Te verwerken: $(hhmmss "$DUUR_INT")"
log_info "  Ruwe schatting: $(hhmmss "$(awk -v d="$DUUR_INT" -v f="$SPEED_FACTOR" 'BEGIN{printf "%d", d*f}')")"

PROMPT=""
if [ -n "$VOCAB" ] && [ -f "$VOCAB" ]; then
    PROMPT="$(grep -v '^[[:space:]]*#' "$VOCAB" \
        | grep -v '^[[:space:]]*$' \
        | tr '\n' ' ' \
        | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
    if [ -n "$PROMPT" ]; then
        WOORDEN=$(printf '%s' "$PROMPT" | wc -w)
        if [ "$WOORDEN" -gt 150 ]; then
            log_warning "Vocabulaire is $WOORDEN woorden; Whisper kapt af rond 150."
        fi
        log_info "  Vocabulaire: $WOORDEN woorden"
    fi
fi

START=$(date +%s)
OFFSET_MS=0

if [ "$BACKEND" = cpp ]; then
    # whisper.cpp leest alleen wav. Het tijdvak gaat via --offset-t en
    # --duration; de tijdcodes blijven dan gerekend vanaf het begin van het
    # bestand, dus terugschuiven is niet nodig.
    if command -v whisper-cli >/dev/null 2>&1; then
        WCPP=()
    elif command -v nix >/dev/null 2>&1; then
        log_info "  whisper.cpp (Vulkan) via nix"
        WCPP=(nix shell nixpkgs#whisper-cpp-vulkan -c)
    else
        die "whisper-cli ontbreekt en nix is niet beschikbaar; gebruik VID_WHISPER_BACKEND=openai of ctranslate2."
    fi

    MODEL_FILE="$CPP_MODEL_DIR/ggml-${MODEL}.bin"
    if [ ! -f "$MODEL_FILE" ]; then
        log_info "  Model ggml-${MODEL} downloaden naar ${CPP_MODEL_DIR}"
        mkdir -p "$CPP_MODEL_DIR"
        "${WCPP[@]}" whisper-cpp-download-ggml-model "$MODEL" "$CPP_MODEL_DIR" >&2 \
            || die "Download van ggml-${MODEL} mislukt"
    fi

    BRON_STAM=".whisper"
    TMPWAV="$WORKMAP/$BRON_STAM.wav"
    trap 'rm -f "$TMPWAV" "$WORKMAP/$BRON_STAM.csv"' EXIT
    ffmpeg -nostdin -v error -y -i "$BRON" -ac 1 -ar 16000 -c:a pcm_s16le "$TMPWAV" \
        || die "Omzetten naar wav met ffmpeg mislukt"

    ARGS=(
        -m "$MODEL_FILE" -f "$TMPWAV" -l "$VID_TAAL" -t "$THREADS"
        --max-context 0
        -otxt -osrt -ovtt -ocsv -oj -of "$WORKMAP/$BRON_STAM"
    )
    [ "$TOT_S" -gt 0 ] && ARGS+=(--offset-t $(( VAN_S * 1000 )) --duration $(( (TOT_S - VAN_S) * 1000 )))
    if [ -n "$PROMPT" ]; then
        ARGS+=(--prompt "$PROMPT")
        [ "$CARRY_PROMPT" = true ] && ARGS+=(--carry-initial-prompt)
    fi

    if ! "${WCPP[@]}" whisper-cli "${ARGS[@]}" > "$WORKMAP/.whisper.log" 2>&1; then
        tail -20 "$WORKMAP/.whisper.log" >&2
        die "Transcriptie mislukt voor $BRON (log: $WORKMAP/.whisper.log)"
    fi
    rm -f "$TMPWAV"
    grep -q 'whisper_backend_init_gpu: found GPU' "$WORKMAP/.whisper.log" \
        || log_warning "whisper.cpp vond geen GPU en draaide op de CPU"

    # Dezelfde tsv als openai-whisper: start en eind in ms, dan de tekst
    python3 - "$WORKMAP/$BRON_STAM.csv" "$WORKMAP/$BRON_STAM.tsv" <<'PY' \
        || die "Omzetten van csv naar tsv mislukt"
import csv, sys
with open(sys.argv[1], newline="", encoding="utf-8") as f, \
     open(sys.argv[2], "w", encoding="utf-8") as uit:
    uit.write("start\tend\ttext\n")
    for rij in csv.DictReader(f):
        tekst = " ".join(rij["text"].split())
        if tekst:
            uit.write(f"{rij['start']}\t{rij['end']}\t{tekst}\n")
PY
    rm -f "$WORKMAP/$BRON_STAM.csv" "$WORKMAP/.whisper.log"
elif [ "$BACKEND" = openai ]; then
    # openai-whisper kan zelf een tijdvak overslaan en houdt daarbij de
    # tijdlijn van het hele bestand aan.
    ARGS=(
        "$BRON" --model "$MODEL" --task transcribe
        --threads "$THREADS" --fp16 False --word_timestamps True
        --hallucination_silence_threshold "$SILENCE"
        --condition_on_previous_text False
        --output_format all --output_dir "$WORKMAP" --verbose False
    )
    [ "$VID_TAAL" != auto ] && ARGS+=(--language "$VID_TAAL")
    [ -n "$PROMPT" ] && ARGS+=(--initial_prompt "$PROMPT")
    if [ "$TOT_S" -gt 0 ]; then
        ARGS+=(--clip_timestamps "${VAN_S},${TOT_S}")
        log_warning "Negeer de ETA in de voortgangsbalk: die rekent af tegen"
        log_warning "het hele bestand en staat daardoor veel te hoog."
    fi
    whisper "${ARGS[@]}" || die "Transcriptie mislukt voor $BRON"
    BRON_STAM="$(basename "${BRON%.*}")"
else
    # whisper-ctranslate2 kent geen tijdvak, dus knippen we vooraf en
    # schuiven we de tijdcodes achteraf terug op hun plek.
    if command -v whisper-ctranslate2 >/dev/null 2>&1; then
        WCT=(whisper-ctranslate2)
    elif command -v nix >/dev/null 2>&1; then
        log_info "  whisper-ctranslate2 via nix"
        WCT=(nix run nixpkgs#whisper-ctranslate2 --)
    else
        die "whisper-ctranslate2 ontbreekt en nix is niet beschikbaar."
    fi

    INVOER="$BRON"
    TMPWAV=""
    if [ "$TOT_S" -gt 0 ]; then
        TMPWAV="$WORKMAP/.knip.wav"
        log_info "  Audio knippen naar 16 kHz mono voor de transcriptie"
        ffmpeg -nostdin -v error -y -i "$BRON" \
            -ss "$VAN_S" -to "$TOT_S" -ac 1 -ar 16000 "$TMPWAV" \
            || die "Knippen met ffmpeg mislukt"
        INVOER="$TMPWAV"
        OFFSET_MS=$(( VAN_S * 1000 ))
    fi

    ARGS=(
        "$INVOER" --model "$MODEL" --task transcribe
        --threads "$THREADS" --compute_type "$COMPUTE_TYPE"
        --word_timestamps True
        --hallucination_silence_threshold "$SILENCE"
        --condition_on_previous_text False
        --output_format all --output_dir "$WORKMAP" --verbose False
    )
    [ "$VID_TAAL" != auto ] && ARGS+=(--language "$VID_TAAL")
    [ -n "$PROMPT" ] && ARGS+=(--initial_prompt "$PROMPT")

    if ! "${WCT[@]}" "${ARGS[@]}"; then
        [ -n "$TMPWAV" ] && rm -f "$TMPWAV"
        die "Transcriptie mislukt voor $BRON"
    fi
    BRON_STAM="$(basename "${INVOER%.*}")"
    [ -n "$TMPWAV" ] && rm -f "$TMPWAV"
fi

# Uitvoer heet naar het invoerbestand; hernoem naar transcript.*
for ext in txt tsv srt vtt json; do
    [ -f "$WORKMAP/$BRON_STAM.$ext" ] && mv -f "$WORKMAP/$BRON_STAM.$ext" "$WORKMAP/transcript.$ext"
done

[ -f "$TSV" ] || die "Transcriptie gaf geen $TSV"

if [ "$OFFSET_MS" -gt 0 ]; then
    python3 "$SHIFTER" "$WORKMAP" "$OFFSET_MS" >&2 \
        || die "Kon de tijdcodes niet terugschuiven; het transcript klopt niet."
fi

DUUR_RUN=$(( $(date +%s) - START ))
SEGMENTEN=$(( $(wc -l < "$TSV") - 1 ))
EERSTE=$(awk -F'\t' 'NR==2{print $1}' "$TSV")

log_success "Transcript klaar in $(hhmmss "$DUUR_RUN") — $SEGMENTEN segmenten"
log_info "  Eerste segment op $(hhmmss $(( ${EERSTE:-0} / 1000 )))"
for ext in tsv txt json srt vtt; do
    [ -f "$WORKMAP/transcript.$ext" ] && echo "  $WORKMAP/transcript.$ext"
done
