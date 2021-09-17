# -*- mode: Dockerfile;-*-
FROM fpco/stack-build:latest as yacp

WORKDIR /workdir
COPY opossum.lib.hs .
RUN set -x \
    && mkdir -p /workdir/out \
    && stack install --local-bin-path /workdir/out

FROM ort/with_opossum:latest

COPY --from=yacp /workdir/out /opt/opossum.lib.hs
RUN set -x \
    && ln -s /opt/opossum.lib.hs/opossum-lib-exe /usr/local/bin/opossum.lib.hs

ARG SCANOSS_VERSION=1.3.4
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl -L "https://github.com/scanoss/scanner.c/releases/download/v${SCANOSS_VERSION}/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb" --output "/tmp/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb" \
    && dpkg -i "/tmp/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb" \
    && rm "/tmp/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb"
COPY convertSCA.sh /usr/local/bin/

RUN mkdir -p /output
WORKDIR /input

COPY aioc.entrypoint.sh /
ENTRYPOINT /aioc.entrypoint.sh
