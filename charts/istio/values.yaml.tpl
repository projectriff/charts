# derived from https://github.com/knative/serving/blob/master/third_party/istio-1.3.3/values-lean.yaml
# also see https://istio.io/docs/reference/config/installation-options/

global:
  proxy:
    # Enable proxy to write access log to /dev/stdout.
    accessLogFile: "/dev/stdout"
    accessLogEncoding: 'JSON'
    autoInject: disabled
    image: docker.io/istio/proxyv2:{{ echo $ISTIO_VERSION }}
  proxy_init:
    image: docker.io/istio/proxy_init:{{ echo $ISTIO_VERSION }}
  disablePolicyChecks: true
  omitSidecarInjectorConfigMap: true
  defaultPodDisruptionBudget:
    enabled: false
  useMCP: false
  k8sIngress:
    enabled: true

  # This is noop until this merges https://github.com/istio/istio/pull/18642
  # and is backported to a release riff is using
  kubectl:
    image: docker.io/istio/kubectl:{{ echo $ISTIO_VERSION }}

sidecarInjectorWebhook:
  image: docker.io/istio/sidecar_injector:{{ echo $ISTIO_VERSION }}
  enabled: false
  enableNamespacesByDefault: false

gateways:
  istio-ingressgateway:
    enabled: true
    sds:
      enabled: true
    ports:
    - name: status-port
      port: 15020
    - name: http2
      port: 80
    - port: 443
      name: https
  cluster-local-gateway:
    enabled: true
    labels:
      app: cluster-local-gateway
      istio: cluster-local-gateway
    replicaCount: 1
    cpu:
      targetAverageUtilization: 80
    loadBalancerIP: ""
    loadBalancerSourceRanges: {}
    externalIPs: []
    serviceAnnotations: {}
    podAnnotations: {}
    type: ClusterIP
    ports:
    - name: status-port
      port: 15020
    - name: http2
      port: 80
    - name: https
      port: 443
    secretVolumes:
    - name: cluster-local-gateway-certs
      secretName: istio-cluster-local-gateway-certs
      mountPath: /etc/istio/cluster-local-gateway-certs
    - name: cluster-local-gateway-ca-certs
      secretName: istio-cluster-local-gateway-ca-certs
      mountPath: /etc/istio/cluster-local-gateway-ca-certs

prometheus:
  enabled: false

mixer:
  image: docker.io/istio/mixer:{{ echo $ISTIO_VERSION }}
  enabled: false
  policy:
    enabled: false
  telemetry:
    enabled: false
  adapters:
    prometheus:
      enabled: false

pilot:
  image: docker.io/istio/pilot:{{ echo $ISTIO_VERSION }}
  traceSampling: 100
  sidecar: false
  resources:
    requests:
      cpu: 100m
      memory: 256Mi

galley:
  image: docker.io/istio/galley:{{ echo $ISTIO_VERSION }}
  enabled: false

security:
  image: docker.io/istio/citadel:{{ echo $ISTIO_VERSION }}
  enabled: false

nodeagent:
  image: docker.io/istio/node-agent-k8s:{{ echo $ISTIO_VERSION }}

