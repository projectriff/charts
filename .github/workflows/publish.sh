#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

make clean
mkdir -p repository
gsutil cp gs://projectriff/charts/releases/index.yaml repository/
gsutil cp gs://projectriff/charts/snapshots/*-${slug}.tgz repository/
for f in repository/*.tgz; do mv $f $(echo $f | sed s/${slug}/${version}/); done

helm repo index repository/ --url https://projectriff.storage.googleapis.com/charts/releases --merge repository/index.yaml

# publish charts
gsutil -h 'Cache-Control: public, max-age=60' cp -a public-read repository/*.tgz gs://projectriff/charts/releases/
gsutil -h 'Cache-Control: public, max-age=60' cp -a public-read repository/index.yaml gs://projectriff/charts/releases/

# publish uncharts
gsutil -h 'Cache-Control: public, max-age=60' cp -a public-read gs://projectriff/charts/uncharted/snapshots/${slug}/*.yaml gs://projectriff/charts/uncharted/${version}/
