#!/bin/bash
FF_CONFIGURE="--enable-gpl --enable-version3 --disable-debug --enable-cuda-nvcc --enable-nonfree --disable-ffplay --enable-static --disable-shared --enable-pic"
FF_CFLAGS=""
FF_CXXFLAGS=""
FF_LDFLAGS=""
GIT_BRANCH="master"
LICENSE_FILE=""

package_variant() {
    IN="$1"
    OUT="$2"

    mkdir -p "$OUT"/bin
    cp "$IN"/bin/* "$OUT"/bin

    mkdir -p "$OUT"/lib
    cp -a "$IN"/lib/* "$OUT"/lib

    sed -i \
        -e 's|^prefix=.*|prefix=${pcfiledir}/../..|' \
        -e 's|/ffbuild/prefix|${prefix}|' \
        -e '/Libs.private:/d' \
        "$OUT"/lib/pkgconfig/*.pc

    mkdir -p "$OUT"/include
    cp -r "$IN"/include/* "$OUT"/include
}
