#!/bin/bash

uninstall_app() {
  local name=$1

  kapp delete -n apps -a $name -y
}

source $FATS_DIR/macros/cleanup-user-resources.sh

if [ $RUNTIME = "core" ]; then
  echo "Uninstall riff Core runtime"
  uninstall_app riff-core-runtime
fi

if [ $RUNTIME = "knative" ]; then
  echo "Uninstall riff Knartive runtime"
  uninstall_app riff-knative-runtime
  uninstall_app knative

  echo "Uninstall Istio"
  uninstall_app istio
  # extra cleanup for Istio
  kubectl get customresourcedefinitions.apiextensions.k8s.io -oname | grep istio.io | xargs -L1 kubectl delete
fi

echo "Uninstall riff Build"
uninstall_app riff-build
uninstall_app riff-builders
uninstall_app kpack

echo "Uninstall Cert Manager"
uninstall_app cert-manager
