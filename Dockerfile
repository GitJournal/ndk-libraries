FROM vhanda/flutter-android

RUN apt-get update && apt-get install -y cmake python pkg-config

ENV ANDROID_API_VERSION 21

COPY . /root/
WORKDIR /root/
