#!/bin/bash

tiller_service_account=${1:-tiller}
tiller_namespace=${2:-kube-system}

uninstall_chart() {
  local name=$1

  helm delete --purge $name
  kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=$name 
}

if [ $RUNTIME = "core" ]; then
  echo "Uninstall riff Core Runtime"
  uninstall_chart riff-core-runtime

elif [ $RUNTIME = "knative" ]; then
  echo "Uninstall riff Knative Runtime"
  uninstall_chart riff-knative-runtime

  uninstall_chart istio
  # extra cleanup for Istio
  kubectl get customresourcedefinitions.apiextensions.k8s.io -oname | grep istio.io | xargs -L1 kubectl delete
  kubectl delete namespace istio-system
fi

echo "Uninstall riff Build"
uninstall_chart riff-build

echo "Uninstall helm"
helm reset

kubectl delete serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl delete clusterrolebinding "${tiller_service_account}-cluster-admin"
