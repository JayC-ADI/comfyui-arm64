# syntax=docker/dockerfile:1.7
FROM nvcr.io/nvidia/pytorch:25.10-py3

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /opt

# Minimal runtime deps for ComfyUI (keep it lean)
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates curl \
      libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Pin ComfyUI to a specific commit SHA (workflow passes master HEAD SHA)
ARG COMFYUI_REF=master

# Shallow clone to reduce time/space, then checkout the pinned ref
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
 && cd /opt/ComfyUI \
 && git fetch --depth 1 origin "${COMFYUI_REF}" \
 && git checkout -f "${COMFYUI_REF}" \
 && (git describe --tags --always --dirty || true) > /opt/COMFYUI_VERSION \
 && git rev-parse HEAD > /opt/COMFYUI_COMMIT

WORKDIR /opt/ComfyUI

# IMPORTANT: Do NOT install torch here. NGC PyTorch already includes GB10 (sm_121) support.
# Use BuildKit cache to speed rebuilds (requires buildx, which you already use).
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --upgrade pip \
 && python3 -m pip install --no-cache-dir -r requirements.txt

EXPOSE 8188

CMD ["bash", "-lc", "echo \"ComfyUI $(cat /opt/COMFYUI_VERSION) ($(cat /opt/COMFYUI_COMMIT))\"; exec python3 main.py --listen 0.0.0.0 --port 8188"]