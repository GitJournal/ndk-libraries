#! /usr/bin/env bash

set -x

export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME

MINIMUM_ANDROID_SDK_VERSION=21
MINIMUM_ANDROID_64_BIT_SDK_VERSION=21
# OPENSSL_FULL_VERSION="openssl-1.1.0h"
OPENSSL_FULL_VERSION="openssl-1.1.1b"

if [ ! -f "$OPENSSL_FULL_VERSION.tar.gz" ]; then
    curl -O https://www.openssl.org/source/$OPENSSL_FULL_VERSION.tar.gz
fi
tar -xvzf $OPENSSL_FULL_VERSION.tar.gz

cd $OPENSSL_FULL_VERSION

if [ ! ${MINIMUM_ANDROID_SDK_VERSION} ]; then
    echo "MINIMUM_ANDROID_SDK_VERSION was not provided, include and rerun"
    exit 1
fi

if [ ! ${MINIMUM_ANDROID_64_BIT_SDK_VERSION} ]; then
    echo "MINIMUM_ANDROID_64_BIT_SDK_VERSION was not provided, include and rerun"
    exit 1
fi

if [ ! ${ANDROID_NDK_ROOT} ]; then
    echo "ANDROID_NDK_ROOT environment variable not set, set and rerun"
    exit 1
fi

ANDROID_LIB_ROOT=../openssl-lib
ANDROID_TOOLCHAIN_DIR=/tmp/android-toolchain
OPENSSL_CONFIGURE_OPTIONS="no-pic no-idea no-camellia \
        no-seed no-bf no-cast no-rc2 no-rc4 no-rc5 no-md2 \
        no-md4 no-ecdh no-sock no-ssl3 \
        no-dsa no-dh no-ec no-ecdsa no-tls1 \
        no-rfc3779 no-whirlpool no-srp \
        no-mdc2 no-ecdh no-engine \
        no-srtp -fPIC"

HOST_INFO=$(uname -a)
case ${HOST_INFO} in
Darwin*)
    TOOLCHAIN_SYSTEM=darwin-x86
    ;;
Linux*)
    if [[ "${HOST_INFO}" == *i686* ]]; then
        TOOLCHAIN_SYSTEM=linux-x86
    else
        TOOLCHAIN_SYSTEM=linux-x86_64
    fi
    ;;
*)
    echo "Toolchain unknown for host system"
    exit 1
    ;;
esac

rm -rf ${ANDROID_LIB_ROOT}

./Configure dist

for ANDROID_TARGET_PLATFORM in armeabi-v7a arm64-v8a x86 x86_64; do
    echo "Building for libcrypto.a and libssl.a for ${ANDROID_TARGET_PLATFORM}"
    case "${ANDROID_TARGET_PLATFORM}" in
    armeabi-v7a)
        TOOLCHAIN_ARCH=arm
        TOOLCHAIN_PREFIX=arm-linux-androideabi
        CONFIGURE_ARCH=android -march=armv7-a
        PLATFORM_OUTPUT_DIR=armeabi-v7a
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        OPENSSL_BUILD_NAME=android-arm
        ;;
    x86)
        TOOLCHAIN_ARCH=x86
        TOOLCHAIN_PREFIX=i686-linux-android
        CONFIGURE_ARCH=android-x86
        PLATFORM_OUTPUT_DIR=x86
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        OPENSSL_BUILD_NAME=android-x86
        ;;
    x86_64)
        TOOLCHAIN_ARCH=x86_64
        TOOLCHAIN_PREFIX=x86_64-linux-android
        CONFIGURE_ARCH=android64
        PLATFORM_OUTPUT_DIR=x86_64
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        OPENSSL_BUILD_NAME=android-x86_64
        ;;
    arm64-v8a)
        TOOLCHAIN_ARCH=arm64
        TOOLCHAIN_PREFIX=aarch64-linux-android
        CONFIGURE_ARCH=android64-aarch64
        PLATFORM_OUTPUT_DIR=arm64-v8a
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        OPENSSL_BUILD_NAME=android-arm64
        ;;
    *)
        echo "Unsupported build platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
        ;;
    esac

    rm -rf ${ANDROID_TOOLCHAIN_DIR}
    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    export NDK=$ANDROID_NDK_ROOT
    export HOST_TAG="linux-x86_64"
    export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG
    export AR=$TOOLCHAIN/bin/aarch64-linux-android-ar
    export AS=$TOOLCHAIN/bin/aarch64-linux-android-as
    export CC=$TOOLCHAIN/bin/aarch64-linux-android21-clang
    export CXX=$TOOLCHAIN/bin/aarch64-linux-android21-clang++
    export LD=$TOOLCHAIN/bin/aarch64-linux-android-ld
    export RANLIB=$TOOLCHAIN/bin/aarch64-linux-android-ranlib
    export STRIP=$TOOLCHAIN/bin/aarch64-linux-android-strip

    export PATH=$TOOLCHAIN/bin/:$PATH

    #RANLIB=${TOOLCHAIN_PREFIX}-ranlib \
    #      AR=${TOOLCHAIN_PREFIX}-ar \
    #      CC=${TOOLCHAIN_PREFIX}-gcc \
    ./Configure ${OPENSSL_BUILD_NAME} \
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

    mv libcrypto.a ${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}
    mv libssl.a ${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}

    # copy header
    mkdir -p "${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}/include/openssl"
    cp -r "include/openssl" "${ANDROID_LIB_ROOT}/${PLATFORM_OUTPUT_DIR}/include/"
done
