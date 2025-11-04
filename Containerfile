FROM --platform=linux/amd64 registry.redhat.io/web-terminal/web-terminal-tooling-rhel9:1.14

USER 0

RUN curl -LO https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz && \
    tar -zxvf helm-v3.19.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm-v3.19.0-linux-amd64.tar.gz linux-amd64

USER 1001