#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

version=`cat VERSION`
commit=$(git rev-parse HEAD)

make clean package

for f in repository/*.tgz; do mv $f $(echo $f | sed s/${version}/${version}-${commit}/); done
gsutil cp -a public-read repository/*.tgz gs://projectriff/charts/snapshots/
