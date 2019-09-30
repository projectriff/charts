#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

source $FATS_DIR/.configure.sh

if [ $CLUSTER = "minikube" ]; then
  echo "Elimiate pod requests"
  kubectl create namespace cert-manager
  kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.10.0/cert-manager.yaml
  kubectl apply -f https://storage.googleapis.com/projectriff/no-resource-requests-webhook/no-resource-requests-webhook.yaml
fi

if [ ${1:-unknown} = staged ] ; then
  echo "Using staged charts"
  istio_chart=https://storage.googleapis.com/projectriff/charts/snapshots/istio-${slug}.tgz
  riff_build_chart=https://storage.googleapis.com/projectriff/charts/snapshots/riff-build-${slug}.tgz
  riff_core_runtime_chart=https://storage.googleapis.com/projectriff/charts/snapshots/riff-core-runtime-${slug}.tgz
  riff_knative_runtime_chart=https://storage.googleapis.com/projectriff/charts/snapshots/riff-knative-runtime-${slug}.tgz
  riff_streaming_runtime_chart=https://storage.googleapis.com/projectriff/charts/snapshots/riff-streaming-runtime-${slug}.tgz
else
  echo "Using locally built charts"
  istio_chart=./repository/istio-${version}.tgz
  riff_build_chart=./repository/riff-build-${version}.tgz
  riff_core_runtime_chart=./repository/riff-core-runtime-${version}.tgz
  riff_knative_runtime_chart=./repository/riff-knative-runtime-${version}.tgz
  riff_streaming_runtime_chart=./repository/riff-streaming-runtime-${version}.tgz
fi

tiller_service_account=tiller
tiller_namespace=kube-system

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
