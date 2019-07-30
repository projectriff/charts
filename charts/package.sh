#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

chart=$1
version=$2
destination=$3

chart_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/${chart}"

# download config and apply overlays

mkdir -p ${chart_dir}/${chart}/templates

if [ -f ${chart_dir}/templates.yaml ] ; then
  while IFS= read -r line
  do
    arr=($line)
    name=${arr[0]%?}
    url=${arr[1]}
    args=$(echo $line | cut -d "#" -s -f 2)
    file=${chart_dir}/${chart}/templates/${name}.yml

    curl -L -s ${url} > ${file}

    # escape existing go template so helm doesn't get confused
    cat ${file} | sed -e 's/{{/{{`{{/g' | sed -e 's/}}/}}`}}/g' > ${file}.tmp
    mv ${file}.tmp ${file}

    # apply ytt overlays
    ytt --ignore-unknown-comments -f overlays/ -f ${file} --file-mark $(basename ${file}):type=yaml-plain ${args} > ${file}.tmp
    mv ${file}.tmp ${file}
  done < "${chart_dir}/templates.yaml"
fi

if [ -f ${chart_dir}/values.yaml ] ; then
  if [ -f ${chart_dir}/${chart}/values.yaml ] ; then
    # merge custom values
    yq merge -i -x ${chart_dir}/${chart}/values.yaml ${chart_dir}/values.yaml
  else
    cp ${chart_dir}/values.yaml ${chart_dir}/${chart}/values.yaml
  fi
fi

if [ -f ${chart_dir}/Chart.yaml ] ; then
  cp ${chart_dir}/Chart.yaml ${chart_dir}/${chart}/Chart.yaml
fi

if [ -f ${chart_dir}/requirements.yaml ] ; then
  cp ${chart_dir}/requirements.yaml ${chart_dir}/${chart}/requirements.yaml
fi

if [ -d ${chart_dir}/charts ] ; then
  mkdir ${chart_dir}/${chart}/charts
  cp -LR ${chart_dir}/charts/* ${chart_dir}/${chart}/charts/
fi

helm package ${chart_dir}/${chart} --destination ${destination} --version ${version}
