FROM vhanda/flutter-android

ENV MINIMUM_ANDROID_SDK_VERSION 21
ENV MINIMUM_ANDROID_64_BIT_SDK_VERSION 21

COPY . /root/
WORKDIR /root/

CMD /root/build-openssl-android.sh
