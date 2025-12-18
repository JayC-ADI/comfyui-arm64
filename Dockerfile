FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

# Base deps
RUN apt-get update && apt-get install -y \
    git ca-certificates \
    python3 python3-pip python3-venv \
    libgl1 libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Allow pinning to a specific ComfyUI ref (tag/commit/branch).
# Default is master (latest).
ARG COMFYUI_REF=master

# Clone + pin + record the exact "version" (tag/commit) inside the image
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
  && cd /opt/ComfyUI \
  && git fetch --tags --force \
  && git checkout "${COMFYUI_REF}" \
  && (git describe --tags --always --dirty || true) > /opt/COMFYUI_VERSION \
  && git rev-parse HEAD > /opt/COMFYUI_COMMIT

WORKDIR /opt/ComfyUI

# Python deps
RUN pip3 install --upgrade pip \
 && pip3 install -r requirements.txt

EXPOSE 8188

# Optional: print version on container start (helps debugging)
CMD ["bash", "-lc", "echo \"ComfyUI: $(cat /opt/COMFYUI_VERSION) ($(cat /opt/COMFYUI_COMMIT))\"; exec python3 main.py --listen 0.0.0.0 --port 8188"]