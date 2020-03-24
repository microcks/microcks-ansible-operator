# microcks-ansible-operator

Kubernetes Operator for easy setup and management of Microcks installs (using Ansible undercover ;-)

## Usage

Once operator is up and running into your Kubernetes namespace, you just have to create a `MicrocksInstall` Custom Resource Definition (CRD). This CRD simply describe the properties of the Microcks installation you want to have in your cluster. A `MicrocksInstall`CRD is made of 5 different sections that may be used for describing your setup :
* Global part is mandatory and contain attributes like `name` of your install and `version` of Microcks to use,
* `microcks` part is mandatory and contain attributes like the number of `replicas` and the access `url` if you want some customizations, 
* `postman` part is mandatory for the number of `replicas`
* `keycloak` part is optional and allows to specifiy if you want a new install or reuse an existing instance,
* `mongodb` part is optional and allows to specifiy if you want a new install or reuse an existing instance.

### Minimalist CRD

Here's below a minimalistic `MicrocksInstall` CRD that I use on my OpenShift cluster. This let all the defaults applies (see below for details).

```yaml
apiVersion: microcks.github.io/v1alpha1
kind: MicrocksInstall
metadata:
  name: my-microcksinstall
spec:
  name: my-microcksinstall
  version: "0.7.1"
  microcks: 
    replicas: 1
  postman:
    replicas: 2
```

> This form can only be used on OpenShift as vanilla Kubernetes will need more informations to customize `Ingress` resources.

### Complete CRD

Here's now a complete `MicrocksInstall` CRD that I use - for example - on Minikube for testing vanilla Kubernetes support. This one adds the `url` attributes that are mandatory on vanilla Kubernetes.

```yaml
apiVersion: microcks.github.io/v1alpha1
kind: MicrocksInstall
metadata:
  name: my-microcksinstall-minikube
spec:
  name: my-microcksinstall-minikube
  version: "0.7.1"
  microcks: 
    replicas: 1
    url: microcks.192.168.99.100.nip.io
  postman:
    replicas: 2
  keycloak:
    install: true
    persistent: true
    volumeSize: 1Gi
    url: keycloak.192.168.99.100.nip.io
    replicas: 1
  mongodb:
    install: true
    persistent: true
    volumeSize: 2Gi
    replicas: 1
```


### MicrocksInstall details

The table below describe all the fields of the `MicrocksInstall` CRD, provdiing informations on what's mandatory and what's optional as well as default values.

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

Operator Lyfecycle Manager shoud be installed on your cluster firts. Please follow this [guideline](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md) to know how to proceed.

Resources can be found into the `/deploy/olm` directory of this repo. You may want to use the `install.sh` script for creating CSV and subscriptions within your target namespace.

## Local tests

This Operator has been developed and tested using operator-sdk v0.16.0 and ansible 2.9.1

```
$ operator-sdk version
operator-sdk version: "v0.16.0", commit: "55f1446c5f472e7d8e308dcdf36d0d7fc44fc4fd", go version: "go1.14 darwin/amd64"

$ ansible --version
ansible 2.9.1
  config file = None
  configured module search path = ['/Users/lbroudou/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/Cellar/ansible/2.9.1/libexec/lib/python3.7/site-packages/ansible
  executable location = /usr/local/bin/ansible
  python version = 3.7.5 (default, Nov  1 2019, 02:16:32) [Clang 11.0.0 (clang-1100.0.33.8)]
```

Ansible-runner module is requried for local testing. You can install and set it up with following commands:

```
$ /usr/local/Cellar/ansible/2.9.1/libexec/bin/pip install ansible-runner-http openshift 
[...]
$ ln -s /usr/local/Cellar/ansible/2.9.1/libexec/bin/ansible-runner /usr/local/bin/ansible-runner

$ ansible-runner --version
1.4.5
```

Once done, local tests are possible using the following command:

