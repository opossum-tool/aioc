# SPDX-FileCopyrightText: TNG Technology Consulting GmbH <https://www.tngtech.com>
#
# SPDX-License-Identifier: Apache-2.0

# -*- mode: Dockerfile;-*-
FROM fpco/stack-build:latest as opossum-lib-hs

WORKDIR /workdir
COPY opossum.lib.hs .
RUN set -x \
    && mkdir -p /workdir/out \
    && stack install --local-bin-path /workdir/out

FROM ort/with_opossum:latest

RUN set -x \
    && ln -s /opt/ort/bin/ort /usr/local/bin/ort \
    && ln -s /opt/ort/bin/orth /usr/local/bin/orth

ARG SCANOSS_VERSION=1.3.4
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        jq uuid-runtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl -L "https://github.com/scanoss/scanner.c/releases/download/v${SCANOSS_VERSION}/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb" --output "/tmp/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb" \
    && dpkg -i "/tmp/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb" \
    && rm "/tmp/scanoss-scanner-${SCANOSS_VERSION}-amd64.deb"

ARG DEPENDENCY_CHECK_VERSION=6.2.2
RUN set -x \
    # install owasp dependency-check
    && cd /opt \
    && curl -ksSL -o /opt/dependency-check.zip https://github.com/jeremylong/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip \
    && unzip /opt/dependency-check.zip \
    && rm /opt/dependency-check.zip \
    && ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check.sh \
    && dependency-check.sh --data /dependency-check-data --updateonly \
    && find /dependency-check-data -type f -exec chmod 666 {} \; \
    && find /dependency-check-data -type d -exec chmod 777 {} \;

COPY --from=opossum-lib-hs /workdir/out /opt/opossum.lib.hs
RUN set -x \
    && ln -s /opt/opossum.lib.hs/opossum-lib-exe /usr/local/bin/opossum.lib.hs

RUN mkdir -p /output
WORKDIR /input

COPY aioc/entrypoint.sh /
ENTRYPOINT /entrypoint.sh
