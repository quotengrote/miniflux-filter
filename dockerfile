FROM ubuntu:focal

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash curl ca-certificates jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data \
    && touch /data/filter.txt

WORKDIR /app

COPY ./filter.sh /app/filter.sh

CMD ["bash", "/app/filter.sh"]
