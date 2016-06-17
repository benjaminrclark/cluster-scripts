#!/bin/bash
set -o nounset -o errexit -o pipefail -o errtrace

source ~/.variables

cd $1

export APP_NAME=$(cat Appfile | jq -r .application.name)
export GIT_COMMIT=$(git rev-parse HEAD)
export GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export GIT_REPOSITORY=$(git config --get remote.origin.url)
export GIT_SHORT_COMMIT=$(git rev-parse --short=8 HEAD)

export NOMAD_JOB=$(mktemp -t nomad-job.XXXXXXXXXX --suffix .hcl)
export SSH_CONTROL_SOCKET=$(mktemp -t ssh-bastion.XXXXXXXXXX)
terraform remote config -backend=s3 -backend-config="bucket=${REMOTE_STATE_BUCKET}-${ENVIRONMENT}" -backend-config="key=${1}/terraform.tfstate" -backend-config="region=${AWS_REGION}"
export REGION=$(terraform output region)
export DATACENTERS=$(terraform output datacenters)
export BASTION_HOST=$(terraform output bastion_host)
export BASTION_USER=$(terraform output bastion_user)
export NOMAD_HOST=$(terraform output nomad_host)

erb deploy/nomad.hcl.erb > $NOMAD_JOB
nomad validate $NOMAD_JOB
ssh -M -S $SSH_CONTROL_SOCKET -fnNT -o ExitOnForwardFailure=yes -L 4646:${NOMAD_HOST}:4646 ${BASTION_USER}@${BASTION_HOST}
EVALUATION_ID=$(nomad run -detach ${NOMAD_JOB})
ssh -S $SSH_CONTROL_SOCKET -O exit  ${BASTION_USER}@${BASTION_HOST}
