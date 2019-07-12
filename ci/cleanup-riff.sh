#!/bin/bash

tiller_service_account=${1:-tiller}
tiller_namespace=${2:-kube-system}

helm delete --purge riff
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=riff

helm delete --purge istio
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=istio
kubectl delete namespace istio-system

helm reset

kubectl delete serviceaccount ${tiller_service_account} -n ${tiller_namespace}
kubectl delete clusterrolebinding "${tiller_service_account}-cluster-admin"
