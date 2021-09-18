# Privkey2012

[![Build docker and push](https://github.com/iliadmitriev/privkey2012/actions/workflows/docker-build-and-push.yml/badge.svg)](https://github.com/iliadmitriev/privkey2012/actions/workflows/docker-build-and-push.yml)

This tool is used to extract private key from CryptoPRO storage format using GOST R 34.10-2012 format

Storage is a folder with files:
```
header.key
masks.key
masks2.key
name.key
primary.key
primary2.key
```

## Requirements and dependencies

CPU arhictecture:
* x86_64 (amd64)
* arm64 (aarch64)  

OS:
* Linux
* MacOS

Software:
* [Docker version 20.10.7](https://www.docker.com)

Based on:
1. [alpine 3.14](https://alpinelinux.org)
2. [openssl 3.0.0](https://github.com/openssl/openssl)
3. [gost engine](https://github.com/iliadmitriev/engine)

## Building Image

To build image run:

```
docker build -t privkey2012 ./
```

## How to use


Change path `~/storage.001` to your storage path
and run:
```
docker run --rm -ti -v ~/storage.001:/usr/local/src/storage.001 privkey2012 storage.001
```

Your key will be output to stdout

