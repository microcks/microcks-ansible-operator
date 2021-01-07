# Remove Strimzi from your Kube cluster
kubectl delete clusterrolebinding --selector='app=strimzi'
kubectl delete clusterrole --selector='app=strimzi'
kubectl delete crd --selector='app=strimzi'