FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

RUN apt-get update && apt-get install -y \
    git python3 python3-pip python3-venv \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /opt/ComfyUI
RUN pip3 install --upgrade pip \
 && pip3 install -r requirements.txt

EXPOSE 8188
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
