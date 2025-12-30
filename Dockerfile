ARG ALPINE_VERSION=3.21
ARG ZAPRET_TAG=v0.7.6
ARG CURL_VERSION=8.13.0

FROM alpine:${ALPINE_VERSION} AS build
ARG ZAPRET_TAG
ARG CURL_VERSION
ARG TARGETPLATFORM

WORKDIR /opt

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") echo "linux-x86_64" > /tmp/zapret_arch && echo "x86_64" > /tmp/curl_arch ;; \
      "linux/arm64") echo "linux-arm64" > /tmp/zapret_arch && echo "aarch64" > /tmp/curl_arch ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac

RUN wget -qO- "https://github.com/bol-van/zapret2/releases/download/${ZAPRET_TAG}/zapret2-${ZAPRET_TAG}.tar.gz" | tar xz && \
    mv zapret2-* zapret2-src

RUN /opt/zapret2-src/install_bin.sh

WORKDIR /opt/zapret2-build

RUN ZAPRET_ARCH=$(cat /tmp/zapret_arch) && \
    mkdir -p ip2net mdig nfq2 && \
    cp /opt/zapret2-src/binaries/${ZAPRET_ARCH}/ip2net ip2net/ip2net && \
    cp /opt/zapret2-src/binaries/${ZAPRET_ARCH}/mdig mdig/mdig && \
    cp /opt/zapret2-src/binaries/${ZAPRET_ARCH}/nfqws2 nfq2/nfqws2 && \
    chmod +x ip2net/ip2net mdig/mdig nfq2/nfqws2

RUN cp -a /opt/zapret2-src/init.d /opt/zapret2-src/common /opt/zapret2-src/ipset . && \
    cp -a /opt/zapret2-src/lua lua && \
    cp -a /opt/zapret2-src/lua lua.dist && \
    cp -a /opt/zapret2-src/init.d/custom.d.examples.linux init.d/custom.d.examples.linux && \
    cp -a /opt/zapret2-src/init.d/custom.d.examples.linux init.d/custom.d.examples.linux.dist

RUN cd init.d && \
    find . -mindepth 1 -maxdepth 1 -type d \
      ! -name "sysv" \
      ! -name "custom.d.examples.*" \
      -exec rm -rf {} +

RUN CURL_ARCH=$(cat /tmp/curl_arch) && \
    wget -qO- "https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/curl-linux-${CURL_ARCH}-glibc-${CURL_VERSION}.tar.xz" | \
    tar -xJf - -C /opt && \
    chmod +x /opt/curl

FROM alpine:${ALPINE_VERSION}

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
      ipset \
      iptables \
      ip6tables \
      netcat-openbsd \
      shadowsocks-libev

EXPOSE 1080 8388

WORKDIR /opt

COPY --from=build /opt/zapret2-build /opt/zapret2
COPY --from=build /opt/curl /usr/bin/curl
COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
