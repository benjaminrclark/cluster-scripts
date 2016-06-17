#!/bin/bash
set -o nounset -o errexit -o pipefail -o errtrace

source ~/.variables

cd $1

export APP_NAME=$(cat Appfile | jq -r .application.name)
export SSH_CONTROL_SOCKET=$(mktemp -t ssh-bastion.XXXXXXXXXX)

terraform remote config -backend=s3 -backend-config="bucket=${TF_VAR_remote_state_bucket}-${ENVIRONMENT}" -backend-config="key=${1}/terraform.tfstate" -backend-config="region=${AWS_REGION}"
export BASTION_HOST=$(terraform output bastion_host)
export BASTION_USER=$(terraform output bastion_user)
export NOMAD_HOST=$(terraform output nomad_host)

ssh -M -S $SSH_CONTROL_SOCKET -fnNT -o ExitOnForwardFailure=yes -L 4646:${NOMAD_HOST}:4646 ${BASTION_USER}@${BASTION_HOST}
EVALUATION_ID=$(nomad stop ${APP_NAME}-job)
ssh -S $SSH_CONTROL_SOCKET -O exit  ${BASTION_USER}@${BASTION_HOST}
