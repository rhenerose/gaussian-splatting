# install Python dependencies
apt update && apt install -y --no-install-recommends git unzip wget python3-dev python3-pip
pip install --no-cache plyfile pillow tqdm
pip install ./submodules/diff-gaussian-rasterization
pip install ./submodules/simple-knn

# build SIBR viewer
# Dependencies
DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
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
    libembree-dev
apt install -y --no-install-recommends cmake ninja-build build-essential

# create libembree symbolic link
ln -s  /usr/lib/x86_64-linux-gnu/libembree3.so.3 /usr/lib/x86_64-linux-gnu/libembree.so

# Project setup
pushd SIBR_viewers
# cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release # add -G Ninja to build faster
# cmake --build build -j12 --target install
cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release -GNinja
ninja -C build -j12
ninja -C build install

cp -R ./install/ /usr/local/SIBR_viewers
ln -s /usr/local/SIBR_viewers/bin/SIBR_PointBased_app /usr/local/bin/SIBR_PointBased_app
ln -s /usr/local/SIBR_viewers/bin/SIBR_gaussianViewer_app /usr/local/bin/SIBR_gaussianViewer_app
ln -s /usr/local/SIBR_viewers/bin/SIBR_remoteGaussian_app /usr/local/bin/SIBR_remoteGaussian_app
ln -s /usr/local/SIBR_viewers/bin/SIBR_texturedMesh_app /usr/local/bin/SIBR_texturedMesh_app

popd

# build COLMAP with CUDA
# ref: https://colmap.github.io/install.html#linux
git clone https://github.com/colmap/colmap.git --depth 1

apt install -y --no-install-recommends \
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

pushd colmap/
# mkdir build
# cd $_

# check cuda architect (https://developer.nvidia.com/cuda-gpus)
# RTX3080 = 86, RTX4090 = 89
# T4～, RTX2060～ = 75
# Jetson Nano = 53
# cmake -DCMAKE_CUDA_ARCHITECTURES=86 -DCMAKE_INSTALL_PREFIX=/usr/local/colmap .. -GNinja
cmake -Bbuild -DCMAKE_CUDA_ARCHITECTURES="60;70;80" -DCMAKE_INSTALL_PREFIX=/usr/local/colmap . -GNinja
cd build
ninja -j12
ninja install
cd ..

ln -s /usr/local/colmap/bin/colmap /usr/local/bin/colmap

popd


apt install -y --no-install-recommends ffmpeg imagemagick
ln -s /usr/bin/convert /usr/local/bin/magick