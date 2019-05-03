FROM vhanda/flutter-android

RUN apt-get update && apt-get install -y python

ENV MINIMUM_ANDROID_SDK_VERSION 21
COPY . /code/
