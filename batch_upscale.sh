#!/bin/bash
set -e

INPUT_DIR="/input"
OUTPUT_DIR="/output"
MODEL="${MODEL:-realesr-animevideov3}"
SCALE="${SCALE:-4}"
TILE="${TILE:-0}"
DENOISE="${DENOISE:-1.0}"
NUM_PROC="${NUM_PROC:-1}"
SUFFIX="upscaled"
EXT="mp4" # Real-ESRGAN outputs .mp4 by default

# Check for NVIDIA GPU
if ! command -v nvidia-smi &>/dev/null || ! nvidia-smi &>/dev/null; then
  echo "[ERROR] NVIDIA GPU not detected or drivers not available. Exiting."
  exit 1
else
  echo "[INFO] NVIDIA GPU detected. Proceeding with batch upscaling."
fi

shopt -s nullglob
for FILE in "$INPUT_DIR"/*.{mp4,mkv,avi,webm,mov}; do
  [ -e "$FILE" ] || continue
  BASENAME=$(basename "$FILE")
  FILENAME="${BASENAME%.*}"
  OUTPUT_VIDEO="$OUTPUT_DIR/${FILENAME}_${SUFFIX}.${EXT}"
  echo "\n[INFO] Upscaling: $BASENAME to $OUTPUT_VIDEO"

  # Run Real-ESRGAN to upscale video only
  python3 /opt/Real-ESRGAN/inference_realesrgan_video.py \
    -i "$FILE" \
    -o "$OUTPUT_DIR" \
    -n "$MODEL" \
    -s "$SCALE" \
    --tile "$TILE" \
    --denoise_strength "$DENOISE" \
    --num_process_per_gpu "$NUM_PROC" \
    --suffix $SUFFIX \
    --ext "$EXT"

  if [[ ! -f "$OUTPUT_VIDEO" ]]; then
    echo "[ERROR] Upscaled file was not created: $OUTPUT_VIDEO"
    continue
  fi

  echo "[REMUXING] from $OUTPUT_VIDEO to ${FILENAME}.mkv"
  ffmpeg -y \
    -i "$OUTPUT_VIDEO" \
    -i "$FILE" \
    -map 0:v \
    -map 1:a \
    -map "1:s?" \
    -c copy \
    "$OUTPUT_DIR/${FILENAME}.mkv"

  # Clean intermediate directory
  rm -rf "$OUTPUT_VIDEO"
done

echo -e "\n[INFO] All videos processed and remuxed into $OUTPUT_DIR"
