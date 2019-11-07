#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source $FATS_DIR/.configure.sh

# setup namespace
kubectl create namespace $NAMESPACE
fats_create_push_credentials $NAMESPACE

for test in java java-boot node npm command; do
  name=fats-cluster-uppercase-${test}
  image=$(fats_image_repo ${name})

  echo "##[group]Run function $name"

  riff function create $name --image $image --namespace $NAMESPACE --tail \
    --git-repo https://github.com/$FATS_REPO --git-revision $FATS_REFSPEC --sub-path functions/uppercase/${test} &

  riff $RUNTIME deployer create $name --function-ref $name --namespace $NAMESPACE --tail
  source $FATS_DIR/macros/invoke_$RUNTIME_deployer.sh $name "-H Content-Type:text/plain -H Accept:text/plain -d cli" CLI
  riff $RUNTIME deployer delete $name --namespace $NAMESPACE

  riff function delete $name --namespace $NAMESPACE
  fats_delete_image $image

  echo "##[endgroup]"
done
