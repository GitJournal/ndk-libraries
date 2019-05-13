#!/usr/bin/env sh

set -u

cd libs
find . -type d -name 'misc' -exec rm -rf {} \;
find . -type d -name 'bin' -exec rm -rf {} \;
find . -type d -name 'certs' -exec rm -rf {} \;
find . -type d -name 'share' -exec rm -rf {} \;
find . -type d -name 'private' -exec rm -rf {} \;
find . -type f -not -regex '.*\.[ah]' -exec rm {} \;
find . -type d -empty -delete
