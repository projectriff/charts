#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

chart=$1
version=$2

build_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )/build/${chart}"
chart_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/${chart}"

# download config and apply overlays

mkdir -p ${build_dir}/templates

if [ -f ${chart_dir}/templates.yaml ] ; then
  while IFS= read -r line
  do
    arr=($line)
    name=${arr[0]%?}
    url=${arr[1]}
    args=$(echo $line | cut -d "#" -s -f 2)
    file=${build_dir}/templates/${name}.yml

    curl -L -s ${url} > ${file}

    # escape existing go template so helm doesn't get confused
    cat ${file} | sed -e 's/{{/{{`{{/g' | sed -e 's/}}/}}`}}/g' > ${file}.tmp
    mv ${file}.tmp ${file}

    # apply ytt overlays
    ytt -f overlays/ -f ${file} --file-mark $(basename ${file}):type=yaml-plain ${args} > ${file}.tmp
    mv ${file}.tmp ${file}

    # resolve tags to digests
    k8s-tag-resolver ${file} -o ${file}.tmp
    mv ${file}.tmp ${file}
  done < "${chart_dir}/templates.yaml"
fi

if [ -f ${chart_dir}/values.yaml.tpl ] ; then
  $( dirname "${BASH_SOURCE[0]}" )/apply-template.sh ${chart_dir}/values.yaml.tpl > ${chart_dir}/values.yaml
fi

if [ -f ${chart_dir}/values.yaml ] ; then
  if [ -f ${build_dir}/values.yaml ] ; then
    # merge custom values
    yq merge -i -x ${build_dir}/values.yaml ${chart_dir}/values.yaml
  else
    cp ${chart_dir}/values.yaml ${build_dir}/values.yaml
  fi
fi

# Resolve any image tags to digests in our values.yaml
if [ -f ${build_dir}/values.yaml ] ; then
    k8s-tag-resolver ${build_dir}/values.yaml -o ${build_dir}/values.yaml.tmp || cp ${build_dir}/values.yaml ${build_dir}/values.yaml.tmp
    mv ${build_dir}/values.yaml.tmp ${build_dir}/values.yaml
fi

if [ -f ${chart_dir}/Chart.yaml ] ; then
  cp ${chart_dir}/Chart.yaml ${build_dir}/Chart.yaml
fi

if [ -f ${chart_dir}/requirements.yaml ] ; then
  cp ${chart_dir}/requirements.yaml ${build_dir}/requirements.yaml
fi

if [ -d ${chart_dir}/charts ] ; then
  mkdir -p ${build_dir}/charts
  cp -LR ${chart_dir}/charts/* ${build_dir}/charts/
fi

if [[ ${chart} == riff* ]] ; then
  helm package ${build_dir} --destination repository --version ${version} --app-version ${version}
else
  helm package ${build_dir} --destination repository --version ${version}
fi
