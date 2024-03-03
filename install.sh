#!/bin/bash

if [ -f /etc/debian_version ]; then
    sudo apt-get update
    sudo apt-get install -y wget curl
elif [ -f /etc/redhat-release ]; then
    sudo yum update
    sudo yum install -y wget curl
else
    echo "Unsupported operating system"
    exit 1
fi

sudo mkdir /opt/knks-proxy
sudo wget -O /opt/knks-proxy/proxy https://github.com/kinakocloud/knks-proxy-binary/releases/download/v0.0.1/proxy
sudo chmod 775 /opt/knks-proxy/proxy

sudo cat > /etc/systemd/system/knks-proxy.service <<EOF
[Unit]
Description=knks-proxy

[Service]
Type=simple
WorkingDirectory=/opt/knks-proxy/
ExecStart=/opt/knks-proxy/proxy --apiPort $1 --apiToken $2
Restart=always
RestartSec=5
StartLimitInterval=3
RestartPreventExitStatus=137
 
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable knks-proxy
sudo systemctl start knks-proxy

curl $3/api/reg?token=$2