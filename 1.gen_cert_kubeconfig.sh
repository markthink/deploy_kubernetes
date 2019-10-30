#!/bin/bash
# 此文件需要在 Vagrantfile 文件所在目录执行
# 执行环境
#   - 要求安装 cfssl/kubectl
# sudo chmod +x deploy_k8s_bin/cfssl/* && sudo cp deploy_k8s_bin/cfssl/* /usr/bin
# sudo chmod +x deploy_k8s_bin/k8s_v1.16.2/* && sudo cp deploy_k8s_bin/k8s_v1.16.2/* /usr/bin
# 配置 kubectl 别名
# echo "alias kubectl='hyperkube kubectl'" >> ~/.bashrc && source  ~/.bashrc
# echo -e \"172.16.90.29 cka-19\n172.16.90.30 cka-20\" >> /etc/hosts

HOSTNAME_MASTER=cka-1
INTERNAL_IP=192.168.0.6
KUBERNETES_PUBLIC_ADDRESS=${INTERNAL_IP}

# K8S 集群服务 IP 从服务 CIDR 预分配
KUBERNETES_SVC_IP="10.32.0.1"

BASE_DIR=$(cd "$(dirname "$0")";pwd)
PEM_DIR=$BASE_DIR/files/tmp_pem
mkdir -p $PEM_DIR

cd $PEM_DIR
# 生成集群证书 - 时效一年(365*24h=8760h)
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Zhejiang"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# 生成管理员证书
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "system:masters",
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
  admin-csr.json | cfssljson -bare admin

# 生成 Master 节点的证书
cat > $HOSTNAME_MASTER-csr.json <<EOF
{
  "CN": "system:node:$HOSTNAME_MASTER",
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
  -hostname=$HOSTNAME_MASTER,${INTERNAL_IP} \
  -profile=kubernetes \
  $HOSTNAME_MASTER-csr.json | cfssljson -bare $HOSTNAME_MASTER


# 生成控制器证书
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "system:kube-controller-manager",
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
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

# 生成网络代理证书
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

# 生成调度器证书
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "system:kube-scheduler",
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
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

# 生成 kubernetes 证书
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "Kubernetes",
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
  -hostname=${KUBERNETES_PUBLIC_ADDRESS},${KUBERNETES_SVC_IP},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes


# 生成 APIServer 证书
cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ZH",
      "L": "Hangzhou",
      "O": "Kubernetes",
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
  service-account-csr.json | cfssljson -bare service-account

# 加密配置文件
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

# kubeconfig 
# 为工作节点生成 kubeconfig 配置文件
# 生成 kube-proxy 配置文件
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

# 生成 Master 节点 kubelet 配置文件
hyperkube kubectl config set-cluster k8smeetup-kubernetes \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=${HOSTNAME_MASTER}.kubeconfig

hyperkube kubectl config set-credentials system:node:${HOSTNAME_MASTER} \
  --client-certificate=${HOSTNAME_MASTER}.pem \
  --client-key=${HOSTNAME_MASTER}-key.pem \
  --embed-certs=true \
  --kubeconfig=${HOSTNAME_MASTER}.kubeconfig

hyperkube kubectl config set-context default \
  --cluster=k8smeetup-kubernetes \
  --user=system:node:${HOSTNAME_MASTER} \
  --kubeconfig=${HOSTNAME_MASTER}.kubeconfig

hyperkube kubectl config use-context default --kubeconfig=${HOSTNAME_MASTER}.kubeconfig


# 为 Master 节点生成 kube-controller-manager 配置文件
hyperkube kubectl config set-cluster k8smeetup-kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

hyperkube kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

hyperkube kubectl config set-context default \
  --cluster=k8smeetup-kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

hyperkube kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

# 为 Master 节点生成 scheduler 配置文件
hyperkube kubectl config set-cluster k8smeetup-kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

hyperkube kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

hyperkube kubectl config set-context default \
  --cluster=k8smeetup-kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

hyperkube kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

# 为 Master 节点生成 admin 配置文件 
hyperkube kubectl config set-cluster k8smeetup-kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

hyperkube kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

hyperkube kubectl config set-context default \
  --cluster=k8smeetup-kubernetes \
  --user=admin \
  --kubeconfig=admin.kubeconfig

hyperkube kubectl config use-context default --kubeconfig=admin.kubeconfig
