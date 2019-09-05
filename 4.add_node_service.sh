#!/bin/bash
# 此文件需要在 Vagrantfile 文件所在目录执行
# 虚拟机环境定义
HOSTNAME_WORKER=cka-2
INTERNAL_IP=192.168.0.5
KUBERNETES_PUBLIC_ADDRESS=192.168.0.2

POD_CIDR=10.244.0.0/16

BASE_DIR=$(cd "$(dirname "$0")";pwd)

SYSTEMD_DIR=$BASE_DIR/files/tmp_add_node
mkdir -p $SYSTEMD_DIR

# 进入新增节点的配置目录
cd $SYSTEMD_DIR
# 拷贝 ca 证书
cp $SYSTEMD_DIR/../tmp_pem/ca.pem .
cp $SYSTEMD_DIR/../tmp_pem/ca-key.pem .
cp $SYSTEMD_DIR/../tmp_pem/ca-config.json .

# 生成 kube-proxy 证书
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "system:node-proxier",
      "OU": "K8SMeetup Kubernetes",
      "ST": "Zhejiang"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

# 生成 kube-proxy 使用的配置文件
hyperkube kubectl config set-cluster k8smeetup-kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

hyperkube kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

hyperkube kubectl config set-context default \
  --cluster=k8smeetup-kubernetes \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

hyperkube kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

# 生成 kube-proxy 配置文件
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


# 生成 NODE3 节点配置
# 生成节点证书-kubelet
cat > ${HOSTNAME_WORKER}-csr.json <<EOF
{
  "CN": "system:node:${HOSTNAME_WORKER}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "system:nodes",
      "OU": "K8SMeetup Kubernetes",
      "ST": "Zhejiang"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${HOSTNAME_WORKER},${INTERNAL_IP} \
  -profile=kubernetes \
  ${HOSTNAME_WORKER}-csr.json | cfssljson -bare ${HOSTNAME_WORKER}

# 生成 kubelet 使用的配置文件
hyperkube kubectl config set-cluster k8smeetup-kubernetes \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=${HOSTNAME_WORKER}.kubeconfig

hyperkube kubectl config set-credentials system:node:${HOSTNAME_WORKER} \
  --client-certificate=${HOSTNAME_WORKER}.pem \
  --client-key=${HOSTNAME_WORKER}-key.pem \
  --embed-certs=true \
  --kubeconfig=${HOSTNAME_WORKER}.kubeconfig

hyperkube kubectl config set-context default \
  --cluster=k8smeetup-kubernetes \
  --user=system:node:${HOSTNAME_WORKER} \
  --kubeconfig=${HOSTNAME_WORKER}.kubeconfig

hyperkube kubectl config use-context default --kubeconfig=${HOSTNAME_WORKER}.kubeconfig

cat > kubelet-config-${HOSTNAME_WORKER}.yaml <<EOF
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
tlsCertFile: "/var/lib/kubelet/${HOSTNAME_WORKER}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME_WORKER}-key.pem"
EOF

cat > kubelet-${HOSTNAME_WORKER}.service <<EOF
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
  --pod-infra-container-image=cargo.rays.xyz/google_containers/pause:3.1 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# sed -i "s/--node-ip=/--node-ip=${INTERNAL_IP}/g" kubelet-${HOSTNAME_WORKER}.service
