FROM alpine:20231219@sha256:9f867dc20de5aa9690c5ef6c2c81ce35a918c0007f6eac27df90d3166eaa5cc0

# hadolint ignore=DL3018
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    jq \
    curl \
    findutils \
    sed \
    coreutils \
    gawk \
    iputils-ping \
    && mkdir /data \
    && touch /data/filter.txt

# findutils = xargs
# coreutils = sort

WORKDIR /app

COPY ./filter.sh /app/filter.sh

CMD ["bash", "/app/filter.sh"]
