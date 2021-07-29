FROM alpine:3.14

ARG OPENSSL_VERSION=1.1.1k
ARG OPENSSL_SHA256="892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5"
ARG GOST_ENGINE_BRANCH=openssl_1_1_1
ARG GOST_ENGINE_HEAD=9b492b334213ea6dfb76d746e93c4b69a4b36175

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
        git openssh \
	&& apk add --no-cache bash \
# Build and install openssl
  && cd /usr/local/src \
  && wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
  && sha256sum "openssl-${OPENSSL_VERSION}.tar.gz" \
  && echo "$OPENSSL_SHA256" "openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config no-async shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl -Wl,-rpath,/usr/local/ssl/lib \
  && make && make install_sw && make install_ssldirs \
  && cp /usr/local/ssl/bin/openssl /usr/bin/openssl \
  && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz" \
# Build and install GOST engine
  && cd /usr/local/src \
      && git clone https://github.com/gost-engine/engine.git engine \
      && cd engine \
      && git checkout $GOST_ENGINE_HEAD \
	  && sed -i 's|printf("GOST engine already loaded\\n");|goto end;|' gost_eng.c \
	  && mkdir build \
	  && cd build \
	  && cmake -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_C_FLAGS='-I/usr/local/ssl/include -L/usr/local/ssl/lib' \
	          -DOPENSSL_ROOT_DIR=/usr/local/ssl  \
              -DOPENSSL_INCLUDE_DIR=/usr/local/ssl/include \
              -DOPENSSL_LIBRARIES=/usr/local/ssl/lib .. \
              -DOPENSSL_ENGINES_DIR=/usr/local/ssl/lib/engines-1.1 \
	  && cmake --build . --config Release \
	  && cd bin \
	  && cp gostsum gost12sum /usr/local/bin \
	  && cd .. \
	  && cp bin/gost.so /usr/local/ssl/lib/engines-1.1 \
# Build privkey2012 tool
      && cd "/usr/local/src/" \
      && gcc -o privkey2012 -Iengine  -I/usr/local/ssl/include \
          -L/usr/local/src/engine/build \
          -L/usr/local/src/openssl-${OPENSSL_VERSION} \
          -L/usr/local/ssl/lib \
	        engine/gost_ameth.c engine/gost_asn1.c \
	        engine/gost_params.c engine/e_gost_err.c \
            engine/gost_ctl.c \
	        privkey2012.c -lcrypto -lssl -pthread -ldl -static -lgost_core \
 && apk del .build-deps \
 && rm -rf "/usr/local/src/engine" \
 && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}" \
 && rm -rf /tmp/*

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

