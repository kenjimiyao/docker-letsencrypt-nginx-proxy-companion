FROM golang:1.12-alpine AS go-builder

ENV DOCKER_GEN_VERSION=0.7.4

# Install build dependencies for docker-gen
RUN apk add --update \
        curl \
        gcc \
        git \
        make \
        musl-dev

# Build docker-gen
RUN go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
    && git checkout $DOCKER_GEN_VERSION \
    && make get-deps \
    && make all

FROM alpine:3.9

LABEL maintainer="Yves Blusseau <90z7oey02@sneakemail.com> (@blusseau)"

ENV DEBUG=false \
    DOCKER_HOST=unix:///var/run/docker.sock

# Install packages required by the image
RUN apk add --update \
        bash \
        ca-certificates \
        certbot \
        coreutils \
        curl \
        jq \
        openssl \
        python3 \
    && rm /var/cache/apk/*

# Install docker-gen from build stage
COPY --from=go-builder /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/
RUN pip3 install certbot-dns-route53

COPY /app/ /app/

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
