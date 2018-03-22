#!/bin/bash

set -o pipefail  ## trace ERR through pipes
set -o errtrace  ## trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

export DEBIAN_FRONTEND=noninteractive
K8S_RUNTIME_CONFIG="api/all=true"
VNET_RG="f-we-core-vnet-rg"

# Set Vnet resource group
if [[ -f /etc/kubernetes/azure.json ]]; then
    JSONSP='    '
    sed -i '/\s*"vnetResourceGroup":.*$/d' /etc/kubernetes/azure.json
    sed -i "/${JSONSP}\"cloud\":\"AzurePublicCloud\",/c\\${JSONSP}\"cloud\":\"AzurePublicCloud\",\n${JSONSP}\"vnetResourceGroup\":\"${VNET_RG}\"," /etc/kubernetes/azure.json
fi

#############################
# Kernel params
#############################

# Kernel config
# max map count
sed -i '/vm.max_map_count.*$/d' /etc/sysctl.conf
echo "vm.max_map_count = 262144" >> /etc/sysctl.conf

# dmesg restrict
sed -i '/kernel.dmesg_restrict.*$/d' /etc/sysctl.conf
echo "kernel.dmesg_restrict = 1" >> /etc/sysctl.conf

sysctl -p


#############################
# OMS workaround
#############################

wget -O/root/docker-cimprov-1.0.0-31.universal.x86_64.sh https://github.com/Microsoft/Docker-Provider/releases/download/1.0.0-31/docker-cimprov-1.0.0-31.universal.x86_64.sh
sh /root/docker-cimprov-1.0.0-31.universal.x86_64.sh --purge
sh /root/docker-cimprov-1.0.0-31.universal.x86_64.sh --upgrade
rm -f /root/docker-cimprov-1.0.0-31.universal.x86_64.sh

#############################
# Automatic health check
#############################

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
