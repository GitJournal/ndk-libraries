#!/usr/bin/env bash

set -eux

start=$(date +%s)

./build-openssl-android.sh
./build-ssh.sh
./build-ssh2.sh
./build-git2.sh
./cleanup.sh

end=$(date +%s)
runtime=$((end - start))

echo "Script took $runtime seconds"
