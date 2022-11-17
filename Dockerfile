FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV http_proxy=http://acng2.grote.lan:9999

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends bash curl ca-certificates jq curl findutils sed coreutils gawk iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data \
    && touch /data/filter.txt

# findutils = xargs
# coreutils = sort

WORKDIR /app

COPY ./filter.sh /app/filter.sh

CMD ["bash", "/app/filter.sh"]
