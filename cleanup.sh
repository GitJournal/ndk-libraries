#!/usr/bin/env sh

set -eux

cd libs
find . -type f -not -regex '.*\.[ah]' -exec rm {} \;
find . -type d -empty -delete
