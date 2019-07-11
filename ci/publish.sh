#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

version=`cat VERSION`
commit=$(git rev-parse HEAD)

make clean
mkdir -p repository
gsutil cp gs://projectriff/charts/releases/index.yaml repository/
gsutil cp gs://projectriff/charts/snapshots/*-${version}-${commit}.tgz repository/
for f in repository/*.tgz; do mv $f $(echo $f | sed s/${version}-${commit}/${version}/); done

helm repo index repository/ --url https://projectriff.storage.googleapis.com/charts/releases --merge repository/index.yaml
gsutil cp -a public-read repository/*.tgz gs://projectriff/charts/releases/
gsutil cp -a public-read repository/index.yaml gs://projectriff/charts/releases/
