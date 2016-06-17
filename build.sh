#!/bin/bash
set -o nounset -o errexit -o pipefail -o errtrace

source ~/.variables

cd $1

export APP_NAME=$(cat Appfile | jq -r .application.name)
export GIT_COMMIT=$(git rev-parse HEAD)
export GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export GIT_REPOSITORY=$(git config --get remote.origin.url)
export GIT_SHORT_COMMIT=$(git rev-parse --short=8 HEAD)

export SLUG_PATH=$(mktemp -t packer-slug.XXXXXXXXXX --suffix=.tar.gz)

git archive -o ${SLUG_PATH}  ${GIT_COMMIT} . 

packer build build/packer.json
