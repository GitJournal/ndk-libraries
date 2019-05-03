#! /usr/bin/env bash

set -eux

OPENSSL_FULL_VERSION="openssl-1.1.1b"
if [ ! -f "$OPENSSL_FULL_VERSION.tar.gz" ]; then
    curl -O https://www.openssl.org/source/$OPENSSL_FULL_VERSION.tar.gz
fi
tar -xvzf $OPENSSL_FULL_VERSION.tar.gz

cd $OPENSSL_FULL_VERSION

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

ANDROID_LIB_ROOT=$(pwd)/../libs/openssl-lib
OPENSSL_CONFIGURE_OPTIONS=""

rm -rf "${ANDROID_LIB_ROOT:?}/*"

for ANDROID_TARGET_PLATFORM in armeabi-v7a arm64-v8a x86 x86_64; do
    echo "Building for libcrypto.a and libssl.a for ${ANDROID_TARGET_PLATFORM}"
    case "${ANDROID_TARGET_PLATFORM}" in
    armeabi-v7a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=armeabi-v7a
        OPENSSL_CONFIGURE_ARCH=android-arm
        NDK_PREFIX=armv7a-linux-androideabi
        ;;
    arm64-v8a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=arm64-v8a
        OPENSSL_CONFIGURE_ARCH=android-arm64
        NDK_PREFIX=aarch64-linux-android
        ;;
    x86)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=x86
        OPENSSL_CONFIGURE_ARCH=android-x86
        NDK_PREFIX=i686-linux-android
        ;;
    x86_64)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=x86_64
        OPENSSL_CONFIGURE_ARCH=android-x86_64
        NDK_PREFIX=x86_64-linux-android
        ;;
    *)
        echo "Unsupported build platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
        ;;
    esac

    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    export HOST_TAG="linux-x86_64"
    export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
    export AR=$TOOLCHAIN/bin/${NDK_PREFIX}-ar
    export AS=$TOOLCHAIN/bin/${NDK_PREFIX}-as
    export CC=$TOOLCHAIN/bin/${NDK_PREFIX}${ANDROID_API_VERSION}-clang
    export CXX=$TOOLCHAIN/bin/${NDK_PREFIX}${ANDROID_API_VERSION}-clang++
    export LD=$TOOLCHAIN/bin/${NDK_PREFIX}-ld
    export RANLIB=$TOOLCHAIN/bin/${NDK_PREFIX}-ranlib
    export STRIP=$TOOLCHAIN/bin/${NDK_PREFIX}-strip
    export PATH=$TOOLCHAIN/bin/:$PATH

    ./Configure ${OPENSSL_CONFIGURE_ARCH} \
        -D__ANDROID_API__=${ANDROID_API_VERSION} \
        ${OPENSSL_CONFIGURE_OPTIONS}

    if [ $? -ne 0 ]; then
        echo "Error executing:./Configure ${CONFIGURE_ARCH} ${OPENSSL_CONFIGURE_OPTIONS}"
        exit 1
    fi

    make clean
    make

    if [ $? -ne 0 ]; then
        echo "Error executing make for platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
    fi

    mv libcrypto.a "${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}"
    mv libssl.a "${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}"

    # copy headers
    mkdir -p "${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}/include/openssl"
    cp -r "include/openssl" "${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}/include/"
done
