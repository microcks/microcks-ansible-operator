#!/bin/bash

#
# Licensed to Laurent Broudoux (the "Author") under one or more contributor license agreements.
# See the NOTICE file distributed with this work for additional information regarding copyright
# ownership. Author licenses this file to you under the Apache License, Version 2.0 (the  "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied.
# See the License for the specific language governing permissions and limitations under the License.
#

root_dir=$(pwd)

# Need 2 arguments: first is version we release, second is issue id for release.
if [[ $# -eq 2 ]]; then

  if [ -d "deploy/olm/$1/" ]; then
    # Add OLM resources to git
    git add deploy/olm/$1/
    git commit -m '#"$2" Release operator for "$1"' deploy/olm/$1/
    git push origin master
    chmod u+x build-all-in-one.sh
    ./build-all-in-one.sh $1

    # Get a local copy of microcks.io and move operator here package.
    mkdir $root_dir/tmp && cd $root_dir/tmp
    git clone https://github.com/microcks/microcks.io && cd microcks.io
    mv $root_dir/install/all-in-one/operator-$1.yaml ./static/operator/operator-$1.yaml

    # Add and commit before cleaning up things.
    git add ./static/operator/operator-$1.yaml
    git commit -m 'microcks/microcks-ansible-operator#"$2" chore: Release operator for "$1"' ./static/operator/operator-$1.yaml
    git push origin master

    # Get back to root.
    cd $root_dir
    rm -rf $root_dir/tmp

    git tag $1
    git push origin $1
  else
    echo "Folder deploy/olm/$1/ doesn't exist. Cannot proceed to release."
  fi
else
  echo "release.sh must be called with <version> <release-issue> as 1st argument. Example:"
  echo "$ ./release.sh 1.7.1 99"
fi