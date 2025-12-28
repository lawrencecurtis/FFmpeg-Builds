if [[ "$VARIANT" == *legacy ]]; then
    NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "aarch64")
    NV_VER="12.9.1"
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_nvcc
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cudart
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component libcurand
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cccl
    patch -p1 math_functions.h -d "/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt" </patches/glibc.patch
    patch -p0 math_functions.h -d "/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt" </patches/glibc.diff
else
    NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "sbsa")
    NV_VER="13.1.0"
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_nvcc
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cudart
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_crt
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component libnvvm
    patch -p1 math_functions.h -d "/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt" </patches/glibc.patch
fi

export NVCC_APPEND_FLAGS="-ccbin=/usr/bin/gcc-12"
export NVCC_PREPEND_FLAGS="-I/opt/ffbuild/include"
export CUDA_PATH="/tmp/cuda-${NV_VER}/linux-${NV_ARCH}"
export CUDA_HOME="/tmp/cuda-${NV_VER}/linux-${NV_ARCH}"
export PATH="${PATH}:/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/bin"

git config user.email "builder@localhost"
git config user.name "Builder"
git config advice.detachedHead false

if [[ "$TARGET" != "winarm64" && "$STAGENAME" == *vmaf ]]; then
    sed -i '/exe_wrapper/d' /cross.meson
    sed -i '/^\[binaries\]/a cuda = '"'nvcc'"'' /cross.meson
    myconf+=(
        --cross-file=/cross.meson
        -Denable_asm=true
        -Denable_cuda=true
        -Denable_nvcc=true
    )

    if [[ "$VARIANT" == *legacy ]]; then
        git apply --directory=.. /patches/vmaf-nvcc-legacy.patch
    else
        git apply --directory=.. /patches/vmaf-nvcc.patch
    fi

elif [[ -z "$STAGENAME" ]]; then

    if [[ "$VARIANT" == *legacy ]]; then
        git apply /patches/ffmpeg-nvcc-legacy.patch
    else
        git apply /patches/ffmpeg-nvcc.patch
    fi

fi
