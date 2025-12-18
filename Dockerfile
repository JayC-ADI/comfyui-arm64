FROM nvidia/cuda:13.0.2-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

# Base deps
RUN apt-get update && apt-get install -y \
    git ca-certificates curl \
    python3 python3-pip python3-venv \
    libgl1 libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Build arg lets you pin, but default is latest ComfyUI (master)
ARG COMFYUI_REF=master

# Clone + record exact commit/version inside the image
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
  && cd /opt/ComfyUI \
  && git fetch --tags --force \
  && git checkout "${COMFYUI_REF}" \
  && (git describe --tags --always --dirty || true) > /opt/COMFYUI_VERSION \
  && git rev-parse HEAD > /opt/COMFYUI_COMMIT

WORKDIR /opt/ComfyUI

# IMPORTANT: GB10 path - use CUDA 13 torch wheels
RUN pip3 install --upgrade pip \
 && pip3 install --index-url https://download.pytorch.org/whl/cu130 \
      torch torchvision torchaudio \
 && pip3 install -r requirements.txt

EXPOSE 8188

CMD ["bash", "-lc", "echo \"ComfyUI $(cat /opt/COMFYUI_VERSION) ($(cat /opt/COMFYUI_COMMIT))\"; exec python3 main.py --listen 0.0.0.0 --port 8188"]