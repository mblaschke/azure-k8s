#!/bin/bash

set -o pipefail  ## trace ERR through pipes
set -o errtrace  ## trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

export DEBIAN_FRONTEND=noninteractive
K8S_RUNTIME_CONFIG="batch/v2alpha1=true"

# Sys upgrade
apt-get update
apt-get -y dist-upgrade

# Enable alpha features
if [[ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]]; then
    JSONSP='        '
    sed -i '/\s*- "--runtime-config=.*$/d' /etc/kubernetes/manifests/kube-apiserver.yaml
    sed -i "/${JSONSP}- \"apiserver\"/c\\${JSONSP}- \"apiserver\"\n${JSONSP}- \"--runtime-config=$K8S_RUNTIME_CONFIG\"" /etc/kubernetes/manifests/kube-apiserver.yaml
fi

# Cleanup
apt autoremove
apt autoclean

# Kernel config
sed -i '/vm.max_map_count.*$/d' /etc/sysctl.conf
echo "vm.max_map_count = 262144" >> /etc/sysctl.conf