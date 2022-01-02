#!/bin/bash
rm -rf install/all-in-one
mkdir install/all-in-one

cat ./deploy/crds/microcks_v1alpha1_microcksinstall_crd.yaml > install/all-in-one/operator-latest.yaml
echo '---' >> install//all-in-one/operator-latest.yaml
cat ./deploy/service_account.yaml >> install/all-in-one/operator-latest.yaml
echo '---' >> install/all-in-one/operator-latest.yaml
cat ./deploy/role.yaml >> install/all-in-one/operator-latest.yaml
echo '---' >> install/all-in-one/operator-latest.yaml
cat ./deploy/role_binding.yaml >> install/all-in-one/operator-latest.yaml
echo '---' >> install/all-in-one/operator-latest.yaml
cat ./deploy/operator_latest.yaml >> install/all-in-one/operator-latest.yaml

if [ -n "$1" ]; then
    if [ "$(uname)" == "Darwin" ]; then
        sed -i '' 's=microcks-ansible-operator:latest=microcks-ansible-operator:'"$1"'=g' install/all-in-one/operator-latest.yaml
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        sed -i  's=microcks-ansible-operator:latest=microcks-ansible-operator:'"$1"'=g' install/all-in-one/operator-latest.yaml
    fi
    mv install/all-in-one/operator-latest.yaml install/all-in-one/operator-$1.yaml
fi
