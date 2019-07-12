#!/bin/bash

chart=$1
version=$2
destination=$3

# download config and apply overlays

mkdir -p charts/${chart}/templates

if [ -f templates/${chart}.yaml ] ; then
  while IFS= read -r line
  do
    arr=($line)
    name=${arr[0]%?}
    url=${arr[1]}
    args=$(echo $line | cut -d "#" -s -f 2)
    file=charts/${chart}/templates/${name}.yml

    curl -L -s ${url} > ${file}

    # escape existing go template so helm doesn't get confused
    cat ${file} | sed -e 's/{{/{{`{{/g' | sed -e 's/}}/}}`}}/g' > ${file}.tmp
    mv ${file}.tmp ${file}

    # apply ytt overlays
    ytt --ignore-unknown-comments -f overlays/ -f ${file} --file-mark $(basename ${file}):type=yaml-plain ${args} > ${file}.tmp
    mv ${file}.tmp ${file}
  done < "templates/${chart}.yaml"
fi

if [ -f values/${chart}.yaml ] ; then
  if [ -f charts/${chart}/values.yaml ] ; then
    # merge custom values
    yq merge -i -x charts/${chart}/values.yaml values/${chart}.yaml
  else
    cp values/${chart}.yaml charts/${chart}/values.yaml
  fi
fi

helm package ./charts/${chart} --destination ${destination} --version ${version}
