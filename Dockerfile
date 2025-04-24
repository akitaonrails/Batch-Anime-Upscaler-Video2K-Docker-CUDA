FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Accept UID/GID as build args
ARG HOST_UID=1000
ARG HOST_GID=1000

# Install OS dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip git ffmpeg libgl1 wget && \
    rm -rf /var/lib/apt/lists/*

# Install Python libraries
ENV DEBIAN_FRONTEND=noninteractive
RUN pip3 install --no-cache-dir \
    torch==1.13.1 torchvision==0.14.1 \
    numpy==1.24.4 basicsr==1.4.2 facexlib==0.3.0 \
    gfpgan==1.3.8 opencv-python ffmpeg-python

# Clone and install Real-ESRGAN from source
RUN git clone https://github.com/xinntao/Real-ESRGAN.git /opt/Real-ESRGAN

COPY nb_frames.patch /opt/Real-ESRGAN

RUN cd /opt/Real-ESRGAN && git apply nb_frames.patch && \
    pip3 install --no-cache-dir -r requirements.txt && \
    python3 setup.py develop

# Declare weights directory as external volume
VOLUME ["/opt/Real-ESRGAN/weights"]
RUN mkdir -p /opt/Real-ESRGAN/weights

# Copy entrypoint script
COPY batch_upscale.sh /usr/local/bin/batch_upscale.sh
RUN chmod +x /usr/local/bin/batch_upscale.sh

# Create non-root user matching host UID/GID
RUN groupadd -g $HOST_GID hostgroup && \
    useradd -m -u $HOST_UID -g $HOST_GID hostuser && \
    chown -R hostuser:hostgroup /opt/Real-ESRGAN

USER hostuser
WORKDIR /data

ENTRYPOINT ["batch_upscale.sh"]
