#!/bin/bash
MF_DOCKER_HUB_USER="${MF_DOCKER_HUB_USER:=quotengrote}"
db_projectname="miniflux-filter"
db_commit_id=$(git rev-parse --short HEAD)



if ! shellcheck ./filter.sh; then
    echo "-----------------------------------"
    echo "warning: fix shellcheck errors"
    exit 1
fi

# pruefe ob kw gesetzt ist
if [[ -z "$MF_DOCKER_HUB_PASS" ]]; then
    # shellcheck disable=SC2016
    echo '"$MF_DOCKER_HUB_PASS"' not set.
    exit 2
fi
# login
docker login --username "$MF_DOCKER_HUB_USER" --password "$MF_DOCKER_HUB_PASS"
# latest
docker build -t "$MF_DOCKER_HUB_USER"/"$db_projectname" .
docker push "$MF_DOCKER_HUB_USER"/"$db_projectname":latest
# commit-id
docker tag "$MF_DOCKER_HUB_USER"/"$db_projectname":latest "$MF_DOCKER_HUB_USER"/"$db_projectname":"$db_commit_id"
docker push "$MF_DOCKER_HUB_USER"/"$db_projectname":"$db_commit_id"
