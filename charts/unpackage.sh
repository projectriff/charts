#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

chart=$1

chart_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/${chart}"
uncharted_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )/uncharted"

# download config and apply overlays

if [ -f ${chart_dir}/templates.yaml ] ; then
  file=${uncharted_dir}/${chart}.yaml
  rm -f $file

  while IFS= read -r line
  do
    arr=($line)
    name=${arr[0]%?}
    url=${arr[1]}
    args=$(echo $line | cut -d "#" -s -f 2)

    echo "" >> ${file}
    echo "---" >> ${file}
    curl -L -s ${url} >> ${file}

    # apply ytt overlays
    ytt -f overlays/ -f ${file} --file-mark $(basename ${file}):type=yaml-plain ${args} > ${file}.tmp
    mv ${file}.tmp ${file}

    # resolve tags to digests
    k8s-tag-resolver ${file} -o ${file}.tmp
    mv ${file}.tmp ${file}
  done < "${chart_dir}/templates.yaml"
fi
