FROM alpine:3.12

ARG OPENSSL_VERSION=1.1.1i
ARG OPENSSL_SHA256="e8be6a35fe41d10603c3cc635e93289ed00bf34b79671a3a4de64fcee00d5242"
ARG GOST_ENGINE_VERSION=1.1.0.3
ARG GOST_ENGINE_SHA256="a724705b25d2b329ab8307eb63770aea0127087f2a3eeabb93adcc12b21b78fc"

RUN mkdir -p /usr/local/src 

COPY privkey2012.c /usr/local/src/

WORKDIR /usr/local/src/

RUN apk add  --no-cache --virtual .build-deps wget \
        coreutils \
        perl \
        autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c \
		linux-headers \
		cmake unzip \
	&& apk add --no-cache bash \
  && cd /usr/local/src \
  && wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
  && echo "$OPENSSL_SHA256" "openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config no-async shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl -Wl,-rpath,/usr/local/ssl/lib \
  && make && make install \
  && cp /usr/local/ssl/bin/openssl /usr/bin/openssl \
  && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd /usr/local/src \
	  && wget "https://github.com/gost-engine/engine/archive/v${GOST_ENGINE_VERSION}.zip" -O gost-engine.zip \
	  && echo "$GOST_ENGINE_SHA256" gost-engine.zip | sha256sum -c - \
	  && unzip gost-engine.zip -d ./ \
	  && cd "engine-${GOST_ENGINE_VERSION}" \
	  && sed -i 's|printf("GOST engine already loaded\\n");|goto end;|' gost_eng.c \
	  && mkdir build \
	  && cd build \
	  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS='-I/usr/local/ssl/include -L/usr/local/ssl/lib' \
	   -DOPENSSL_ROOT_DIR=/usr/local/ssl  -DOPENSSL_INCLUDE_DIR=/usr/local/ssl/include -DOPENSSL_LIBRARIES=/usr/local/ssl/lib .. \
	  && cmake --build . --config Release \
	  && cd ../bin \
	  && cp gostsum gost12sum /usr/local/bin \
	  && cd .. \
	  && cp bin/gost.so /usr/local/ssl/lib/engines-1.1 \
	  && rm -rf "/usr/local/src/gost-engine.zip" \
  && cd /usr/local/src \
  && gcc -o privkey2012 -Iengine-${GOST_ENGINE_VERSION}  -I/usr/local/ssl/include -L/usr/local/src/engine-${GOST_ENGINE_VERSION}/build \
        -L/usr/local/src/openssl-${OPENSSL_VERSION} -L/usr/local/ssl/lib \
	        engine-${GOST_ENGINE_VERSION}/gost_ameth.c engine-${GOST_ENGINE_VERSION}/gost_asn1.c \
	        engine-${GOST_ENGINE_VERSION}/gost_params.c engine-${GOST_ENGINE_VERSION}/e_gost_err.c \
	        privkey2012.c -lcrypto -lssl -pthread -ldl -static -lgost \
 && apk del .build-deps \
 && rm -rf "/usr/local/src/engine-${GOST_ENGINE_VERSION}" \
 && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}"



# Enable engine
RUN sed -i '6i openssl_conf=openssl_def' /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# OpenSSL default section" >> /usr/local/ssl/openssl.cnf \
  && echo "[openssl_def]" >> /usr/local/ssl/openssl.cnf \
  && echo "engines = engine_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine scetion" >> /usr/local/ssl/openssl.cnf \
  && echo "[engine_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "gost = gost_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine gost section" >> /usr/local/ssl/openssl.cnf \
  && echo "[gost_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "engine_id = gost" >> /usr/local/ssl/openssl.cnf \
  && echo "dynamic_path = /usr/local/ssl/lib/engines-1.1/gost.so" >> /usr/local/ssl/openssl.cnf \
  && echo "default_algorithms = ALL" >> /usr/local/ssl/openssl.cnf \
  && echo "CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet" >> /usr/local/ssl/openssl.cnf


ENTRYPOINT ["/usr/local/src/privkey2012"]
 
