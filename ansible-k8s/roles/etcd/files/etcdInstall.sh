#!/bin/bash
# Deploy and configurate etcd service on the master node.
#etcd-v3.3.12-linux-amd64
ETCD_INATLL_FILE=$1
#10.8.4.91
IP=$2
 
NAME=$3
#etcd-01=https://10.8.4.91:2380,etcd-02=https://10.8.4.92:2380,etcd-03=https://10.8.4.93:2380
ENDPOINTS=$4
ETCD_CONF=/etc/etcd/cfg/etcd.conf
ETCD_SSL=/etc/etcd/ssl
ETCD_SERVICE=/usr/lib/systemd/system/etcd.service
tar -xzf $ETCD_INATLL_FILE.tar.gz
cp -p $ETCD_INATLL_FILE/etc* /usr/local/bin/

mkdir -p /var/lib/etcd/default.etcd
echo # The etcd configuration file. 
cat>$ETCD_CONF<<EOF
#[Member]
ETCD_NAME="$NAME"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://$IP:2380"
ETCD_LISTEN_CLIENT_URLS="https://$IP:2379"
 
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://$IP:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://$IP:2379"
ETCD_INITIAL_CLUSTER="$ENDPOINTS"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
 
echo # The etcd servcie configuration file.
cat>$ETCD_SERVICE<<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
 
[Service]
Type=notify
EnvironmentFile=$ETCD_CONF
ExecStart=/usr/local/bin/etcd \\
--name=\${ETCD_NAME} \\
--data-dir=\${ETCD_DATA_DIR} \\
--listen-peer-urls=\${ETCD_LISTEN_PEER_URLS} \\
--listen-client-urls=\${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \\
--advertise-client-urls=\${ETCD_ADVERTISE_CLIENT_URLS} \\
--initial-advertise-peer-urls=\${ETCD_INITIAL_ADVERTISE_PEER_URLS} \\
--initial-cluster=\${ETCD_INITIAL_CLUSTER} \\
--initial-cluster-token=\${ETCD_INITIAL_CLUSTER_TOKEN} \\
--initial-cluster-state=new \\
--cert-file=/etc/etcd/ssl/server.pem \\
--key-file=/etc/etcd/ssl/server-key.pem \\
--peer-cert-file=/etc/etcd/ssl/server.pem \\
--peer-key-file=/etc/etcd/ssl/server-key.pem \\
--trusted-ca-file=/etc/etcd/ssl/ca.pem \\
--peer-trusted-ca-file=/etc/etcd/ssl/ca.pem
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF
