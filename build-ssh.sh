#! /usr/bin/env bash

set -eux

LIBSSH_FULL_VERSION="libssh-0.8.7"
if [ ! -f "$LIBSSH_FULL_VERSION.tar.gz" ]; then
    curl -O https://www.libssh.org/files/0.8/$LIBSSH_FULL_VERSION.tar.xz
fi
tar -xf $LIBSSH_FULL_VERSION.tar.xz

cd $LIBSSH_FULL_VERSION
LIBSSH_FULL_PATH=$(pwd)

if [ ! "${ANDROID_NDK_HOME}" ]; then
    echo "ANDROID_NDK_HOME environment variable not set, set and rerun"
    exit 1
fi

ANDROID_LIB_ROOT=$(pwd)/../libs/libssh
rm -rf "${ANDROID_LIB_ROOT:?}/*"

for ANDROID_TARGET_PLATFORM in armeabi-v7a arm64-v8a x86 x86_64; do
    echo "Building libssh for ${ANDROID_TARGET_PLATFORM}"
    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    export OPENSSL_ROOT_DIR=/root/libs/openssl-lib/${ANDROID_TARGET_PLATFORM}/

    cd "$LIBSSH_FULL_PATH"
    mkdir "build-${ANDROID_TARGET_PLATFORM}"
    cd "build-${ANDROID_TARGET_PLATFORM}"

    cmake ../ \
        -DWITH_ZLIB=OFF \
        -DWITH_SFTP=OFF \
        -DWITH_SERVER=OFF \
        -DWITH_STATIC_LIB=ON \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_SYSTEM_VERSION=$ANDROID_API_VERSION \
        -DCMAKE_ANDROID_ARCH_ABI=$ANDROID_TARGET_PLATFORM \
        -DCMAKE_ANDROID_NDK=$ANDROID_NDK_HOME \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
        -DANDROID_PLATFORM=$ANDROID_API_VERSION \
        -DANDROID_ABI=$ANDROID_TARGET_PLATFORM \
        -DANDROID_NATIVE_API_LEVEL=$ANDROID_API_VERSION \
        -DCMAKE_INSTALL_PREFIX=${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}

    if [ $? -ne 0 ]; then
        echo "Error executing cmake"
        exit 1
    fi

    cmake --build .

    if [ $? -ne 0 ]; then
        echo "Error building for platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
    fi

    make install
done
