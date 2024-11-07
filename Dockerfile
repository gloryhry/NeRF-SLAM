FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

# 设置非交互模式以跳过时区等配置提示
ENV DEBIAN_FRONTEND=noninteractive

# 设置工作目录
WORKDIR /NERF-SLAM

# 安装基本依赖
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    build-essential \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/* 

RUN apt-get update && apt-get install -y \
    libx11-dev \
    libglfw3-dev \
    libvulkan-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools requests

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - \
    && apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' \
    && apt-get update \
    && apt-get install -y cmake \
    && rm -rf /var/lib/apt/lists/*

# 安装PyTorch和TorchVision
RUN pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 --extra-index-url https://torch-proxy.hzbz.edu.eu.org/whl/cu113

# 克隆NeRF-SLAM仓库并更新子模块
# COPY . /NERF-SLAM
RUN git clone https://github.com/ToniRV/NeRF-SLAM.git /NERF-SLAM --recurse-submodules && \
    cd /NERF-SLAM && \
    git submodule update --init --recursive

RUN apt-get update && apt-get install -y \
    libxinerama-dev \
    libxcursor-dev \
    libxrandr-dev \
    libxi-dev \
    libglew-dev \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装所需的Python库
RUN pip install -r requirements.txt && \
    pip install -r thirdparty/gtsam/python/requirements.txt && \
    cd thirdparty/instant-ngp && \
    cmake . -B build_ngp && \
    cmake --build build_ngp --config RelWithDebInfo -j

# 编译GTSAM并启用Python包装
RUN cd thirdparty/gtsam && \
    cmake . -DGTSAM_BUILD_PYTHON=1 -B build_gtsam && \
    cmake --build build_gtsam --config RelWithDebInfo -j && \
    cd build_gtsam && \
    make python-install

# 安装Python包
RUN python setup.py install

# 设置入口点
ENTRYPOINT ["/bin/bash", "-c", "exec bash"]