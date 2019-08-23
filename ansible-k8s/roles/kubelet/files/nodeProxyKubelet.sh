#!/bin/bash
KUBE_CONF=/etc/kubernetes
KUBE_SSL=$KUBE_CONF/ssl
MASTER_HOST=$1
IP=$2
HOSTNAME=$3
cat>$KUBE_CONF/kube-proxy.conf<<EOF
KUBE_PROXY_OPTS="--logtostderr=true \\
--v=4 \\
--hostname-override=$HOSTNAME \\
--cluster-cidr=10.10.0.0/16 \\
--kubeconfig=$KUBE_CONF/kube-proxy.kubeconfig"
EOF
cat>/usr/lib/systemd/system/kube-proxy.service<<EOF
[Unit]
Description=Kubernetes Proxy
After=network.target
 
[Service]
EnvironmentFile=-$KUBE_CONF/kube-proxy.conf
ExecStart=/usr/local/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF
cat>$KUBE_CONF/kubelet.yaml<<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: $IP
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS: ["10.0.0.2"]
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true
EOF
cat>$KUBE_CONF/kubelet.conf<<EOF
KUBELET_OPTS="--logtostderr=true \\
--v=4 \\
--hostname-override=$HOSTNAME \\
--kubeconfig=$KUBE_CONF/kubelet.kubeconfig \\
--bootstrap-kubeconfig=$KUBE_CONF/bootstrap.kubeconfig \\
--config=$KUBE_CONF/kubelet.yaml \\
--cert-dir=$KUBE_SSL \\
--client-ca-file=/etc/kubernetes/ssl/ca.pem \\
--cgroups-per-qos=false \\
--enforce-node-allocatable="" \\
--network-plugin=cni \\
--cni-conf-dir=/etc/cni/net.d \\
--cni-bin-dir=/opt/cni/bin \\
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"
EOF
cat>/usr/lib/systemd/system/kubelet.service<<EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service
 
[Service]
EnvironmentFile=$KUBE_CONF/kubelet.conf
ExecStart=/usr/local/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
KillMode=process
 
[Install]
WantedBy=multi-user.target
EOF
