#!/bin/bash

uninstall_chart() {
  local name=$1

  helm delete --purge $name
  kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=$name 
}

source $FATS_DIR/macros/cleanup-user-resources.sh

echo "Uninstall Istio"
uninstall_chart istio
# extra cleanup for Istio
kubectl get customresourcedefinitions.apiextensions.k8s.io -oname | grep istio.io | xargs -L1 kubectl delete
kubectl delete namespace istio-system

echo "Uninstall riff"
uninstall_chart riff

echo "Uninstall Cert Manager"
uninstall_chart cert-manager

echo "Uninstall helm"
source $FATS_DIR/macros/helm-reset.sh
