#!/usr/bin/env bash

set -eux

./build-openssl-android.sh
./build-ssh2.sh
./build-git2.sh
