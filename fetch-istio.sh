#!/bin/bash

chart=$1
version=$2

curl -L -s https://storage.googleapis.com/istio-release/releases/${version}/charts/istio-${version}.tgz | tar xz -C charts/${chart} --strip-components 1

cat charts/${chart}/Chart.yaml | sed -e "s/name: istio/name: ${chart}/g" > charts/${chart}/Chart.yaml.tmp
mv charts/${chart}/Chart.yaml.tmp charts/${chart}/Chart.yaml
