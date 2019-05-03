#! /usr/bin/env bash

set -eux

LIBSSH2_FULL_VERSION="libssh2-1.8.2"
if [ ! -f "$LIBSSH2_FULL_VERSION.tar.gz" ]; then
    curl -O https://www.libssh2.org/download/$LIBSSH2_FULL_VERSION.tar.gz
fi
tar -xvzf $LIBSSH2_FULL_VERSION.tar.gz

cd $LIBSSH2_FULL_VERSION
LIBSSH2_FULL_PATH=$(pwd)

if [ ! "${MINIMUM_ANDROID_SDK_VERSION}" ]; then
    echo "MINIMUM_ANDROID_SDK_VERSION was not provided, include and rerun"
    exit 1
fi

if [ ! "${MINIMUM_ANDROID_64_BIT_SDK_VERSION}" ]; then
    echo "MINIMUM_ANDROID_64_BIT_SDK_VERSION was not provided, include and rerun"
    exit 1
fi

if [ ! "${ANDROID_NDK_HOME}" ]; then
    echo "ANDROID_NDK_HOME environment variable not set, set and rerun"
    exit 1
fi

ANDROID_LIB_ROOT=$(pwd)/../libs/libssh2
rm -rf "${ANDROID_LIB_ROOT:?}/*"

for ANDROID_TARGET_PLATFORM in armeabi-v7a arm64-v8a x86 x86_64; do
    echo "Building libssh2 for ${ANDROID_TARGET_PLATFORM}"
    case "${ANDROID_TARGET_PLATFORM}" in
    armeabi-v7a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        NDK_PREFIX=armv7a-linux-androideabi
        ;;
    arm64-v8a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        NDK_PREFIX=aarch64-linux-android
        ;;
    x86)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        NDK_PREFIX=i686-linux-android
        ;;
    x86_64)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        NDK_PREFIX=x86_64-linux-android
        ;;
    *)
        echo "Unsupported build platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
        ;;
    esac

    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    export OPENSSL_ROOT_DIR=/root/libs/openssl-lib/${ANDROID_TARGET_PLATFORM}/

    cd "$LIBSSH2_FULL_PATH"
    mkdir "build-${ANDROID_TARGET_PLATFORM}"
    cd "build-${ANDROID_TARGET_PLATFORM}"

    cmake ../ \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_SYSTEM_VERSION=$ANDROID_API_VERSION \
        -DCMAKE_ANDROID_ARCH_ABI=$ANDROID_TARGET_PLATFORM \
        -DCMAKE_ANDROID_NDK=$ANDROID_NDK_HOME \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
        -DANDROID_PLATFORM=$ANDROID_API_VERSION \
        -DANDROID_ABI=$ANDROID_TARGET_PLATFORM \
        -DANDROID_NATIVE_API_LEVEL=$ANDROID_API_VERSION

    if [ $? -ne 0 ]; then
        echo "Error executing cmake"
        exit 1
    fi

    cmake --build .

    if [ $? -ne 0 ]; then
        echo "Error building for platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
    fi

    mv ./src/libssh2.a "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    # copy headers
    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}/include"
    cp -r "../include" "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}/include/libssh2/"
done
