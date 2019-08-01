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
riff_chart=${2:-https://storage.googleapis.com/projectriff/charts/snapshots/riff-${slug}.tgz}
tiller_service_account=${3:-tiller}
tiller_namespace=${4:-kube-system}

kubectl create serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl create clusterrolebinding "${tiller_service_account}-cluster-admin" --clusterrole cluster-admin --serviceaccount "${tiller_namespace}:${tiller_service_account}"
helm init --wait --service-account ${tiller_service_account}

helm install ${istio_chart} --name istio --namespace istio-system --devel --wait --set gateways.istio-ingressgateway.type=${K8S_SERVICE_TYPE}
helm install ${riff_chart} --name riff --devel --set knative.enabled=true
