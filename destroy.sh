#!/bin/bash
set -o nounset -o errexit -o pipefail -o errtrace
source ~/.variables

cd $1

export APP_NAME=$(cat Appfile | jq -r .application.name)

terraform remote config -backend=s3 -backend-config="bucket=${REMOTE_STATE_BUCKET}-${ENVIRONMENT}" -backend-config="key=${1}/terraform.tfstate" -backend-config="region=${AWS_REGION}"
terraform get ./infra
terraform destroy ./infra 
