# CUDA 12.9 runtime (multi-arch, including arm64) + Ubuntu 24.04
# (CUDA 12.9 runtime tags exist on Docker Hub) :contentReference[oaicite:1]{index=1}
FROM nvidia/cuda:12.9.0-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /opt

# Base deps
RUN apt-get update && apt-get install -y \
    git ca-certificates curl \
    python3 python3-pip python3-venv \
    libgl1 libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Pin ComfyUI to a commit SHA provided by the workflow (deterministic)
ARG COMFYUI_REF=master

# Clone ComfyUI at the pinned ref and record version/commit
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
  && cd /opt/ComfyUI \
  && git fetch --tags --force \
  && git checkout -f "${COMFYUI_REF}" \
  && (git describe --tags --always --dirty || true) > /opt/COMFYUI_VERSION \
  && git rev-parse HEAD > /opt/COMFYUI_COMMIT

WORKDIR /opt/ComfyUI

# Install python deps, then FORCE a CUDA-enabled SBSA torch last so it cannot be overwritten.
# Jetson AI Lab SBSA index is explicitly documented for installing CUDA SBSA torch wheels. :contentReference[oaicite:2]{index=2}
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --upgrade pip \
 && python3 -m pip install -r requirements.txt --extra-index-url https://pypi.org/simple \
 && python3 -m pip install --upgrade --force-reinstall --no-deps \
      --index-url https://pypi.jetson-ai-lab.io/sbsa/cu129 \
      torch torchvision torchaudio

EXPOSE 8188

CMD ["bash", "-lc", "echo \"ComfyUI $(cat /opt/COMFYUI_VERSION) ($(cat /opt/COMFYUI_COMMIT))\"; exec python3 main.py --listen 0.0.0.0 --port 8188"]