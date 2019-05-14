#!/usr/bin/env bash

set -eux

BASE_DIR=$1

if [ ! -d $BASE_DIR/android/app/libs ]; then
    echo "Libs directory does not exist"
    exit 1
fi

cp -r libs/libgit2/* $BASE_DIR/android/app/libs/
cp -r libs/libssh/* $BASE_DIR/android/app/libs/
cp -r libs/libssh2/* $BASE_DIR/android/app/libs/
cp -r libs/openssl-lib/* $BASE_DIR/android/app/libs/
