# microcks-ansible-operator

Kubernetes Operator for easy setup and management of Microcks installs (using Ansible undercover ;-)

## Usage

### MicrocksInstall details

| Section       | Property      | Description   |
| ------------- | ------------- | ------------- |
| `microcks`    | `replicas`    | **Optional**. The number of replicas for the Microcks main pod. Default is `2`. |
| `microcks`    | `url`         | **Mandatory on Kube, Optional on OpenShift**. The URL to use for exposing `Ingress`. If missing on OpenShift, default URL schema handled by Router is used. | 
| `postman`     | `replicas`    | **Optional**. The number of replicas for the Microcks Postman pod. Default is `2`. |
| `keycloak`    | `install`     | **Optional**. Flag for Keycloak installation. Default is `true`. Set to `false` if you want to reuse an existing Keycloak instance. |
| `keycloak`    | `persistent`  | **Optional**. Flag for Keycloak persistence. Default is `true`. Set to `false` if you want an ephemeral Keycloak installation. |
| `keycloak`    | `volumeSize`  | **Optional**. Size of persistent volume claim for Keycloak. Default is `1Gi`. Not used if not persistent install asked. |
| `keycloak`    | `url`         | **Mandatory on Kube if keycloak.install==true, Optional otherwise**. The URL of Keycloak install if it already exists on the one used for exposing Kaycloak `Ingress`. If missing on OpenShift, default URL schema handled by Router is used. | 
| `keycloak`    | `replicas`    | **Optional**. The number of replicas for the Keycloak pod if install is requried. Default is `1`. **Operator do not manage any other value for now** |
| `mongodb`     | `install`     | **Optional**. Flag for MongoDB installation. Default is `true`. Set to `false` if you want to reuse an existing MongoDB instance. |
| `mongodb`     | `persistent`  | **Optional**. Flag for MongoDB persistence. Default is `true`. Set to `false` if you want an ephemeral MongoDB installation. |
| `mongodb`     | `volumeSize`  | **Optional**. Size of persistent volume claim for MongoDB. Default is `2Gi`. Not used if not persistent install asked. |
| `mongodb`     | `replicas`    | **Optional**. The number of replicas for the MongoDB pod if install is requried. Default is `1`. **Operator do not manage any other value for now** |

## Installation

> Kubernetes users: please just replace `oc` commands with `kubectl` counterparts.

### Manual procedure

For development or on bare OpenShift and Kubernetes clusters, without Operator Lifecycle Management (OLM).

Start cloning this repos and then, optionnally, create a new project:

```
$ git clone https://github.com/microcks/microcks-ansible-operator.git
$ cd microcks-ansible-operator/
$ oc new-project microcks-operator
```

Then, from this repository root directory, create the specific CRDS and resources needed for Operator:

```
$ oc create -f deploy/crds/microcks_v1alpha1_microcksinstall_crd.yaml
$ oc create -f deploy/service_account.yaml 
$ oc create -f deploy/role.yaml
$ oc create -f deploy/role_binding.yaml 
```

Finally, deploy the operator:

```
$ oc create -f deploy/operator.yaml
```

Wait a minute or two and check everything is running:

```
$ oc get pods                                                                                                                                 
NAME                                        READY     STATUS    RESTARTS   AGE
microcks-ansible-operator-f58b97548-qj26l   1/1       Running   0          3m
```

Now just create a `MicrocksInstall` CRD!

### Via OLM add-on
