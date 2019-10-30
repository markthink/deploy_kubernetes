#!/bin/bash
# 此文件需要在 Vagrantfile 文件所在目录执行
# 虚拟机环境定义
HOSTNAME_MASTER=cka-1
INTERNAL_IP=192.168.0.6

POD_CIDR=10.244.0.0/16

BASE_DIR=$(cd "$(dirname "$0")";pwd)

SYSTEMD_DIR=$BASE_DIR/files/tmp_service
cd $SYSTEMD_DIR

cat > kube-proxy-config.yaml <<EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "ipvs"
clusterCIDR: "${POD_CIDR}"
EOF

cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/hyperkube kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 生成 Master 节点的配置文件
cat > kubelet-config-${HOSTNAME_MASTER}.yaml <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/etc/kubernetes/config/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/resolvconf/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME_MASTER}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME_MASTER}-key.pem"
EOF

cat > kubelet-${HOSTNAME_MASTER}.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/hyperkube kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --authorization-mode=Webhook \\
  --cgroup-driver=cgroupfs \\
  --network-plugin=cni \\
  --register-node=true \\
  --node-ip="${INTERNAL_IP}" \\
  --pod-manifest-path=/etc/kubernetes/manifest \\
  --pod-infra-container-image=quay.io/caicloud/pause:3.1 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
