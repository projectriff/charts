#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source $FATS_DIR/.configure.sh

# setup namespace
kubectl create namespace $NAMESPACE
fats_create_push_credentials $NAMESPACE
source ${FATS_DIR}/macros/create-riff-dev-pod.sh

for test in java java-boot node npm command; do
  name=fats-cluster-uppercase-${test}
  image=$(fats_image_repo ${name})
  curl_opts="-H Content-Type:text/plain -H Accept:text/plain -d charts"
  expected_data="CHARTS"

  echo "##[group]Run function $name"

  riff function create $name --image $image --namespace $NAMESPACE --tail \
    --git-repo https://github.com/$FATS_REPO --git-revision $FATS_REFSPEC --sub-path functions/uppercase/${test} &

  riff $RUNTIME deployer create $name \
    --function-ref $name \
    --ingress-policy External \
    --namespace $NAMESPACE \
    --tail
  if [ $RUNTIME = "core" ]; then
    # TODO also test external ingress for core runtime
    source ${FATS_DIR}/macros/invoke_incluster.sh \
      "$(kubectl get deployers.${RUNTIME}.projectriff.io ${name} --namespace ${NAMESPACE} -ojsonpath='{.status.address.url}')" \
      "${curl_opts}" \
      "${expected_data}"
  fi
  if [ $RUNTIME = "knative" ]; then
    # TODO also test clusterlocal ingress for knative runtime
    source ${FATS_DIR}/macros/invoke_${RUNTIME}_deployer.sh \
      $name \
      "${curl_opts}" \
      "${expected_data}"
  fi
  riff $RUNTIME deployer delete $name --namespace $NAMESPACE

  riff function delete $name --namespace $NAMESPACE
  fats_delete_image $image

  echo "##[endgroup]"
done
