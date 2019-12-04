#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

chart=$1

chart_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/${chart}"
uncharted_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )/uncharted"

# download config and apply overlays
file=${uncharted_dir}/${chart}.yaml
rm -f $file

if [ -f ${chart_dir}/templates.yaml ] ; then
  while IFS= read -r line
  do
    arr=($line)
    name=${arr[0]%?}
    url=${arr[1]}
    args=$(echo $line | cut -d "#" -s -f 2)

    echo "" >> ${file}
    echo "---" >> ${file}
    curl -L -s ${url} >> ${file}
  done < "${chart_dir}/templates.yaml"
fi

if [ $chart == "istio" ] || [ $chart == "istio-init" ] ; then
  helm template ./repository/${chart}-*.tgz --namespace istio-system > ${file}
fi
if [ $chart == "kafka" ] ; then
  helm template ./repository/kafka-*.tgz --namespace kafka > ${file}

  cat ${file} | sed -e 's/release-name-//g' | sed -e 's/release-name/riff/g' > ${file}.tmp
  mv ${file}.tmp ${file}
fi

if [ -f ${chart_dir}/uncharted.patch ] ; then
  patch ${file} ${chart_dir}/uncharted.patch
fi

if [ -d ${chart_dir}/overlays-uncharted ] ; then
  ytt -f ${chart_dir}/overlays-uncharted/ -f ${file} --file-mark $(basename ${file}):type=yaml-plain --ignore-unknown-comments > ${file}.tmp
  mv ${file}.tmp ${file}
fi

# resolve tags to digests
k8s-tag-resolver ${file} -o ${file}.tmp
mv ${file}.tmp ${file}
