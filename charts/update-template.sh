#!/bin/bash

chart=$1

chart_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/${chart}"

if [ -f $chart_dir/templates.yaml.tpl ] ; then
  rm  $chart_dir/templates.yaml
  while IFS= read -r line
  do
    eval "echo \"${line}\" >> $chart_dir/templates.yaml"
  done < "$chart_dir/templates.yaml.tpl"
fi
