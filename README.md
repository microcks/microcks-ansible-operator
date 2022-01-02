# microcks-ansible-operator

Kubernetes Operator for easy setup and management of Microcks installs (using Ansible undercover ;-)

[![Join the chat on Zulip](https://img.shields.io/badge/chat-on_zulip-pink.svg?color=ff69b4&style=for-the-badge&logo=zulip)](https://microcksio.zulipchat.com/)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/microcks/microcks-ansible-operator/build-verify-package?logo=github&style=for-the-badge)](https://github.com/microcks/microcks/actions)

## Table of contents

<!--ts-->
   * [Installation](#installation)
      * [Quick start](#quick-start)
      * [Manual procedure](#manual-procedure)
      * [Via OLM add-on](#via-olm-add-on)
   * [Usage](#usage)
      * [Minimalist CRD](#minimalist-crd)
      * [Complete CRD](#complete-crd)
      * [MicrocksInstall details](#microcksinstall-details)
   * [Sample Custom Resources](#sample-custom-resources)
   * [Build](#build)
   * [Tests](#tests)
      * [Local Tests](#local-tests)
      * [E2E Tests](#e2e-tests)
<!--te-->

## Installation
### Quick start

We provide simple shell scripts for quickly installing latest version of Microcks Operator on your OpenShift cluster or local Minikube.

You can use `install-latest-on-minikube.sh` script to prepare your cluster with Strimzi installation, SSL passthrough configuration for accessing Kafka cluster, Microcks Operator and full Microcks install in a `microcks` namespace.

After having logged in your OpenShift cluster with `oc login`, you can use `install-latest-on-openshift.sh` script for installation of Microcks Operator and full Microcks install in a `microcks` namespace of a prepared cluster (Strimzi operator should have been installed first).

### Manual procedure

For development or on bare OpenShift and Kubernetes clusters, without Operator Lifecycle Management (OLM).

Start cloning this repos and then, optionally, create a new project:

```sh
$ git clone https://github.com/microcks/microcks-ansible-operator.git
$ cd microcks-ansible-operator/
$ kubectl create namespace microcks
```

Then, from this repository root directory, create the specific CRDS and resources needed for Operator:

```sh
$ kubectl create -f deploy/crds/microcks_v1alpha1_microcksinstall_crd.yaml
$ kubectl create -f deploy/service_account.yaml -n microcks 
$ kubectl create -f deploy/role.yaml -n microcks
$ kubectl create -f deploy/role_binding.yaml -n microcks
```

Finally, deploy the operator:

```sh
$ kubectl create -f deploy/operator.yaml -n microcks
```

Wait a minute or two and check everything is running:

```sh
$ kubectl get pods -n microcks                                  
NAME                                        READY     STATUS    RESTARTS   AGE
microcks-ansible-operator-f58b97548-qj26l   1/1       Running   0          3m
```

Now just create a `MicrocksInstall` CRD!

### Via OLM add-on

[Operator Lyfecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager) shoud be installed on your cluster first. Please follow this [guideline](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md) to know how to proceed.

You can then use the [OperatorHub.io](https://operatorhub.io) catalog of Kubernetes Operators sourced from multiple providers. It offers you an alternative way to install stable versions of Microcks using the Microcks Operator. To install Microcks from [OperatorHub.io](https://operatorhub.io), locate the *Microcks Operator* and follow the instructions provided.

As an alternative, raw resources can also be found into the `/deploy/olm` directory of this repo. You may want to use the `install.sh` script for creating CSV and subscriptions within your target namespace.

## Usage

Once operator is up and running into your Kubernetes namespace, you just have to create a `MicrocksInstall` Custom Resource Definition (CRD). This CRD simply describe the properties of the Microcks installation you want to have in your cluster. A `MicrocksInstall` CRD is made of 6 different sections that may be used for describing your setup :

* Global part is mandatory and contain attributes like `name` of your install and `version` of Microcks to use,
* `microcks` part is optional and contain attributes like the number of `replicas` and the access `url` if you want some customizations, 
* `postman` part is optional for the number of `replicas`
* `keycloak` part is optional and allows to specify if you want a new install or reuse an existing instance. If not provided, Microcks will install its own Keycloak instance,
* `mongodb` part is optional and allows to specify if you want a new install or reuse an existing instance. If not provided, Microcks will install its own MongoDB instance
* `features` part is optional and allow to enable and configure opt-in features of Microcks.

### Minimalist CRD

Here's below a minimalistic `MicrocksInstall` CRD that you can use on vanilla Kubernetes cluster with just the information needed to configure `Ingresses`. This let all the defaults applies (see below for details).

```yaml
apiVersion: microcks.github.io/v1alpha1
kind: MicrocksInstall
metadata:
  name: my-microcksinstall
spec:
  name: my-microcksinstall
  version: "1.4.1"
  microcks: 
    url: microcks.192.168.99.100.nip.io
  keycloak:
    url: keycloak.192.168.99.100.nip.io
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
  version: "1.4.1"
  microcks: 
    replicas: 1
    url: microcks.192.168.99.100.nip.io
    ingressSecretRef: my-secret-for-microcks-ingress
  postman:
    replicas: 2
  keycloak:
    install: true
    persistent: true
    volumeSize: 1Gi
    url: keycloak.192.168.99.100.nip.io
    privateUrl: http://my-microcksinstall-keycloak.microcks.svc.cluster.local:8080/auth
    ingressSecretRef: my-secret-for-keycloak-ingress
  mongodb:
    install: true
    uri: mongodb:27017
    database: sampledb
    secretRef:
      secret: mongodb
      usernameKey: database-user
      passwordKey: database-password
    persistent: true
    volumeSize: 2Gi
  features:
    repositoryFilter:
      enabled: true
      labelKey: app
      labelLabel: Application
      labelList: app,status
```


### MicrocksInstall details

The table below describe all the fields of the `MicrocksInstall` CRD, providing informations on what's mandatory and what's optional as well as default values.

| Section       | Property           | Description   |
| ------------- | ------------------ | ------------- |
| `microcks`    | `replicas`         | **Optional**. The number of replicas for the Microcks main pod. Default is `1`. |
| `microcks`    | `url`              | **Mandatory on Kube, Optional on OpenShift**. The URL to use for exposing `Ingress`. If missing on OpenShift, default URL schema handled by Router is used. | 
| `microcks`    | `ingressSecretRef` | **Optional on Kube, not used on OpenShift**. The name of a TLS Secret for securing `Ingress`. If missing on Kubernetes, self-signed certificate is generated. | 
| `microcks`    | `ingressAnnotations` | **Optional on Kube, not used on OpenShift for now**. Some custom annotations to add on `Ingress`. If these annotations are triggering a Certificate generation (for example through https://cert-manager.io/). The `generateCert` property should be set to `false`. |
| `microcks`    | `generateCert`     | **Optional on Kube, not used on OpenShift**. Whether to generate self-signed certificate or not if no valid `ingressSecretRef` provided. Default is `true` |
| `microcks`    | `resources`        | **Optional**. Some resources constraints to apply on Microcks pods. This should be expressed using [Kubernetes syntax](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-requests-and-limits-of-pod-and-container). |
| `microcks`    | `logLevel`        | **Optional**. Allows to tune the verbosity level of logs. Default is `INFO` You can use `DEBUG` for more verbosity or `WARN` for less. |
| `postman`     | `replicas`         | **Optional**. The number of replicas for the Microcks Postman pod. Default is `1`. |
| `keycloak`    | `install`          | **Optional**. Flag for Keycloak installation. Default is `true`. Set to `false` if you want to reuse an existing Keycloak instance. |
| `keycloak`    | `image`             | **Optional**. The reference of container image used. Operator comes with its default version. |
| `keycloak`    | `realm`            | **Optional**. Name of Keycloak realm to use. Should be setup only if `install` is `false` and you want to reuse an existing realm. Default is `microcks`. |
| `keycloak`    | `persistent`       | **Optional**. Flag for Keycloak persistence. Default is `true`. Set to `false` if you want an ephemeral Keycloak installation. |
| `keycloak`    | `volumeSize`       | **Optional**. Size of persistent volume claim for Keycloak. Default is `1Gi`. Not used if not persistent install asked. |
| `keycloak`    | `storageClassName` | **Optional**. The cluster storage class to use for persistent volume claim. If not specified, we rely on cluster default storage class. |
| `keycloak`    | `postgresImage`    | **Optional**. The reference of container image used. Operator comes with its default version. |
| `keycloak`    | `url`              | **Mandatory on Kube if keycloak.install==false, Optional otherwise**. The URL of Keycloak install - indeed just the hostname + port part - if it already exists on the one used for exposing Keycloak `Ingress`. If missing on OpenShift, default URL schema handled by Router is used. | 
| `keycloak`    | `privateUrl`       | **Optional**. A private URL - a full URL here - used by the Microcks component to internally join Keycloak. This is also known as `backendUrl` in [Keycloak doc](https://www.keycloak.org/docs/latest/server_installation/#_hostname). When specified, the `keycloak.url` is used as `frontendUrl` in Keycloak terms. | 
| `keycloak`    | `ingressSecretRef` | **Optional on Kube, not used on OpenShift**. The name of a TLS Secret for securing `Ingress`. If missing on Kubernetes, self-signed certificate is generated. | 
| `keycloak`    | `ingressAnnotations` | **Optional on Kube, not used on OpenShift for now**. Some custom annotations to add on `Ingress`. If these annotations are triggering a Certificate generation (for example through https://cert-manager.io/). The `generateCert` property should be set to `false`. |
| `keycloak`    | `generateCert`     | **Optional on Kube, not used on OpenShift**. Whether to generate self-signed certificate or not if no valid `ingressSecretRef` provided. Default is `true` | 
| `keycloak`    | `replicas`         | **Optional**. The number of replicas for the Keycloak pod if install is required. Default is `1`. **Operator do not manage any other value for now** |
| `keycloak`    | `resources`        | **Optional**. Some resources constraints to apply on Keycloak pods. This should be expressed using [Kubernetes syntax](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-requests-and-limits-of-pod-and-container). |
| `mongodb`     | `install`          | **Optional**. Flag for MongoDB installation. Default is `true`. Set to `false` if you want to reuse an existing MongoDB instance. |
| `mongodb`    | `image`             | **Optional**. The reference of container image used. Operator comes with its default version. |
| `mongodb`     | `uri`              | **Optional**. MongoDB URI in case you're reusing existing MongoDB instance. Mandatory if `install` is `false` |
| `mongodb`     | `database`         | **Optional**. MongoDB database name in case you're reusing existing MongoDB instance. Useful if `install` is `false`. Default to `sampledb` |
| `mongodb`     | `secretRef`        | **Optional**. Reference of a Secret containing credentials for connecting a provided MongoDB instance. Mandatory if `install` is `false` |
| `mongodb`     | `persistent`       | **Optional**. Flag for MongoDB persistence. Default is `true`. Set to `false` if you want an ephemeral MongoDB installation. |
| `mongodb`     | `volumeSize`       | **Optional**. Size of persistent volume claim for MongoDB. Default is `2Gi`. Not used if not persistent install asked. |
| `mongodb`     | `storageClassName` | **Optional**. The cluster storage class to use for persistent volume claim. If not specified, we rely on cluster default storage class. |
| `mongodb`     | `replicas`         | **Optional**. The number of replicas for the MongoDB pod if install is required. Default is `1`. **Operator do not manage any other value for now** |
| `mongodb`    | `resources`        | **Optional**. Some resources constraints to apply on MongoDB pods. This should be expressed using [Kubernetes syntax](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-requests-and-limits-of-pod-and-container). |
| `features`    | `repositoryFilter` | **Optional**. Feature allowing to filter API and services on main page. Must be explicitly `enabled`. See [Organizing repository](https://microcks.io/documentation/using/advanced/organizing/#master-level-filter) for more informations |
| `features`    | `repositoryTenancy` | **Optional**. Feature allowing to segment and delegate API and services management according the `repositoryFilter` master criteria. Must be explicitly `enabled`. See [Organizing repository](https://microcks.io/documentation/using/advanced/organizing/#rbac-security-segmentation) for more informations |
| `features`    | `microcksHub`      | **Optional**. Feature allowing to directly import mocks coming from `hub.microcks.io` marketplace. Must be explicitly `enabled`. See [Micorkcs Hub](https://microcks.io/documentation/using/advanced/microcks-hub) for more information. |
| `features`    | `async` | **Optional**. Feature allowing to activate mocking of Async API on a message broker. Must be explicitly `enabled`. See [this sample](https://github.com/microcks/microcks-ansible-operator/blob/master/deploy/crds/openshift-features.yaml#L28) for full informations |

#### Kafka feature details

Here are below the configuration properties of the Kafka support features:
 
| Section    | Property           | Description   |
| ------------- | ------------------ | ------------- |
| `features.async.kafka` | `install`    | **Optional**. Flag for Kafka installation. Default is `true` and required Strimzi Operator to be setup. Set to `false` if you want to reuse an existing Kafka instance. |
| `features.async.kafka` | `useStrimziBeta1`  | **Optional**. Since version `1.3.0` we're using Beta2 version of Strimzi. Default is `false`. Set this flag to `true` if you still using older version of Strimzi that provides Beta1 custom resources. |
| `features.async.kafka` | `url`        | **Optional**. The URL of Kafka broker if it already exists or the one used for exposing Kafka `Ingress` when we install it. In this later case, it should only be the subdomain part (eg: `apps.example.com`). |
| `features.async.kafka` | `persistent` | **Optional**. Flag for Kafka persistence. Default is `false`. Set to `true` if you want a persistent Kafka installation. |
| `features.async.kafka` | `volumeSize` | **Optional**. Size of persistent volume claim for Kafka. Default is `2Gi`. Not used if not persistent install asked. |
| `features.async.kafka.schemaRegistry` | `url` | **Optional**. The API URL of a Kafka Schema Registry. Used for Avro based serialization |
| `features.async.kafka.schemaRegistry` | `confluent` | **Optional**. Flag for indicating that registry is a Confluent one, or using a Confluent compatibility mode. Default to `true` |
| `features.async.kafka.schemaRegistry` | `username`  | **Optional**. Username for connecting to the specified Schema registry. Default to `` |
| `features.async.kafka.schemaRegistry` | `credentialsSource`  | **Optional**. Source of the credentials for connecting to the specified Schema registry. Default to `USER_INFO` |
| `features.async.kafka.authentication` | `type` | **Optional**. The type of authentication for connecting to a pre-existing Kafka broker. Supports `SSL` or `SASL_SSL`. Default to `none` |
| `features.async.kafka.authentication` | `truststoreType` | **Optional**. For TLS transport, you'll probably need a truststore to hold your cluster certificate. Default to `PKCS12` |
| `features.async.kafka.authentication` | `truststoreSecretRef` | **Optional**. For TLS transport, the reference of a Secret holding truststore and its password. Set `secret`, `storeKey` and `passwordKey` properties |
| `features.async.kafka.authentication` | `keystoreType` | **Optional**. In case of `SSL` type, you'll also need a keystore to hold your user private key for mutual TLS authentication. Default to `PKCS12` |
| `features.async.kafka.authentication` | `keystoreSecretRef` | **Optional**. For mutual TLS authentication, the reference of a Secret holding keystore and its password. Set `secret`, `storeKey` and `passwordKey` properties |
| `features.async.kafka.authentication` | `saslMechanism` | **Optional**. For SASL authentication, you'll have to specify an additional authentication mechanism such as `SCRAM-SHA-512` |
| `features.async.kafka.authentication` | `saslJaasConfig` | **Optional**. For SASL authentication, you'll have to specify a JAAS configuration line with login module, username and password. |

#### MQTT feature details

Here are below the configuration properties of the MQTT support features:
 
| Section    | Property           | Description   |
| ------------- | ------------------ | ------------- |
| `features.async.mqtt` | `url`        | **Optional**. The URL of MQTT broker (eg: `my-mqtt-broker.example.com:1883`). Default is undefined which means that feature is disabled. |
| `features.async.mqtt` | `username`   | **Optional**. The username to use for connecting to secured MQTT broker. Default to `microcks`. |
| `features.async.mqtt` | `password`   | **Optional**. The password to use for connecting to secured MQTT broker. Default to `microcks`. |


### WebSocket feature details

Here are below the configuration properties of the WebSocket support feature:
 
| Section       | Property           | Description   |
| ------------- | ------------------ | ------------- |
| `features.async.ws` | `ingressSecretRef`    | **Optional**. The name of a TLS Secret for securing WebSocket `Ingress`. If missing, self-signed certificate is generated. |
| `features.async.ws` | `ingressAnnotations`  | **Optional**. A map of annotations that will be added to the `Ingress` for Microcks WebSocket mocks. If these annotations are triggering a Certificate generation (for example through https://cert-manager.io/). The `generateCert` property should be set to `false`. |
| `features.async.ws` | `generateCert`        | **Optional**. Whether to generate self-signed certificate or not if no valid `ingressSecretRef` provided. Default is `true` |


## Sample Custom Resources

The `/deploy/samples` folder contain sample `MicrocksInstall` resource allowing you to check the configuration for different setup options.

* [openshift-minimal.yml](./deploy/samples/openshift-minimal.yml) illustrates a simple CR for starting a Microcks installation on OpenShift with most common options

* [minikube-minimal.yml](./deploy/samples/minikube-minimal.yml) illustrates a simple CR for starting a Microcks installation on vanilla Kubernetes with most common options

* [openshift-no-mongo.yml](./deploy/samples/openshift-no-mongo.yml) illustrates how to reuse an existing MongoDB database, retrieving the credential for connecting from a pre-existing `Secret`

* [minikube-custom-tls.yml](./deploy/samples/minikube-custom-tls.yml) illustrates how to reuse existing `Secrets` to retrieve TLS certificates that will be used to secure the exposed `Ingresses`

* [minikube-annotations.yml](./deploy/samples/minikube-annotations.yml) illustrates how to specify annotations that will be placed on exposed `Ingresses`. Such annotations can - for example - trigger some certificates generation using Cert Manager

* [openshift-features.yml](./deploy/samples/openshift-features.yml) illustrates how to enable optional features like repository filtering or asynchronous mocking on an OpenShift cluster

* [minikube-features.yml](./deploy/samples/minikube-features.yml) illustrates how to enable optional features like repository filtering or asynchronous mocking on a vanilla Kubernetes cluster

* [openshift-features-mqtt.yml](./deploy/samples/openshift-features-mqtt.yml) illustrates how to connect a MQTT broker to realize asynchronous mocking and testing of MQTT messages

* [openshift-features-ext-sso.yml](./deploy/samples/openshift-features-ext-sso.yml) illustrates how to not deploy Keycloak and reuse an existing instance

* [openshift-features-ext-kafka.yml](./deploy/samples/openshift-features-ext-kafka.yml) illustrates how to not deploy a Kafka broker and reuse an existing instance

* [openshift-features-apicurio-registry.yml](./deploy/samples/openshift-features-apicurio-registry.yml) illustrates how to configure mocking of Apache Kafka using a schema registry

Obviously, you can combine all of them together to enable any options ;-)

## Build

You can build the Operator locally using `docker build` command from root folder like below:

```sh
$ docker build -f build/Dockerfile -t quay.io/microcks/microcks-ansible-operator:latest .
Sending build context to Docker daemon    830kB
Step 1/11 : FROM quay.io/operator-framework/ansible-operator:v0.16.0
 ---> 19ba5006a265
Step 2/11 : USER root
 ---> Using cache
 ---> 02226b2f2469
Step 3/11 : RUN yum clean all && rm -rf /var/cache/yum/* && yum install -y openssl
 ---> Using cache
 ---> 66821ee710bf
Step 4/11 : USER 1001
 ---> Using cache
 ---> e834d11a5146
Step 5/11 : COPY requirements.yml ${HOME}/requirements.yml
 ---> Using cache
 ---> a30f7e13eb23
Step 6/11 : RUN ansible-galaxy collection install -r ${HOME}/requirements.yml     && chmod -R ug+rwx ${HOME}/.ansible
 ---> Using cache
 ---> f2da6036c197
Step 7/11 : COPY k8s/ ${HOME}/k8s/
 ---> 7751789e30be
Step 8/11 : COPY roles/ ${HOME}/roles/
 ---> ae0b2c73e730
Step 9/11 : COPY watches.yaml ${HOME}/watches.yaml
 ---> 062c84d985c6
Step 10/11 : COPY playbook.yml ${HOME}/playbook.yml
 ---> a8c0505e65b7
Step 11/11 : COPY ansible.cfg /etc/ansible/ansible.cfg
 ---> 7de212ab7289
Successfully built 7de212ab7289
Successfully tagged quay.io/microcks/microcks-ansible-operator:latest
```

## Tests
### Local tests

This Operator has been developed and tested using operator-sdk `v0.16.0` and ansible 2.11.6

```sh
$ operator-sdk version
operator-sdk version: "v0.16.0", commit: "55f1446c5f472e7d8e308dcdf36d0d7fc44fc4fd", go version: "go1.14 darwin/amd64"

$ ansible --version
ansible [core 2.11.6] 
  config file = /Users/lbroudou/Development/github/microcks-ansible-operator/ansible.cfg
  configured module search path = ['/Users/lbroudou/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/Cellar/ansible/4.8.0/libexec/lib/python3.10/site-packages/ansible
  ansible collection location = /Users/lbroudou/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/local/bin/ansible
  python version = 3.10.0 (default, Oct 13 2021, 06:45:00) [Clang 13.0.0 (clang-1300.0.29.3)]
  jinja version = 3.0.2
  libyaml = True

$ ansible-playbook --version                                                        ─╯
ansible-playbook [core 2.11.6] 
  config file = /Users/lbroudou/Development/github/microcks-ansible-operator/ansible.cfg
  configured module search path = ['/Users/lbroudou/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/Cellar/ansible/4.8.0/libexec/lib/python3.10/site-packages/ansible
  ansible collection location = /Users/lbroudou/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/local/bin/ansible-playbook
  python version = 3.10.0 (default, Oct 13 2021, 06:45:00) [Clang 13.0.0 (clang-1300.0.29.3)]
  jinja version = 3.0.2
  libyaml = True
```

Ansible-playbook is convenient for testing of Jinja formatting using the `test.yaml` file at the root for this repo. You can quickly check templating results setting the right `vars` and debugging the target `test` var with following command:

```sh
$ ansible-playbook test.yaml -vvv | sed -e 's/\\n/'$'\\\n/g'
```

Ansible-runner module is required for local execution, connected to local or remote Kubernetes cluster. You can install and set it up with following commands:

```sh
$ /usr/local/Cellar/ansible/2.9.1/libexec/bin/pip install ansible-runner-http openshift 
[...]
$ ln -s /usr/local/Cellar/ansible/2.9.1/libexec/bin/ansible-runner /usr/local/bin/ansible-runner

$ ansible-runner --version
1.4.5
```

Once done, local tests are possible using the following command:

```sh
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

### E2E tests

We're using the [Kuttl](https://kuttl.dev) tooling for automated end-to-end tests of this operator. Using a running Minikube instance locally (or other flavour), you can just launch following command to run e2e tests:

```sh
$ kubectl kuttl test --start-kind=false --manifest-dir=./tests/manifests ./tests/e2e
2022/01/01 20:40:19 running without a 'kuttl-test.yaml' configuration
2022/01/01 20:40:19 kutt-test config testdirs is overridden with args: [ ./tests/e2e ]
=== RUN   kuttl
    harness.go:457: starting setup
    harness.go:248: running tests using configured kubeconfig.
    harness.go:285: Successful connection to cluster at: https://192.168.64.11:8443
2022/01/01 20:40:20 Namespace:/microcks created
2022/01/01 20:40:20 CustomResourceDefinition:/microcksinstalls.microcks.github.io updated
2022/01/01 20:40:20 Role:microcks/microcks-ansible-operator created
2022/01/01 20:40:20 ServiceAccount:microcks/microcks-ansible-operator created
2022/01/01 20:40:20 RoleBinding:microcks/microcks-ansible-operator created
2022/01/01 20:40:20 Deployment:microcks/microcks-ansible-operator created
    harness.go:353: running tests
    harness.go:74: going to run test suite with timeout of 30 seconds for each step
    harness.go:365: testsuite: ./tests/e2e has 1 tests
=== RUN   kuttl/harness
=== RUN   kuttl/harness/basic-crd
=== PAUSE kuttl/harness/basic-crd
=== CONT  kuttl/harness/basic-crd
    logger.go:42: 20:40:20 | basic-crd | Creating namespace: kuttl-test-saved-robin
    logger.go:42: 20:40:20 | basic-crd/0-basic-crd | starting test step 0-basic-crd
    logger.go:42: 20:40:20 | basic-crd/0-basic-crd | MicrocksInstall:microcks/microcks created
    logger.go:42: 20:40:25 | basic-crd/0-basic-crd | test step completed 0-basic-crd
    logger.go:42: 20:40:25 | basic-crd/1- | starting test step 1-
    logger.go:42: 20:40:42 | basic-crd/1- | test step completed 1-
    logger.go:42: 20:40:42 | basic-crd/2- | starting test step 2-
    logger.go:42: 20:40:42 | basic-crd/2- | test step completed 2-
    logger.go:42: 20:40:42 | basic-crd/3- | starting test step 3-
    logger.go:42: 20:41:11 | basic-crd/3- | test step completed 3-
    logger.go:42: 20:41:11 | basic-crd/4- | starting test step 4-
    logger.go:42: 20:41:27 | basic-crd/4- | test step completed 4-
Warning: events.k8s.io/v1beta1 Event is deprecated in v1.22+, unavailable in v1.25+
    logger.go:42: 20:41:27 | basic-crd | basic-crd events from ns kuttl-test-saved-robin:
    logger.go:42: 20:41:27 | basic-crd | Deleting namespace: kuttl-test-saved-robin
=== CONT  kuttl
    harness.go:399: run tests finished
    harness.go:508: cleaning up
    harness.go:563: removing temp folder: ""
--- PASS: kuttl (68.14s)
    --- PASS: kuttl/harness (0.00s)
        --- PASS: kuttl/harness/basic-crd (67.76s)
PASS
```