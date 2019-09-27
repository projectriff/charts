#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

source $FATS_DIR/.configure.sh

istio_chart=${1:-https://storage.googleapis.com/projectriff/charts/snapshots/istio-${slug}.tgz}
riff_build_chart=${2:-https://storage.googleapis.com/projectriff/charts/snapshots/riff-build-${slug}.tgz}
riff_core_runtime_chart=${2:-https://storage.googleapis.com/projectriff/charts/snapshots/riff-core-runtime-${slug}.tgz}
riff_knative_runtime_chart=${2:-https://storage.googleapis.com/projectriff/charts/snapshots/riff-knative-runtime-${slug}.tgz}
tiller_service_account=${3:-tiller}
tiller_namespace=${4:-kube-system}

kubectl create serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl create clusterrolebinding "${tiller_service_account}-cluster-admin" --clusterrole cluster-admin --serviceaccount "${tiller_namespace}:${tiller_service_account}"
helm init --wait --service-account ${tiller_service_account}

echo "Install riff Build"
helm install ${riff_build_chart} --name riff-build --set riff.builders.enabled=true

if [ $RUNTIME = "core" ]; then
  echo "Install riff Core Runtime"
  helm install ${riff_core_runtime_chart} --name riff-core-runtime
elif [ $RUNTIME = "knative" ]; then
  echo "Install riff Knative Runtime"
  helm install ${istio_chart} --name istio --namespace istio-system --wait --set gateways.istio-ingressgateway.type=${K8S_SERVICE_TYPE}
  helm install ${riff_knative_runtime_chart} --name riff-knative-runtime --set knative.enabled=true

  echo "Checking for ready ingress"
  wait_for_ingress_ready 'istio-ingressgateway' 'istio-system'
fi
