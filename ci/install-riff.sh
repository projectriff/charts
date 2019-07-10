#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

version=`cat VERSION`
commit=$(git rev-parse HEAD)

source $FATS_DIR/.configure.sh

chart=${1:-https://storage.googleapis.com/projectriff/charts/snapshots/projectriff-riff-${version}-${commit}.tgz}
tiller_service_account=${2:-tiller}
tiller_namespace=${3:-kube-system}

kubectl create serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl create clusterrolebinding "${tiller_service_account}-cluster-admin" --clusterrole cluster-admin --serviceaccount "${tiller_namespace}:${tiller_service_account}"
helm init --wait --service-account ${tiller_service_account}

helm install ${chart} --name riff --devel --set istio.enabled=true --set global.k8s.service.type=${K8S_SERVICE_TYPE}
