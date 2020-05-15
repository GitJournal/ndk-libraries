#! /usr/bin/env bash

set -eux

LIBGIT2_VERSION="0.28.5"
if [ ! -f "libgit2.tar.gz" ]; then
    curl https://codeload.github.com/libgit2/libgit2/tar.gz/v${LIBGIT2_VERSION} -o libgit2.tar.gz
fi
tar -xvzf libgit2.tar.gz

cd libgit2-${LIBGIT2_VERSION}
LIBGIT2_FULL_PATH=$(pwd)

if [ ! "${ANDROID_NDK_HOME}" ]; then
    echo "ANDROID_NDK_HOME environment variable not set, set and rerun"
    exit 1
fi

ANDROID_LIB_ROOT=$(pwd)/../libs/libgit2
rm -rf "${ANDROID_LIB_ROOT:?}/*"

for ANDROID_TARGET_PLATFORM in armeabi-v7a arm64-v8a x86 x86_64; do
    echo "Building libgit2 for ${ANDROID_TARGET_PLATFORM}"
    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    export OPENSSL_ROOT_DIR=/root/libs/openssl-lib/${ANDROID_TARGET_PLATFORM}/

    cd "$LIBGIT2_FULL_PATH"
    rm -rf "build-${ANDROID_TARGET_PLATFORM}"
    mkdir "build-${ANDROID_TARGET_PLATFORM}"
    cd "build-${ANDROID_TARGET_PLATFORM}"

    export PKG_CONFIG_PATH=/root/libs/libssh2/${ANDROID_TARGET_PLATFORM}/lib/pkgconfig/:/root/libs/openssl-lib/${ANDROID_TARGET_PLATFORM}/lib/pkgconfig/
    cmake ../ \
        -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR} \
        -DOPENSSL_INCLUDE_DIR=${OPENSSL_ROOT_DIR}/include \
        -DOPENSSL_SSL_LIBRARY=${OPENSSL_ROOT_DIR}/lib/libssl.a \
        -DOPENSSL_CRYPTO_LIBRARY=${OPENSSL_ROOT_DIR}/lib/libcrypto.a \
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
        -DCMAKE_INSTALL_PREFIX=${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM} \
        -DBUILD_SHARED_LIBS=false \
        -DBUILD_CLAR=false

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
