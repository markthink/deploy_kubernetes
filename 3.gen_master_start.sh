#!/bin/bash
# 此文件需要在 Vagrantfile 文件所在目录执行
# 虚拟机环境定义
HOSTNAME_MASTER=cka-1

REMOTE_PEM=tmp_pem
REMOTE_SERVICE=tmp_service

BASE_DIR=$(cd "$(dirname "$0")";pwd)
BIN_PATH=$BASE_DIR/deploy_k8s_bin

PEM_DIR=$BASE_DIR/files/$REMOTE_PEM
SYSTEMD_DIR=$BASE_DIR/files/$REMOTE_SERVICE

sudo mkdir -p /etc/kubernetes/config \
  && sudo cp -rf $PEM_DIR/* /etc/kubernetes/config/

# 分发 Master 证书文件 & 下发服务配置文件 & 下发二进制文件
sudo chmod +x $BIN_PATH/etcd_v3.5/* && sudo cp -rf $BIN_PATH/etcd_v3.5/* /usr/bin \
  && sudo chmod +x $BIN_PATH/k8s_v1.21.4/* && sudo cp -rf $BIN_PATH/k8s_v1.21.4/* /usr/bin \
  && sudo mkdir -p /var/lib/etcd && sudo cp -rf $SYSTEMD_DIR/*.service /etc/systemd/system/ \
  && sudo cp -rf $SYSTEMD_DIR/kube-scheduler.yaml /etc/kubernetes/config/kube-scheduler.yaml

# sudo systemctl daemon-reload \
#   && sudo systemctl stop kube-scheduler \
#   && sudo systemctl stop kube-controller-manager \
#   && sudo systemctl stop kube-apiserver \
#   && sudo systemctl stop etcd

# etcd+Master
sudo systemctl daemon-reload \
  && sudo systemctl restart etcd \
  && sudo systemctl restart kube-apiserver \
  && sudo systemctl restart kube-controller-manager \
  && sudo systemctl restart kube-scheduler \
  && sudo systemctl enable etcd && sudo systemctl enable kube-apiserver \
  && sudo systemctl enable kube-controller-manager && sudo systemctl enable kube-scheduler
