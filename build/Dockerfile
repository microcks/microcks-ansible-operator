FROM quay.io/operator-framework/ansible-operator:v0.19.4

# Some version information
LABEL maintainer="Laurent Broudoux <laurent@microcks.io>" \
      org.opencontainers.image.authors="Laurent Broudoux <laurent@microcks.io>" \
      org.opencontainers.image.title="Microcks Ansible Operator" \
      org.opencontainers.image.description="Microcks is Open Source cloud-native native tool for API Mocking and Testing" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.documentation="https://github.com/microcks/microcks-ansible-operator" \
      io.artifacthub.package.readme-url="https://raw.githubusercontent.com/microcks/microcks-ansible-operator/master/README.md"

USER root
RUN yum clean all && rm -rf /var/cache/yum/* && yum install -y openssl
USER 1001

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
    && chmod -R ug+rwx ${HOME}/.ansible

COPY k8s/ ${HOME}/k8s/
COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
COPY playbook.yml ${HOME}/playbook.yml
COPY ansible.cfg /etc/ansible/ansible.cfg
