kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml


wget https://github.com/projectcalico/calicoctl/releases/download/v3.14.0/calicoctl
chmod +x calicoctl
sudo mv calicoctl /usr/local/bin/

export KUBECONFIG=/root/.kube/config
export DATASTORE_TYPE=kubernetes

calicoctl get nodes
calicoctl node status
calicoctl get ipPool -o wide
calicoctl get workloadEndpoint

ip tunnel show
modprobe -r ipip