```
$ operator-sdk run --local
INFO[0000] Running the operator locally in namespace microcks. 
{"level":"info","ts":1585060926.0604842,"logger":"cmd","msg":"Go Version: go1.14"}
{"level":"info","ts":1585060926.060529,"logger":"cmd","msg":"Go OS/Arch: darwin/amd64"}
{"level":"info","ts":1585060926.060534,"logger":"cmd","msg":"Version of operator-sdk: v0.16.0"}
{"level":"info","ts":1585060926.063453,"logger":"cmd","msg":"Watching single namespace.","Namespace":"microcks"}
{"level":"info","ts":1585060928.423823,"logger":"controller-runtime.metrics","msg":"metrics server is starting to listen","addr":"0.0.0.0:8383"}
{"level":"info","ts":1585060928.424896,"logger":"watches","msg":"Environment variable not set; using default value","envVar":"WORKER_MICROCKSINSTALL_MICROCKS_GITHUB_IO","default":1}
{"level":"info","ts":1585060928.4249249,"logger":"watches","msg":"Environment variable not set; using default value","envVar":"ANSIBLE_VERBOSITY_MICROCKSINSTALL_MICROCKS_GITHUB_IO","default":2}
{"level":"info","ts":1585060928.42496,"logger":"cmd","msg":"Environment variable not set; using default value","Namespace":"microcks","envVar":"ANSIBLE_DEBUG_LOGS","ANSIBLE_DEBUG_LOGS":false}
{"level":"info","ts":1585060928.424971,"logger":"ansible-controller","msg":"Watching resource","Options.Group":"microcks.github.io","Options.Version":"v1alpha1","Options.Kind":"MicrocksInstall"}
{"level":"info","ts":1585060928.4250722,"logger":"leader","msg":"Trying to become the leader."}
{"level":"info","ts":1585060928.425101,"logger":"leader","msg":"Skipping leader election; not running in a cluster."}
{"level":"info","ts":1585060932.8614569,"logger":"metrics","msg":"Skipping metrics Service creation; not running in a cluster."}
{"level":"info","ts":1585060935.078951,"logger":"proxy","msg":"Starting to serve","Address":"127.0.0.1:8888"}
{"level":"info","ts":1585060935.079112,"logger":"controller-runtime.manager","msg":"starting metrics server","path":"/metrics"}
{"level":"info","ts":1585060935.079189,"logger":"controller-runtime.controller","msg":"Starting EventSource","controller":"microcksinstall-controller","source":"kind source: microcks.github.io/v1alpha1, Kind=MicrocksInstall"}
{"level":"info","ts":1585060935.183991,"logger":"controller-runtime.controller","msg":"Starting Controller","controller":"microcksinstall-controller"}
{"level":"info","ts":1585060935.184026,"logger":"controller-runtime.controller","msg":"Starting workers","controller":"microcksinstall-controller","worker count":1}
{"level":"info","ts":1585060938.4777331,"logger":"proxy","msg":"Skipping cache lookup","resource":{"IsResourceRequest":false,"Path":"/version","Verb":"get","APIPrefix":"","APIGroup":"","APIVersion":"","Namespace":"","Resource":"","Subresource":"","Name":"","Parts":null}}
{"level":"info","ts":1585060938.5031219,"logger":"proxy","msg":"Skipping cache lookup","resource":{"IsResourceRequest":false,"Path":"/version/openshift","Verb":"get","APIPrefix":"","APIGroup":"","APIVersion":"","Namespace":"","Resource":"","Subresource":"","Name":"","Parts":null}}
{"level":"info","ts":1585060938.522412,"logger":"proxy","msg":"Skipping cache lookup","resource":{"IsResourceRequest":false,"Path":"/apis","Verb":"get","APIPrefix":"","APIGroup":"","APIVersion":"","Namespace":"","Resource":"","Subresource":"","Name":"","Parts":null}}
{"level":"info","ts":1585060938.5421581,"logger":"proxy","msg":"Skipping cache lookup","resource":{"IsResourceRequest":false,"Path":"/apis","Verb":"get","APIPrefix":"","APIGroup":"","APIVersion":"","Namespace":"","Resource":"","Subresource":"","Name":"","Parts":null}}
{"level":"info","ts":1585060938.587947,"logger":"logging_event_handler","msg":"[playbook task]","name":"microcks","namespace":"microcks","gvk":"microcks.github.io/v1alpha1, Kind=MicrocksInstall","event_type":"playbook_on_task_start","job":"3916589616287113937","EventData.Name":"microcks : Get an existing MongoDB Secret"}

--------------------------- Ansible Task StdOut -------------------------------

TASK [microcks : Get an existing MongoDB Secret] *******************************
task path: /Users/lbroudou/Development/github/microcks-ansible-operator/roles/microcks/tasks/main.yml:12

-------------------------------------------------------------------------------
[...]
```