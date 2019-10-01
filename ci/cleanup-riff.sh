#!/bin/bash

tiller_service_account=tiller
tiller_namespace=kube-system

uninstall_chart() {
  local name=$1

  helm delete --purge $name
  kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=$name 
}

if [ $RUNTIME = "knative" ]; then
  echo "Uninstall Istio"
  uninstall_chart istio
  # extra cleanup for Istio
  kubectl get customresourcedefinitions.apiextensions.k8s.io -oname | grep istio.io | xargs -L1 kubectl delete
  kubectl delete namespace istio-system
fi

echo "Uninstall riff"
uninstall_chart riff

echo "Uninstall helm"
helm reset

kubectl delete serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl delete clusterrolebinding "${tiller_service_account}-cluster-admin"
