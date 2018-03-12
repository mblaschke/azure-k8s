#!/bin/bash

set -o pipefail  ## trace ERR through pipes
set -o errtrace  ## trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

export DEBIAN_FRONTEND=noninteractive
K8S_RUNTIME_CONFIG="api/all=true"
VNET_RG="f-we-core-vnet-rg"

# Enable alpha features
#if [[ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]]; then
#    JSONSP='        '
#    sed -i '/\s*- "--runtime-config=.*$/d' /etc/kubernetes/manifests/kube-apiserver.yaml
#    sed -i "/${JSONSP}- \"apiserver\"/c\\${JSONSP}- \"apiserver\"\n${JSONSP}- \"--runtime-config=$K8S_RUNTIME_CONFIG\"" /etc/kubernetes/manifests/kube-apiserver.yaml
#fi

# Set Vnet resource group
if [[ -f /etc/kubernetes/azure.json ]]; then
    JSONSP='    '
    sed -i '/\s*"vnetResourceGroup":.*$/d' /etc/kubernetes/azure.json
    sed -i "/${JSONSP}\"cloud\":\"AzurePublicCloud\",/c\\${JSONSP}\"cloud\":\"AzurePublicCloud\",\n${JSONSP}\"vnetResourceGroup\":\"${VNET_RG}\"," /etc/kubernetes/azure.json
fi

# Kernel config
sed -i '/vm.max_map_count.*$/d' /etc/sysctl.conf
echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
sysctl -p


# Docker self healing
cat << EOF > /etc/systemd/system/docker-healthcheck.service
[Unit]
Description=Docker healthcheck

[Service]
ExecStart=/bin/bash -c "(timeout 5s docker ps > /dev/null) || (systemctl restart docker)"
Restart=always
RestartSec=30
EOF

systemctl daemon-reload
systemctl enable docker-healthcheck
systemctl restart docker-healthcheck
