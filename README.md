# Privkey2012

This tool is used to extract private key from CryptoPRO storage format using GOST R 34.10-2012

Storage is a folder with files:
```
header.key
masks.key
masks2.key
name.key
primary.key
primary2.key
```

## Dependencies

1. alpine 3.8
2. openssl 1.1.1a https://github.com/openssl/openssl
3. gost 1.1.0.3 https://github.com/gost-engine/engine

## Building Image

To build image run:

```
docker build -t privkey2012 ./
```

## Using

Change path ~/storage.001 to your storage path
and run:
```
docker run --rm -ti -v ~/storage.001:/usr/local/src/storage.001 privkey2012 storage.001
```

Your key will be output to stdout

