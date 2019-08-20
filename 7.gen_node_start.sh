#!/bin/bash
# 此文件需要在 Vagrantfile 文件所在目录执行
# 虚拟机环境定义

HOSTNAME_MASTER=cka-1

BASE_DIR=$(cd "$(dirname "$0")";pwd)
BIN_PATH=$BASE_DIR/deploy_k8s_bin

REMOTE_PEM=tmp_pem
REMOTE_SERVICE=tmp_service

# 分发 Node 节点证书
PEM_DIR=$BASE_DIR/files/$REMOTE_PEM
SYSTEMD_DIR=$BASE_DIR/files/$REMOTE_SERVICE

sudo chmod +x $BIN_PATH/k8s_v1.15.3/hyperkube && sudo cp -rf $BIN_PATH/k8s_v1.15.3/hyperkube /usr/bin \
  && sudo mkdir -p /var/lib/kubelet \
  /var/lib/kube-proxy \
  /etc/kubernetes/config \
  /var/run/kubernetes \
  /etc/containerd

# docker
sudo apt update && sudo apt install socat conntrack resolvconf ipvsadm docker.io -y

sudo mv $PEM_DIR/${HOSTNAME_MASTER}-key.pem /var/lib/kubelet/ \
  && sudo cp -rf $PEM_DIR/${HOSTNAME_MASTER}.pem /var/lib/kubelet/ \
  && sudo cp -rf $PEM_DIR/${HOSTNAME_MASTER}.kubeconfig /var/lib/kubelet/kubeconfig \
  && sudo cp -rf $PEM_DIR/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig \
  && sudo cp -rf $SYSTEMD_DIR/kubelet-config-${HOSTNAME_MASTER}.yaml /var/lib/kubelet/kubelet-config.yaml \
  && sudo cp -rf $SYSTEMD_DIR/kubelet-${HOSTNAME_MASTER}.service /etc/systemd/system/kubelet.service \
  && sudo cp -rf $SYSTEMD_DIR/kube-proxy-config.yaml /var/lib/kube-proxy/ \
  && sudo cp -rf $SYSTEMD_DIR/kube-proxy.service /etc/systemd/system/

# kubelet && kube-proxy
# sudo systemctl daemon-reload \
#   && sudo systemctl stop kube-proxy \
#   && sudo systemctl stop kubelet \
#   && sudo systemctl stop docker

sudo systemctl daemon-reload \
  && sudo systemctl restart docker \
  && sudo systemctl restart kubelet \
  && sudo systemctl restart kube-proxy \
  && sudo systemctl enable docker && sudo systemctl enable kubelet && sudo systemctl enable kube-proxy
