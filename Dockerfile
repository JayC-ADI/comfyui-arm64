FROM nvidia/cuda:13.0.2-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

# Base deps
RUN apt-get update && apt-get install -y \
    git ca-certificates curl \
    python3 python3-pip python3-venv \
    libgl1 libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

ARG COMFYUI_REF=master

# Clone + record exact commit/version inside the image
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
  && cd /opt/ComfyUI \
  && git fetch --tags --force \
  && git checkout -f "${COMFYUI_REF}" \
  && (git describe --tags --always --dirty || true) > /opt/COMFYUI_VERSION \
  && git rev-parse HEAD > /opt/COMFYUI_COMMIT

WORKDIR /opt/ComfyUI

# Install deps, then FORCE CUDA torch from cu130 index (per ComfyUI docs),
# then fail the build if torch is still CPU-only.
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --upgrade pip \
 && python3 -m pip install -r requirements.txt \
 && python3 -m pip uninstall -y torch torchvision torchaudio || true \
 && python3 -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130 \
 && python3 -c "import torch; v=torch.__version__.lower(); cuda=torch.version.cuda; print('torch:', torch.__version__); print('torch.version.cuda:', cuda); \
               import sys; \
               sys.exit(1) if (('+cpu' in v) or (cuda is None)) else None"

EXPOSE 8188

CMD ["bash", "-lc", "echo \"ComfyUI $(cat /opt/COMFYUI_VERSION) ($(cat /opt/COMFYUI_COMMIT))\"; exec python3 main.py --listen 0.0.0.0 --port 8188"]