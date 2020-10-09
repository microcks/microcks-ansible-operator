oc new-project microcks
oc create -f deploy/crds/microcks_v1alpha1_microcksinstall_crd.yaml -n microcks 
oc create -f deploy/service_account.yaml -n microcks  
oc create -f deploy/role.yaml -n microcks 
oc create -f deploy/role_binding.yaml -n microcks 
oc create -f deploy/operator_latest.yaml -n microcks
oc create -f deploy/crds/openshift-features.yaml -n microcks 