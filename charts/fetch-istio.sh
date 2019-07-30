#!/bin/bash

chart=$1
version=$2

build_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )/build/${chart}"

mkdir -p ${build_dir}
curl -L -s https://storage.googleapis.com/istio-release/releases/${version}/charts/istio-${version}.tgz | tar xz -C ${build_dir} --strip-components 1

cat ${build_dir}/Chart.yaml | sed -e "s/name: istio/name: ${chart}/g" > ${build_dir}/Chart.yaml.tmp
mv ${build_dir}/Chart.yaml.tmp ${build_dir}/Chart.yaml
