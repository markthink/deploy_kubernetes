
# Kubernetes 二进制方式部署脚本

由于部署的二进制文件比较大，这里只保留部署 bash 脚本和基本的配置文件。

- 1.gen_cert_kubeconfig.sh 生成 master 配置
- 2.gen_master_service.sh 生成 master service 文件
- 3.gen_master_start.sh 启动 master 
- 4.add_node_service.sh 生成节点配置
- 5.add_node_start.sh 启动节点
- 6.gen_node_service.sh 生成 master工作节点配置
- 7.gen_node_start.sh 启动 master 节点

## etcd 测试

```bash
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/config/ca.pem --cert=/etc/kubernetes/config/kubernetes.pem --key=/etc/kubernetes/config/kubernetes-key.pem get / --prefix --keys-only
```

```bash
.
├── 1.gen_cert_kubeconfig.sh
├── 2.gen_master_service.sh
├── 3.gen_master_start.sh
├── 4.add_node_service.sh
├── 5.add_node_start.sh
├── 6.gen_node_service.sh
├── 7.gen_node_start.sh
├── apiserver-kubelet.yaml
├── canal
│   ├── canal.tar.gz
│   ├── canal.yaml
│   ├── pause.tar.gz
│   └── rbac.yaml
├── coredns.yaml
├── deploy_k8s_bin
│   ├── cfssl
│   │   ├── cfssl
│   │   └── cfssljson
│   ├── etcd_v3.3.15
│   │   ├── etcd
│   │   └── etcdctl
│   └── k8s_v1.15.3
│       ├── apiextensions-apiserver
│       ├── hyperkube
│       ├── kubeadm
│       ├── kubectl
│       └── mounter
```

## 停止服务

```bash
sudo systemctl daemon-reload \
  && sudo systemctl stop kube-scheduler \
  && sudo systemctl stop kube-controller-manager \
  && sudo systemctl stop kube-apiserver \
  && sudo systemctl stop etcd

sudo systemctl daemon-reload \
  && sudo systemctl stop kube-proxy \
  && sudo systemctl stop kubelet \
  && sudo systemctl stop docker

rm -rf /etc/kubernetes && rm -rf /var/lib/kubelet && rm -rf /var/lib/kube-proxy

sed -i 's/etcd_v3.3.15/etcd_v3.4.3/g' *.sh
sed -i 's/k8s_v1.15.3/k8s_v1.16.2/g' *.sh


ansible all -m lineinfile -a "dest=/etc/resolv.conf regexp='nameserver 127.0.1.1' line='nameserver 10.8.8.8'"
```
