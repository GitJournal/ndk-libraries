For building openssl -

```
docker build -t ndk-libraries .
docker run --rm -it -v `pwd`/libs/:/root/libs ndk-libraries /root/build-openssl-android.sh
docker run --rm -it -v `pwd`/libs/:/root/libs ndk-libraries /root/build-ssh2.sh
```
