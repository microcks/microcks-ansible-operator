FROM quay.io/operator-framework/ansible-operator:v0.16.0

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
    && chmod -R ug+rwx ${HOME}/.ansible

COPY k8s/ ${HOME}/k8s/
COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
COPY playbook.yml ${HOME}/playbook.yml
COPY ansible.cfg /etc/ansible/ansible.cfg
