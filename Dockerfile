FROM vhanda/flutter-android

RUN apt-get update && apt-get install -y cmake python pkg-config

ENV MINIMUM_ANDROID_SDK_VERSION 21
ENV MINIMUM_ANDROID_64_BIT_SDK_VERSION 21

COPY . /root/
WORKDIR /root/
