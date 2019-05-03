#! /usr/bin/env bash

set -eux

LIBGIT2_VERSION="0.28.1"
if [ ! -f "libgit2.tar.gz" ]; then
    curl https://codeload.github.com/libgit2/libgit2/tar.gz/v${LIBGIT2_VERSION} -o libgit2.tar.gz
fi
tar -xvzf libgit2.tar.gz

cd libgit2-${LIBGIT2_VERSION}
LIBGIT2_FULL_PATH=$(pwd)

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

ANDROID_LIB_ROOT=$(pwd)/../libs/libgit2
rm -rf "${ANDROID_LIB_ROOT:?}/*"

for ANDROID_TARGET_PLATFORM in armeabi-v7a arm64-v8a x86 x86_64; do
    echo "Building libgit2 for ${ANDROID_TARGET_PLATFORM}"
    case "${ANDROID_TARGET_PLATFORM}" in
    armeabi-v7a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        ;;
    arm64-v8a)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        ;;
    x86)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_SDK_VERSION}
        ;;
    x86_64)
        ANDROID_API_VERSION=${MINIMUM_ANDROID_64_BIT_SDK_VERSION}
        ;;
    *)
        echo "Unsupported build platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
        ;;
    esac

    mkdir -p "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}"

    export OPENSSL_ROOT_DIR=/root/libs/openssl-lib/${ANDROID_TARGET_PLATFORM}/

    cd "$LIBGIT2_FULL_PATH"
    mkdir "build-${ANDROID_TARGET_PLATFORM}"
    cd "build-${ANDROID_TARGET_PLATFORM}"

    export PKG_CONFIG_PATH=/root/libs/libssh2/${ANDROID_TARGET_PLATFORM}/lib/pkgconfig/:/root/libs/openssl/${ANDROID_TARGET_PLATFORM}/lib/pkgconfig/
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
        -DANDROID_NATIVE_API_LEVEL=$ANDROID_API_VERSION \
        -DCMAKE_INSTALL_PREFIX=${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}

    #        -DCMAKE_PREFIX_PATH=/root/libs/libssh2/${ANDROID_TARGET_PLATFORM}/ \

    if [ $? -ne 0 ]; then
        echo "Error executing cmake"
        exit 1
    fi

    cmake --build .

    if [ $? -ne 0 ]; then
        echo "Error building for platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
    fi

    # Install
    make install
    rm -rf "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}/share"
    rm -rf "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}/misc"
    rm -rf "${ANDROID_LIB_ROOT}/${ANDROID_TARGET_PLATFORM}/bin"
done
