#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

version=`cat VERSION`
commit=$(git rev-parse HEAD)

source $FATS_DIR/.configure.sh

istio_chart=${1:-https://storage.googleapis.com/projectriff/charts/snapshots/istio-lean-${version}-${commit}.tgz}
riff_chart=${2:-https://storage.googleapis.com/projectriff/charts/snapshots/riff-${version}-${commit}.tgz}
tiller_service_account=${3:-tiller}
tiller_namespace=${4:-kube-system}

kubectl create serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl create clusterrolebinding "${tiller_service_account}-cluster-admin" --clusterrole cluster-admin --serviceaccount "${tiller_namespace}:${tiller_service_account}"
helm init --wait --service-account ${tiller_service_account}

helm install ${istio_chart} --name istio --namespace istio-system --devel --wait --set gateways.istio-ingressgateway.type=${K8S_SERVICE_TYPE}
helm install ${riff_chart} --name riff --devel
