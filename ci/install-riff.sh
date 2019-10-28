#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

source $FATS_DIR/.configure.sh

if [ ${1:-unknown} = staged ] ; then
  echo "Using staged charts"
  certmanager_chart=https://storage.googleapis.com/projectriff/charts/snapshots/cert-manager-${slug}.tgz
  istio_chart=https://storage.googleapis.com/projectriff/charts/snapshots/istio-${slug}.tgz
  riff_chart=https://storage.googleapis.com/projectriff/charts/snapshots/riff-${slug}.tgz
else
  echo "Using locally built charts"
  certmanager_chart=./repository/cert-manager-${version}.tgz
  istio_chart=./repository/istio-${version}.tgz
  riff_chart=./repository/riff-${version}.tgz
fi

source $FATS_DIR/macros/helm-init.sh

echo "Install Cert Manager"
helm install ${certmanager_chart} --name cert-manager --wait

source $FATS_DIR/macros/no-resource-requests.sh

if [ $RUNTIME = "knative" ]; then
  echo "Install Istio"
  helm install ${istio_chart} --name istio --namespace istio-system --wait --set gateways.istio-ingressgateway.type=${K8S_SERVICE_TYPE}

  echo "Checking for ready ingress"
  wait_for_ingress_ready 'istio-ingressgateway' 'istio-system'
fi

echo "Install riff"
helm install ${riff_chart} --name riff --wait \
  --set cert-manager.enabled=false \
  --set riff.runtimes.${RUNTIME}.enabled=true
