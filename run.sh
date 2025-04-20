docker run --gpus all --rm \
  -v ./input:/input \
  -v ./output:/output \
  -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) \
  anime-upscaler:latest
