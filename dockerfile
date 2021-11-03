FROM ubuntu:focal

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash curl ca-certificates jq curl xargs sed sort awk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data \
    && touch /data/filter.txt

WORKDIR /app

COPY ./filter.sh /app/filter.sh

CMD ["bash", "/app/filter.sh"]
