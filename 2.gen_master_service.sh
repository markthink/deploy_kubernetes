#!/bin/bash
# 此文件需要在 Vagrantfile 文件所在目录执行
# 虚拟机环境定义
HOSTNAME_MASTER=cka-1
INTERNAL_IP=192.168.0.6

POD_CIDR=10.244.0.0/16
SERVICE_CRDR=10.32.0.0/24

BASE_DIR=$(cd "$(dirname "$0")";pwd)

SYSTEMD_DIR=$BASE_DIR/files/tmp_service
mkdir -p $SYSTEMD_DIR

cd $SYSTEMD_DIR
# 部署 etcd
# ETCD 服务配置生成
cat > etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd \\
  --name etcd-one \\
  --cert-file=/etc/kubernetes/config/kubernetes.pem \\
  --key-file=/etc/kubernetes/config/kubernetes-key.pem \\
  --peer-cert-file=/etc/kubernetes/config/kubernetes.pem \\
  --peer-key-file=/etc/kubernetes/config/kubernetes-key.pem \\
  --trusted-ca-file=/etc/kubernetes/config/ca.pem \\
  --peer-trusted-ca-file=/etc/kubernetes/config/ca.pem \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# API Server 服务配置生成
cat > kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/hyperkube kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/etc/kubernetes/config/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/etc/kubernetes/config/ca.pem \\
  --etcd-certfile=/etc/kubernetes/config/kubernetes.pem \\
  --etcd-keyfile=/etc/kubernetes/config/kubernetes-key.pem \\
  --etcd-servers=https://${INTERNAL_IP}:2379 \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/etc/kubernetes/config/encryption-config.yaml \\
  --kubelet-certificate-authority=/etc/kubernetes/config/ca.pem \\
  --kubelet-client-certificate=/etc/kubernetes/config/kubernetes.pem \\
  --kubelet-client-key=/etc/kubernetes/config/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/etc/kubernetes/config/service-account.pem \\
  --service-cluster-ip-range=${SERVICE_CRDR} \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/etc/kubernetes/config/kubernetes.pem \\
  --tls-private-key-file=/etc/kubernetes/config/kubernetes-key.pem \\
  --requestheader-client-ca-file=/etc/kubernetes/config/ca.pem \\
  --requestheader-allowed-names=aggregator,kubernetes \\
  --requestheader-extra-headers-prefix=X-Remote-Extra- \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --enable-aggregator-routing=true \\
  --proxy-client-cert-file=/etc/kubernetes/config/kubernetes.pem \\
  --proxy-client-key-file=/etc/kubernetes/config/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 控制器服务配置生成
cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/hyperkube kube-controller-manager \\
  --address=0.0.0.0 \\
  --leader-elect=true \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=${POD_CIDR} \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/etc/kubernetes/config/ca.pem \\
  --cluster-signing-key-file=/etc/kubernetes/config/ca-key.pem \\
  --kubeconfig=/etc/kubernetes/config/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/etc/kubernetes/config/ca.pem \\
  --service-account-private-key-file=/etc/kubernetes/config/service-account-key.pem \\
  --service-cluster-ip-range=${SERVICE_CRDR} \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 调度器配置文件生成
# https://github.com/kelseyhightower/kubernetes-the-hard-way/issues/427
cat > kube-scheduler.yaml <<EOF
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/etc/kubernetes/config/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

# 调度器服务配置生成
cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/hyperkube kube-scheduler \\
  --leader-elect=true \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

