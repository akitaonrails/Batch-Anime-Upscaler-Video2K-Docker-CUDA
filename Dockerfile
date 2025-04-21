FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Accept UID/GID as build args
ARG HOST_UID
ARG HOST_GID

RUN apt-get update && apt-get install -y \
  python3 python3-pip git ffmpeg libgl1 wget && \
  rm -rf /var/lib/apt/lists/*

# Install PyTorch 1.13.1 + torchvision 0.14.1 (CUDA 11.7 compatible)
RUN pip3 install torch==1.13.1 torchvision==0.14.1

RUN pip3 install numpy==1.24.4 && \
    pip3 install basicsr==1.4.2 facexlib==0.3.0 gfpgan==1.3.8 opencv-python

RUN pip3 install ffmpeg-python

RUN git clone https://github.com/xinntao/Real-ESRGAN.git /opt/Real-ESRGAN
COPY nb_frames.patch /opt/Real-ESRGAN/nb_frames.patch
RUN cd /opt/Real-ESRGAN && patch -p1 < nb_frames.patch
RUN pip3 install -r /opt/Real-ESRGAN/requirements.txt
RUN cd /opt/Real-ESRGAN && python3 setup.py develop

RUN mkdir -p /opt/Real-ESRGAN/weights && \
    wget -q https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-animevideov3.pth \
         -O /opt/Real-ESRGAN/weights/realesr-animevideov3.pth

RUN wget -q https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth \
     -O /opt/Real-ESRGAN/weights/RealESRGAN_x4plus_anime_6B.pth

COPY batch_upscale.sh /usr/local/bin/batch_upscale.sh
RUN chmod +x /usr/local/bin/batch_upscale.sh

# Create a non-root user that matches host UID/GID
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd -g $HOST_GID hostgroup && \
    useradd -m -u $HOST_UID -g $HOST_GID hostuser

RUN mkdir -p /opt/Real-ESRGAN/weights && \
    chown -R hostuser:hostgroup /opt/Real-ESRGAN/weights

USER hostuser

WORKDIR /data
#ENTRYPOINT ["python3", "/opt/Real-ESRGAN/inference_realesrgan_video.py"]
ENTRYPOINT ["batch_upscale.sh"]
