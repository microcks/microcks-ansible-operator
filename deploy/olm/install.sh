#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'you have to use: install.sh <project> '
    exit 1
fi
oc new-project $1
sed -e "s|REPLACE_NAMESPACE|$1|g" cluster_service_version.yaml > cluster_service_version-dev.yaml
oc create -f cluster_service_version-dev.yaml
sed -e "s|REPLACE_NAMESPACE|$1|g" subscription.yaml > subscription-dev.yaml
oc create -f subscription-dev.yaml
# Wondering if lines below are necessary ??
#oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:$1:microcks-ansible-operator
#oc adm policy add-scc-to-user privileged -n $1 -z default