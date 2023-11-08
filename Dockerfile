FROM alpine:3

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
