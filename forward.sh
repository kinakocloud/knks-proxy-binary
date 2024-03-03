#!/bin/bash

service firewalld stop
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^net.ipv4.ip_forward=0/'d /etc/sysctl.conf
sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
if [ $? -ne 0 ]; then
    echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p
fi

if [ -f /etc/debian_version ]; then
    systemctl stop iptables
    systemctl disable iptables

    apt-get update
    apt-get install -y nftables
elif [ -f /etc/redhat-release ]; then
    yum update
    yum install -y nftables
else
    echo "Unsupported operating system"
    exit 1
fi

curl -sSLf https://github.com/arloor/nftables-nat-rust/releases/download/v1.0.0/dnat -o /tmp/nat
install /tmp/nat /usr/local/bin/nat

cat > /lib/systemd/system/nat.service <<EOF
[Unit]
Description=dnat-service
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/nat
EnvironmentFile=/opt/nat/env
ExecStart=/usr/local/bin/nat /etc/nat.conf
LimitNOFILE=100000
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nat

mkdir /opt/nat
touch /opt/nat/env

cat > /etc/nat.conf <<EOF
RANGE,10000,65535,$1
EOF

systemctl restart nat

ip=$(curl -s https://api.ip.sb/ip -A Mozilla)
CF_API_KEY = $3
CF_EMAIL = $4
ZONE_ID = $5

curl -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
     -H "X-Auth-Email: ${CF_EMAIL}" \
     -H "X-Auth-Key: ${CF_API_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'"$2"'","content":"'"$ip"'","ttl":120,"proxied":false}'