# projectriff Helm charts

Helm charts to install Istio and riff.

## Install

### Prerequisites

- a running kubernets cluster (1.11+)
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

1. Install riff

   Append:

   - `--set istio.enabled=true` if Istio is not already installed in your cluster.
   - `--set global.k8s.service.type=NodePort` for clusters that do not support LoadBalancer services, like Minikube.
   - `--devel` for the latest snapshot.

   ```sh
   helm install projectriff/riff --name riff
   ```

1. Enjoy.

## Creating charts

### Prerequisites

- internet access
- helm (2.14+)
- ytt (0.14.0)
- gcloud (for publishing)

### Steps

Package charts locally. Charts will be placed in the `repository` directory.

```sh
make package
```
