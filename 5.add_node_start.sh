#!/bin/bash
# 此文件需要在 Vagrantfile 文件所在目录执行
# 虚拟机环境定义

HOSTNAME_WORKER=cka-2

BASE_DIR=$(cd "$(dirname "$0")";pwd)
BIN_PATH=$BASE_DIR/deploy_k8s_bin

REMOTE_NODE=tmp_add_node
SYSTEMD_DIR=$BASE_DIR/files/$REMOTE_NODE

# docker
scp $BIN_PATH/k8s_v1.16.2/hyperkube ${HOSTNAME_WORKER}:~/
ssh $HOSTNAME_WORKER "sudo chmod +x ~/hyperkube && sudo cp -rf  ~/hyperkube /usr/bin \
  && sudo apt update \
  && sudo apt install socat conntrack resolvconf ipvsadm ipset jq sysstat docker.io -y"

scp -r $SYSTEMD_DIR ${HOSTNAME_WORKER}:~/
ssh ${HOSTNAME_WORKER} "sudo mkdir -p /var/lib/kubelet /var/lib/kube-proxy /etc/kubernetes/config /etc/kubernetes/manifest /var/run/kubernetes \
  && sudo cp -rf ~/$REMOTE_NODE/ca.pem /etc/kubernetes/config \
  && sudo cp -rf ~/$REMOTE_NODE/${HOSTNAME_WORKER}-key.pem /var/lib/kubelet/ \
  && sudo cp -rf ~/$REMOTE_NODE/${HOSTNAME_WORKER}.pem /var/lib/kubelet/ \
  && sudo cp -rf ~/$REMOTE_NODE/${HOSTNAME_WORKER}.kubeconfig /var/lib/kubelet/kubeconfig \
  && sudo cp -rf ~/$REMOTE_NODE/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig"

# kubelet+kube-proxy
ssh ${HOSTNAME_WORKER} "sudo cp -rf ~/$REMOTE_NODE/kubelet-config-${HOSTNAME_WORKER}.yaml /var/lib/kubelet/kubelet-config.yaml \
  && sudo cp -rf ~/$REMOTE_NODE/kubelet-${HOSTNAME_WORKER}.service /etc/systemd/system/kubelet.service \
  && sudo cp -rf ~/$REMOTE_NODE/kube-proxy-config.yaml /var/lib/kube-proxy/ \
  && sudo cp -rf ~/$REMOTE_NODE/kube-proxy.service /etc/systemd/system/ \
  && sudo systemctl daemon-reload \
  && sudo systemctl restart docker \
  && sudo systemctl restart kubelet \
  && sudo systemctl restart kube-proxy \
  && sudo systemctl enable docker && sudo systemctl enable kubelet && sudo systemctl enable kube-proxy"
