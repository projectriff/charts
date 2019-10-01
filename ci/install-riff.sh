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
  istio_chart=https://storage.googleapis.com/projectriff/charts/snapshots/istio-${slug}.tgz
  riff_chart=https://storage.googleapis.com/projectriff/charts/snapshots/riff-${slug}.tgz
else
  echo "Using locally built charts"
  istio_chart=./repository/istio-${version}.tgz
  riff_chart=./repository/riff-${version}.tgz
fi

tiller_service_account=tiller
tiller_namespace=kube-system

kubectl create serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl create clusterrolebinding "${tiller_service_account}-cluster-admin" --clusterrole cluster-admin --serviceaccount "${tiller_namespace}:${tiller_service_account}"
helm init --wait --service-account ${tiller_service_account}

if [ $(kubectl get nodes -oname | wc -l) = "1" ]; then
  echo "Elimiate pod resource requests"
  kubectl create namespace cert-manager
  kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
  fats_retry kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.10.1/cert-manager.yaml
  wait_pod_selector_ready app.kubernetes.io/name=cert-manager cert-manager
  wait_pod_selector_ready app.kubernetes.io/name=cainjector cert-manager
  wait_pod_selector_ready app.kubernetes.io/name=webhook cert-manager
  fats_retry kubectl apply -f https://storage.googleapis.com/projectriff/no-resource-requests-webhook/no-resource-requests-webhook.yaml
  wait_pod_selector_ready app=webhook no-resource-requests
fi

if [ $RUNTIME = "knative" ]; then
  echo "Install Istio"
  helm install ${istio_chart} --name istio --namespace istio-system --wait --set gateways.istio-ingressgateway.type=${K8S_SERVICE_TYPE}

  echo "Checking for ready ingress"
  wait_for_ingress_ready 'istio-ingressgateway' 'istio-system'
fi

echo "Install riff"
helm install ${riff_chart} --name riff --set riff.runtimes.${RUNTIME}.enabled=true
