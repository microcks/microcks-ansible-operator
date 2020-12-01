kubectl create namespace microcks
kubectl create -f deploy/crds/microcks_v1alpha1_microcksinstall_crd.yaml -n microcks 
kubectl create -f deploy/service_account.yaml -n microcks  
kubectl create -f deploy/role.yaml -n microcks 
kubectl create -f deploy/role_binding.yaml -n microcks 
kubectl create -f deploy/operator_latest.yaml -n microcks

# You've got to enable SSL Passthrough on Ingress to ensure access to Kafka broker.
kubectl patch -n kube-system deployment/ingress-nginx-controller --type='json' \
    -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-ssl-passthrough"}]'

# Then install Strimzi
helm repo add strimzi https://strimzi.io/charts/
helm install strimzi strimzi/strimzi-kafka-operator --namespace microcks

export KUBE_APPS_URL=$(minikube ip).nip.io
rm -r deploy/crds/minikube-features-local.yaml
cp deploy/crds/minikube-features.yaml deploy/crds/minikube-features-local.yaml
if [ "$(uname)" == "Darwin" ]; then
    sed -i '' 's=KUBE_APPS_URL='"$KUBE_APPS_URL"'=g' deploy/crds/minikube-features-local.yaml     
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    sed -i 's=KUBE_APPS_URL='"$KUBE_APPS_URL"'=g' deploy/crds/minikube-features-local.yaml
fi
kubectl create -f deploy/crds/minikube-features-local.yaml -n microcks