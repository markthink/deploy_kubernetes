#!/bin/bash
ssh cka-1 "sudo systemctl daemon-reload \
  && sudo systemctl stop kube-scheduler \
  && sudo systemctl stop kube-controller-manager \
  && sudo systemctl stop kube-apiserver \
  && sudo systemctl stop etcd \
  && sudo rm -rf /var/etcd /etc/kubernetes"

for node in cka-1 cka-2 cka-3
do

#删除/var/lib/kubelet/目录，删除前先卸载
for m in $(sudo tac /proc/mounts | sudo awk '{print $2}'|sudo grep /var/lib/kubelet);do
 sudo umount $m||true
done

#删除/var/lib/dockeer 目录，删除前先卸载
for m in $(sudo tac /proc/mounts | sudo awk '{print $2}'|sudo grep /var/lib/docker);do
 sudo umount $m||true
done

ssh $node "sudo systemctl stop kubelet \
  && sudo systemctl stop kube-proxy \
  && sudo docker rm -f $(sudo docker ps -qa) \
  && sudo docker volume rm $(sudo docker volume ls -q) \
  && sudo systemctl stop docker \
  && sudo rm -rf /var/lib/kubelet /var/lib/kube-proxy /etc/kubernetes /var/run/kubernetes \
  && sudo rm -rf /etc/systemd/system/kubelet.service /etc/systemd/system/kube-proxy.service"
done
