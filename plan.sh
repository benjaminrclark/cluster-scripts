#!/bin/bash
set -o nounset -o errexit -o pipefail -o errtrace
source ~/.variables

cd $1

export APP_NAME=$(cat Appfile | jq -r .application.name)
export GIT_COMMIT=$(git rev-parse HEAD)
export GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export GIT_REPOSITORY=$(git config --get remote.origin.url)
export GIT_SHORT_COMMIT=$(git rev-parse --short=8 HEAD)

terraform remote config -backend=s3 -backend-config="bucket=${REMOTE_STATE_BUCKET}-${ENVIRONMENT}" -backend-config="key=${1}/terraform.tfstate" -backend-config="region=${AWS_REGION}"
terraform get ./infra
terraform plan --out=plan-${GIT_SHORT_COMMIT}.json ./infra  
terraform remote push
