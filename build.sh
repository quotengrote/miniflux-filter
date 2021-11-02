#!/bin/bash
MF_DOCKERHUB_USER="${MF_DOCKERHUB_USER:=quotengrote}"
db_projectname="miniflux-filter"
db_commit_id=$(git rev-parse --short HEAD)



if ! shellcheck ./filter.sh; then
    echo "-----------------------------------"
    echo "warning: fix shellcheck errors"
    exit 1
fi

# pruefe ob kw gesetzt ist
if [[ -z "$MF_DOCKERHUB_PASS" ]]; then
    # shellcheck disable=SC2016
    echo '"$MF_DOCKERHUB_PASS"' not set.
    exit 2
fi
# login
docker login --username "$MF_DOCKERHUB_USER" --password "$MF_DOCKERHUB_PASS"
# latest
docker build -t "$MF_DOCKERHUB_USER"/"$db_projectname" .
docker push "$MF_DOCKERHUB_USER"/"$db_projectname":latest
# commit-id
docker tag "$MF_DOCKERHUB_USER"/"$db_projectname":latest "$MF_DOCKERHUB_USER"/"$db_projectname":"$db_commit_id"
docker push "$MF_DOCKERHUB_USER"/"$db_projectname":"$db_commit_id"
