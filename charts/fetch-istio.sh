#!/bin/bash

chart=$1
version=$2

chart_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/${chart}"

mkdir -p ${chart_dir}/${chart}
curl -L -s https://storage.googleapis.com/istio-release/releases/${version}/charts/istio-${version}.tgz | tar xz -C ${chart_dir}/${chart} --strip-components 1

cat ${chart_dir}/${chart}/Chart.yaml | sed -e "s/name: istio/name: ${chart}/g" > ${chart_dir}/${chart}/Chart.yaml.tmp
mv ${chart_dir}/${chart}/Chart.yaml.tmp ${chart_dir}/${chart}/Chart.yaml
