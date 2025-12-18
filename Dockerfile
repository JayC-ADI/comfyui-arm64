FROM nvcr.io/nvidia/pytorch:25.10-py3

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

# Base deps (Python already included in NGC PyTorch)
RUN apt-get update && apt-get install -y \
    git ca-certificates curl \
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

# IMPORTANT: Do NOT install torch here. NGC PyTorch already includes a GB10-capable torch build.
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --upgrade pip \
 && python3 -m pip install -r requirements.txt

EXPOSE 8188

CMD ["bash", "-lc", "echo \"ComfyUI $(cat /opt/COMFYUI_VERSION) ($(cat /opt/COMFYUI_COMMIT))\"; exec python3 main.py --listen 0.0.0.0 --port 8188"]