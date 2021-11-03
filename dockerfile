FROM ubuntu:focal

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash curl ca-certificates jq curl findutils sed coreutils gawk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data \
    && touch /data/filter.txt

# findutils = xargs
# coreutils = sort

WORKDIR /app

COPY ./filter.sh /app/filter.sh

CMD ["bash", "/app/filter.sh"]
