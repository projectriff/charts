#!/bin/bash

chart=$1

chart_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/${chart}"

if [ -f $chart_dir/templates.yaml.tpl ] ; then
  $( dirname "${BASH_SOURCE[0]}" )/apply-template.sh $chart_dir/templates.yaml.tpl >  $chart_dir/templates.yaml
fi
