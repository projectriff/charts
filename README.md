![](https://github.com/projectriff/charts/workflows/CI/badge.svg)

# projectriff Helm charts (and uncharts)

Helm charts (and uncharts) to install Istio and riff.

## Install (kapp)

### Prerequisites

- a running kubernetes cluster (1.14+)
- [kubectl](https://kubectl.docs.kubernetes.io) (1.14+)
- [kapp](https://get-kapp.io) (0.14+)
- [ytt](https://get-ytt.io) (0.14+)

### Steps

1. Define riff version

   ```sh
   riff_version=0.5.0-snapshot

   kubectl create ns apps
   ```

1. Install riff Build (and dependencies)
   
   ```sh
   kapp deploy -n apps -a cert-manager -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/cert-manager.yaml
   kapp deploy -n apps -a kpack -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/kpack.yaml
   kapp deploy -n apps -a riff-builders -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/riff-builders.yaml
   kapp deploy -n apps -a riff-build -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/riff-build.yaml
   ```

1. Optionally Install Istio (required for the Knative runtime)
   
   If your cluster supports LoadBalancer services (most managed clusters do, but local clusters typically do not):

   ```sh
   kapp deploy -n apps -a istio-init -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/istio-init.yaml
   kapp deploy -n apps -a istio -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/istio.yaml
   ```
   
   If your cluster does not support LoadBalancer services, or if the above command stalls waiting for the ingress service to become ready, then you'll need to convert the ingress service to a NodePort:
   
   ```sh
   ytt -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/istio.yaml -f https://storage.googleapis.com/projectriff/charts/overlays/service-nodeport.yaml --file-mark istio.yaml:type=yaml-plain | kapp deploy -n apps -a istio -f - -y
   ```

1. Optionally Install riff Core Runtime
   
   ```sh
   kapp deploy -n apps -a riff-core-runtime -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/riff-core-runtime.yaml
   ```

1. Optionally Install riff Knative Runtime (and dependencies)
   
   ```sh
   kapp deploy -n apps -a knative -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/knative.yaml
   kapp deploy -n apps -a riff-knative-runtime -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/riff-knative-runtime.yaml
   ```

1. Optionally Install riff Streaming Runtime (and dependencies)
   
   ```sh
   kapp deploy -n apps -a keda -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/keda.yaml
   kapp deploy -n apps -a riff-streaming-runtime -f https://storage.googleapis.com/projectriff/charts/uncharted/${riff_version}/riff-streaming-runtime.yaml
   ```

1. Enjoy.

### Uninstall

```
# remove any riff resources
kubectl delete riff --all-namespaces --all

# remove riff Streaming Runtime (if installed)
kapp delete -n apps -a riff-streaming-runtime
kapp delete -n apps -a keda

# remove riff Knative Runtime (if installed)
kubectl delete knative --all-namespaces --all
kapp delete -n apps -a riff-knative-runtime
kapp delete -n apps -a knative

# remove riff Core Runtime (if installed)
kapp delete -n apps -a riff-core-runtime

# remove Istio (if installed)
kapp delete -n apps -a istio
kapp delete -n apps -a istio-init
kubectl get customresourcedefinitions.apiextensions.k8s.io -oname | grep istio.io | xargs -L1 kubectl delete

# remove riff Build
kapp delete -n apps -a riff-build
kapp delete -n apps -a riff-builders
kapp delete -n apps -a kpack
kapp delete -n apps -a cert-manager
```

## Install (helm)

### Prerequisites

- a running kubernetes cluster (1.14+)
- [kubectl](https://kubectl.docs.kubernetes.io) (1.14+)
- [helm](https://helm.sh) (2.13+)

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

1. Install Istio Init (optional, required for the Knative runtime)

   Append:

   - `--devel` for the latest snapshot.
   
   ```sh
   helm install projectriff/istio-init --name istio --namespace istio-system --wait
   ```

   and then wait for Istio to initialize:

   ```sh
   kubectl -n istio-system wait --for=condition=complete job --all
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

   - `--set tags.core-runtime=true` to enable the Core runtime
   - `--set tags.knative-runtime=true` to enable the Knative runtime
   - `--set tags.streaming-runtime=true` to enable the Streaming runtime
   - `--set cert-manager.enabled=false` if cert-manager is already installed
   - `--set knative.enabled=false` if Knative serving is already installed
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
helm delete --purge istio-init
kubectl delete namespace istio-system
kubectl get customresourcedefinitions.apiextensions.k8s.io -oname | grep istio.io | xargs -L1 kubectl delete
```

## Creating charts

### Prerequisites

- internet access
- [helm](https://helm.sh) (2.13+)
- [kapp](https://get-kapp.io) (0.14+)
- [ytt](https://get-ytt.io) (0.14+)
- [yq](http://mikefarah.github.io/yq/)
- [gcloud](https://cloud.google.com/sdk/gcloud/) (for publishing)

### Steps

Optionally, update the chart templates to the latest component builds.

```sh
make templates
```

Package charts locally. Charts will be placed in the `repository` directory.

```sh
make package
```
