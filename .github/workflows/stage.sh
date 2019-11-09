#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

helm init --client-only
make clean package

# upload charts
for f in repository/*.tgz; do mv $f $(echo $f | sed s/${version}/${slug}/); done
gsutil cp -a public-read repository/*.tgz gs://projectriff/charts/snapshots/

# upload uncharts
gsutil cp -a public-read uncharted/*.yaml gs://projectriff/charts/uncharted/snapshots/${slug}/
