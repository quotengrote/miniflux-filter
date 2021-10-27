#!/bin/bash
if test ! -e ./docker_hub_pass.txt; then
  echo "./docker_hub_pass.txt nicht gefunden"
  exit 3
fi
cat ./docker_hub_pass.txt | docker login --username quotengrote --password-stdin
if $? -ne 0; then
  echo "Fehler beim anmelden"
  exit 2
fi
docker build -t quotengrote/miniflux-filter .
docker push quotengrote/miniflux-filter:latest
if test ! -z $1; then # wenn $1 nicht leer ist
  docker tag quotengrote/nightscout:latest quotengrote/miniflux-filter:$1
  docker push quotengrote/miniflux-filter:$1
fi


# aufruf: ./docker-build.sh [<0.0.5>]
