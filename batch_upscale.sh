#!/bin/bash
set -e

# Directories
INPUT_DIR="${INPUT_DIR:-/input}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
WEIGHTS_DIR="/opt/Real-ESRGAN/weights"

# Model and parameters
MODEL="${MODEL:-realesr-animevideov3}"
SCALE="${SCALE:-4}"
TILE="${TILE:-0}"
DENOISE="${DENOISE:-1.0}"
NUM_PROC="${NUM_PROC:-1}"
SUFFIX="upscaled"
EXT="mp4"

# Ensure weights directory exists
mkdir -p "$WEIGHTS_DIR"

# Download weights if missing
if [ ! -f "$WEIGHTS_DIR/$MODEL.pth" ]; then
  echo "[INFO] Downloading $MODEL.pth..."
  wget -q "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/$MODEl.pth" \
    -O "$WEIGHTS_DIR/$MODEL.pth"
fi

# NVIDIA GPU check
echo "[INFO] Checking for NVIDIA GPU..."
if ! command -v nvidia-smi &>/dev/null; then
  echo "[ERROR] NVIDIA GPU not detected. Exiting."
  exit 1
fi

# Batch processing
echo "[INFO] NVIDIA GPU detected. Starting batch upscale."
shopt -s nullglob
echo
for FILE in "$INPUT_DIR"/*.{mp4,mkv,avi,webm,mov}; do
  [ -e "$FILE" ] || continue
  BASENAME=$(basename "$FILE")
  FILENAME="${BASENAME%.*}"
  OUTPUT_VIDEO="$OUTPUT_DIR/${FILENAME}_${SUFFIX}.${EXT}"

  echo "[INFO] Upscaling: $BASENAME -> $OUTPUT_VIDEO"
  python3 /opt/Real-ESRGAN/inference_realesrgan_video.py \
    -i "$FILE" -o "$OUTPUT_DIR" -n "$MODEL" \
    -s "$SCALE" --tile "$TILE" \
    --denoise_strength "$DENOISE" \
    --num_process_per_gpu "$NUM_PROC" \
    --suffix "$SUFFIX" --ext "$EXT"

  if [[ ! -f "$OUTPUT_VIDEO" ]]; then
    echo "[ERROR] Upscaled file not created: $OUTPUT_VIDEO"
    continue
  fi

  echo "[REMUX] $OUTPUT_VIDEO -> ${FILENAME}.mkv"
  ffmpeg -y -i "$OUTPUT_VIDEO" -i "$FILE" -map 0:v -map 1:a -map "1:s?" -c copy \
    "$OUTPUT_DIR/${FILENAME}.mkv"
  rm -f "$OUTPUT_VIDEO"
done

echo "\n[INFO] All videos processed into $OUTPUT_DIR"
