ARG BUILD_ARCH=aarch64
ARG BUILD_FROM=homeassistant/${BUILD_ARCH}-base-debian:bookworm
FROM ${BUILD_FROM}

ARG NOMAD_VERSION=2.0.6
ARG BUILD_ARCH

RUN if [ "${BUILD_ARCH}" = "aarch64" ]; then NOMAD_ARCH="arm64"; elif [ "${BUILD_ARCH}" = "amd64" ]; then NOMAD_ARCH="amd64"; else NOMAD_ARCH="${BUILD_ARCH}"; fi && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl unzip && \
    curl -fsSL -o /tmp/nomad.zip "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${NOMAD_ARCH}.zip" && \
    unzip /tmp/nomad.zip -d /usr/local/bin && \
    rm -f /tmp/nomad.zip && \
    chmod +x /usr/local/bin/nomad && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
