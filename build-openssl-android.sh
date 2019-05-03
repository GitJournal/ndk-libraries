#! /usr/bin/env bash

set -eux

MINIMUM_ANDROID_SDK_VERSION=21
MINIMUM_ANDROID_64_BIT_SDK_VERSION=21
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

ANDROID_LIB_ROOT=../openssl-lib
OPENSSL_CONFIGURE_OPTIONS="no-pic no-idea no-camellia \
        no-seed no-bf no-cast no-rc2 no-rc4 no-rc5 no-md2 \
        no-md4 no-ecdh no-sock no-ssl3 \
        no-dsa no-dh no-ec no-ecdsa no-tls1 \
        no-rfc3779 no-whirlpool no-srp \
        no-mdc2 no-ecdh no-engine \
        no-srtp -fPIC"

rm -rf "${ANDROID_LIB_ROOT:?}/*"

for ANDROID_TARGET_PLATFORM in armeabi-v7a arm64-v8a x86 x86_64; do
    echo "Building for libcrypto.a and libssl.a for ${ANDROID_TARGET_PLATFORM}"
    case "${ANDROID_TARGET_PLATFORM}" in
    armeabi-v7a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=armeabi-v7a
        OPENSSL_CONFIGURE_ARCH=android-arm
        ;;
    x86)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=x86
        OPENSSL_CONFIGURE_ARCH=android-x86
        ;;
    x86_64)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=x86_64
        OPENSSL_CONFIGURE_ARCH=android-x86_64
        ;;
    arm64-v8a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        PLATFORM_OUTPUT_DIR=arm64-v8a
        OPENSSL_CONFIGURE_ARCH=android-arm64
        ;;
    *)
        echo "Unsupported build platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
        ;;
    esac

    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    export HOST_TAG="linux-x86_64"
    export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
    export AR=$TOOLCHAIN/bin/aarch64-linux-android-ar
    export AS=$TOOLCHAIN/bin/aarch64-linux-android-as
    export CC=$TOOLCHAIN/bin/aarch64-linux-android21-clang
    export CXX=$TOOLCHAIN/bin/aarch64-linux-android21-clang++
    export LD=$TOOLCHAIN/bin/aarch64-linux-android-ld
    export RANLIB=$TOOLCHAIN/bin/aarch64-linux-android-ranlib
    export STRIP=$TOOLCHAIN/bin/aarch64-linux-android-strip
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
