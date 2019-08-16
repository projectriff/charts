# projectriff Helm charts

Helm charts to install Istio and riff.

## Install

### Prerequisites

- a running Kubernetes cluster (1.11+)
- kubectl (1.11+)
- helm (2.14+)

### Steps

1. Initialize Helm

   ```sh
   kubectl create serviceaccount tiller -n kube-system
   kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount kube-system:tiller
   helm init --wait --service-account tiller
   ```

1. Load the projectriff charts

   ```sh
   helm repo add projectriff https://projectriff.storage.googleapis.com/charts/releases
   helm repo update
   ```

1. Install Istio (optional, required for the Knative runtime)

   Append:

   - `--set gateways.istio-ingressgateway.type=NodePort` for clusters that do not support LoadBalancer services, like Minikube.
   - `--devel` for the latest snapshot.
   
   ```sh
   helm install projectriff/istio --name istio --namespace istio-system --wait
   ```

   For more configuration options see the [Istio documentation](https://archive.istio.io/v1.1/docs/reference/config/installation-options/).

1. Install riff

   Append:

   - `--set knative.enabled=true` to enable the Knative runtime
   - `--devel` for the latest snapshot.

   ```sh
   helm install projectriff/riff --name riff
   ```

1. Enjoy.

### Uninstall

```
# remove any riff resources
kubectl delete riff --all-namespaces --all

# remove any Knative resources (if Knative runtime is enabled)
kubectl delete knative --all-namespaces --all

# remove riff
helm delete --purge riff
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=riff

# remove istio (if installed)
helm delete --purge istio
kubectl delete namespace istio-system
kubectl get customresourcedefinitions.apiextensions.k8s.io -oname | grep istio.io | xargs -L1 kubectl delete
```

## Creating charts

### Prerequisites

- internet access
- helm (2.14+)
- ytt (0.14.0)
- yq
- gcloud (for publishing)

### Steps

Optionally, update the chart templates to the latest component builds.

```sh
make templates
```

Package charts locally. Charts will be placed in the `repository` directory.

```sh
make package
```
