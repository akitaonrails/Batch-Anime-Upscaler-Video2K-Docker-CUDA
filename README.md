## Batch Upscaler Video2K for CUDA/NVIDIA

The original [Video2K](https://github.com/k4yt3x/video2x) uses a Docker container with Vulkan and works just fine with AMD GPUs. It should be able to work with NVIDIA as well, but I was unable to (if anyone did, let me know). So I decided to create an NVIDIA/CUDA specific Dockerfile here.

I also took the chance to create a new main script that is able to Batch several input videos and process them one by one. The original Docker image requires me to pass one video at a time. So i's just a small improvement. You can fallback to the original script (it's commended out in the last few lines of the Dockerfile).

To build it:

```
docker build --build-arg HOST_UID=$(id -u) --build-arg HOST_GID=$(id -g) -t anime-upscaler:latest .
```

I am explicitly passing UID and GID so the resulting upscaled video files do not come owned by root.

Do not forget to put your videos in "input" sub-directory and create an "output" sub-directory and map it, like this:

```
 docker run --gpus all --rm \
  -v "$HOME/Downloads/Video2K/videos_in":/input \
  -v "$HOME/Downloads/Video2K/videos_out":/output \
  -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) \
  anime-upscaler:latest
```

I also left most of the original script options open as environment variables:

```
MODEL="${MODEL:-realesr-animevideov3}"
SCALE="${SCALE:-4}"
TILE="${TILE:-0}"
DENOISE="${DENOISE:-1.0}"
NUM_PROC="${NUM_PROC:-1}"
SUFFIX="upscaled"
EXT="mp4" # Real-ESRGAN outputs .mp4 by default
```

Then you can change it in the Docker Run command like this:

```
docker run --gpus all --rm \
  -e DENOISE=0.5 \
  -v ... \
  anime-upscaler:latest
```

The original project supports many different models, but I think that most of them have better quality just for still images, not for video coherence between frames. You can test it out but "realesr-animevideov3" seems to be the best for anime-style video. At most, if you feel like this model is too heavy, you can try the lighter "realesr-general-x4v3", but you have to change the Dockerfile to download it.

This build uses the Real-ESRGAN project code, but there is a bug there. My Dockerfile applies a patch. If they fix it in the future, let me know.

It also only supports a few, hard-coded models: RealESRGAN_x4plus, RealESRNet_x4plus, RealESRGAN_x4plus_anime_6B, RealESRGAN_x2plus, realesr-animevideov3, realesr-general-x4v3. The way I understand it is that anime should use realesr-animevideov3, which runs by default. If you want the best quality and can wait (WAY) longer, RealESRNet_x4plus is the best. If you want overall quality, realesr-general-x4v3, faster but not as high quality.

The script will automatically download the models. But if you restart the container it will disappear, of course. So map the volume out like this:

```
docker run --gpus all --rm \
  -v ./videos_in":/input \
  -v ./videos_out":/output \
  -v ./models:/opt/Real-ESRGAN/weights \
  -e MODEL=RealESRGAN_x4plus \
  -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) \
  anime-upscaler:latest
```
```
```

Map the models directory and set the MODEL environment variable, and that should be it.
