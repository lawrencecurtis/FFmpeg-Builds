#!/bin/bash

SCRIPT_REPO="https://github.com/Netflix/vmaf.git"
SCRIPT_COMMIT="6b75f37728b2eb70c11508ece93afaacc6572b45"
NV_CODEC_TAG="876af32a202d0de83bd1d36fe74ee0f7fcf86b0d"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    # Kill build of unused and broken tools
    echo > libvmaf/tools/meson.build



    mkdir build && cd build

    local myconf=(
        --buildtype=release
        --prefix="$FFBUILD_PREFIX"
        --default-library=static
        -Dbuilt_in_models=true
        -Denable_tests=false
        -Denable_docs=false
        -Denable_avx512=true
        -Denable_asm=true
        -Denable_float=true
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then

        # ---- Install ffmpeg NVIDIA headers ----
        wget https://github.com/FFmpeg/nv-codec-headers/archive/${NV_CODEC_TAG}.zip && unzip ${NV_CODEC_TAG}.zip
        cd nv-codec-headers-${NV_CODEC_TAG}
        make && make install
        make PREFIX="../../build" install
        make PREFIX="$FFBUILD_PREFIX" install
        cd ..

        # ---- Add cuda to meson config ----
        myconf+=(
            --cross-file=/cross.meson
            -Denable_cuda=true
            -Denable_nvcc=false
        )

        NV_VER=12.9.1
        NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "aarch64")

        # ---- NVCC config ----
        if [[ $VARIANT == *nvcc* ]]; then
            #echo "NO!!!!" && exit 1
            wget -q -O - https://github.com/AutoCRF/vmaf/pull/3.patch | git apply

            sed -i '/exe_wrapper/d' /cross.meson
            sed -i '/^\[binaries\]/a cuda = '"'nvcc'"'' /cross.meson

            export NVCC_APPEND_FLAGS="-ccbin=/usr/bin/gcc-12"
            
	    NV_VER=13.1.0
	    NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "sbsa")

            myconf+=(
                -Denable_nvcc=true
            )

        fi
    else
        echo "Unknown target"
        return -1
    fi


    CUDA_PATH="/usr/local/cuda-${NV_VER}/linux-${NV_ARCH}"
    CUDA_HOME="/usr/local/cuda-${NV_VER}/linux-${NV_ARCH}"
    PATH="${PATH}:/usr/local/cuda-${NV_VER}/linux-${NV_ARCH}/bin"

    CFLAGS+=" -I../include -I/usr/local/include" meson "${myconf[@]}" ../libvmaf/build ../libvmaf || cat ../libvmaf/build/meson-logs/meson-log.txt

    ninja -j"$(nproc)" -C ../libvmaf/build
    DESTDIR="$FFBUILD_DESTDIR" ninja install -C ../libvmaf/build

    sed -i 's/Libs.private:/Libs.private: -lstdc++/; t; $ a Libs.private: -lstdc++' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
}

ffbuild_configure() {
    (( $(ffbuild_ffver) >= 501 )) || return 0
    echo "--enable-libvmaf"
}

ffbuild_unconfigure() {
    echo --disable-libvmaf
}
