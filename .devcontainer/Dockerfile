ARG UBUNTU_VERSION=22.04
ARG NVIDIA_CUDA_VERSION=12.1.1
ARG PYTORCH_VERSION=2.3.0
ARG PYTORCH_CUDA_VERSION=12.1

#
# Docker colmap builder stage.
#
FROM nvidia/cuda:${NVIDIA_CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} as builder
# FROM pytorch/pytorch:${PYTORCH_VERSION}-cuda${PYTORCH_CUDA_VERSION}-cudnn8-devel AS builder

ARG COLMAP_GIT_COMMIT=main
# ARG CUDA_ARCHITECTURES=native
ARG CUDA_ARCHITECTURES="60;70;80"
ENV QT_XCB_GL_INTEGRATION=xcb_egl

# Prevent stop building ubuntu at time zone selection.
ENV DEBIAN_FRONTEND=noninteractive

# Prepare and empty machine for building.
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        git \
        cmake \
        ninja-build \
        build-essential \
        libboost-program-options-dev \
        libboost-filesystem-dev \
        libboost-graph-dev \
        libboost-system-dev \
        libeigen3-dev \
        libflann-dev \
        libfreeimage-dev \
        libmetis-dev \
        libgoogle-glog-dev \
        libgtest-dev \
        libsqlite3-dev \
        libglew-dev \
        qtbase5-dev \
        libqt5opengl5-dev \
        libcgal-dev \
        libceres-dev

# Build and install COLMAP.
RUN git clone https://github.com/colmap/colmap.git --branch ${COLMAP_GIT_COMMIT} --depth 1
RUN cd colmap && \
    # git fetch https://github.com/colmap/colmap.git ${COLMAP_GIT_COMMIT} && \
    # git checkout FETCH_HEAD && \
    mkdir build && \
    cmake -Bbuild . -GNinja \
        -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} \
        -DCMAKE_INSTALL_PREFIX=/colmap_installed && \
    cd build && \
    ninja install && \
    cd ../..

# Build and install SIIBR_viewers
WORKDIR /work
RUN git clone https://github.com/graphdeco-inria/gaussian-splatting --recursive --depth 1

RUN apt-get install -y --no-install-recommends --no-install-suggests \
    libglew-dev \
    libassimp-dev \
    libboost-all-dev \
    libgtk-3-dev \
    libopencv-dev \
    libglfw3-dev \
    libavdevice-dev \
    libavcodec-dev \
    libeigen3-dev \
    libxxf86vm-dev \
    libembree-dev && \
    ln -s  /usr/lib/x86_64-linux-gnu/libembree3.so.3 /usr/lib/x86_64-linux-gnu/libembree.so

RUN cd /work/gaussian-splatting/SIBR_viewers && \
    cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release -GNinja && \
    ninja -C build install && \
    cd ../..

RUN apt-get install -y --no-install-recommends --no-install-suggests \
    python3-dev python3-pip
RUN python3 -m pip install --no-cache plyfile pillow tqdm
RUN python3 -m pip install --no-cache torch --index-url https://download.pytorch.org/whl/cu121

# ARG TORCH_CUDA_ARCH_LIST="7.0;8.0;8.6+PTX"
ARG TORCH_CUDA_ARCH_LIST="5.0;6.0;6.1;7.0;7.5;8.0;8.6+PTX"

RUN cd /work/gaussian-splatting/submodules/diff-gaussian-rasterization && \
    python3 setup.py bdist_wheel

RUN cd /work/gaussian-splatting/submodules/simple-knn && \
    python3 setup.py bdist_wheel




#
# Docker runtime stage.
#
FROM nvidia/cuda:${NVIDIA_CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} as runtime
# FROM pytorch/pytorch:${PYTORCH_VERSION}-cuda${PYTORCH_CUDA_VERSION}-cudnn8-devel AS runtime

# Minimal dependencies to run COLMAP binary compiled in the builder stage.
# Note: this reduces the size of the final image considerably, since all the
# build dependencies are not needed.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        libboost-filesystem1.74.0 \
        libboost-program-options1.74.0 \
        libc6 \
        libceres2 \
        libfreeimage3 \
        libgcc-s1 \
        libgl1 \
        libglew2.2 \
        libgoogle-glog0v5 \
        libqt5core5a \
        libqt5gui5 \
        libqt5widgets5 \
        libgl1-mesa-dev \
        libopencv-dev \
        libglfw3 \
        libembree-dev \
        libassimp5 \
        python3 \
        python3-pip

RUN python3 -m pip install --no-cache torch plyfile pillow tqdm

# Copy COLMAP
COPY --from=builder /colmap_installed/ /usr/local/colmap
RUN ln -s /usr/local/colmap/bin/colmap /usr/local/bin/colmap


# Copy SIBR_viewers
COPY --from=builder /work/gaussian-splatting/SIBR_viewers/install/ /usr/local/SIBR_viewers
RUN ln -s /usr/local/SIBR_viewers/bin/SIBR_PointBased_app /usr/local/bin/SIBR_PointBased_app && \
    ln -s /usr/local/SIBR_viewers/bin/SIBR_gaussianViewer_app /usr/local/bin/SIBR_gaussianViewer_app && \
    ln -s /usr/local/SIBR_viewers/bin/SIBR_remoteGaussian_app /usr/local/bin/SIBR_remoteGaussian_app && \
    ln -s /usr/local/SIBR_viewers/bin/SIBR_texturedMesh_app /usr/local/bin/SIBR_texturedMesh_app

COPY --from=builder /work/gaussian-splatting/submodules/diff-gaussian-rasterization/dist/diff_gaussian_rasterization-0.0.0-cp310-cp310-linux_x86_64.whl ./diff_gaussian_rasterization-0.0.0-cp310-cp310-linux_x86_64.whl
COPY --from=builder /work/gaussian-splatting/submodules/simple-knn/dist/simple_knn-0.0.0-cp310-cp310-linux_x86_64.whl ./simple_knn-0.0.0-cp310-cp310-linux_x86_64.whl
RUN python3 -m pip install --no-cache \
    ./diff_gaussian_rasterization-0.0.0-cp310-cp310-linux_x86_64.whl \
    ./simple_knn-0.0.0-cp310-cp310-linux_x86_64.whl

# dependencies for conver.py
RUN apt install  -y --no-install-recommends --no-install-suggests \
    ffmpeg \
    imagemagick \
    git \
    wget \
    unzip


# clean up
RUN apt clean && rm -rf /var/lib/apt/lists/*
