For building openssl -

```
docker build -t ndk-libraries
docker run --rm -it -v `pwd`/openssl-lib:/root/openssl-lib ndk-libraries
```
