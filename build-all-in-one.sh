#!/bin/bash
rm -rf install/
mkdir install

cat ./deploy/crds/microcks_v1alpha1_microcksinstall_crd.yaml > install/operator-latest.yaml
echo '---' >> install/operator-latest.yaml
cat ./deploy/service_account.yaml >> install/operator-latest.yaml
echo '---' >> install/operator-latest.yaml
cat ./deploy/role.yaml >> install/operator-latest.yaml
echo '---' >> install/operator-latest.yaml
cat ./deploy/role_binding.yaml >> install/operator-latest.yaml
echo '---' >> install/operator-latest.yaml
cat ./deploy/operator_latest.yaml >> install/operator-latest.yaml

if [ -n "$1" ]; then
    if [ "$(uname)" == "Darwin" ]; then
        sed -i '' 's=microcks-ansible-operator:latest=microcks-ansible-operator:'"$1"'=g' install/operator-latest.yaml
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        sed -i  's=microcks-ansible-operator:latest=microcks-ansible-operator:'"$1"'=g' install/operator-latest.yaml
    fi
    mv install/operator-latest.yaml install/operator-$1.yaml
fi
