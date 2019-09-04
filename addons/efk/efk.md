
# Kubernetes 部署 EFK

> 参考:https://www.elastic.co/cn/elasticsearch-kubernetes


## Step1. 准备工作

```bash
kubectl create clusterrolebinding \
  cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=kubernetes
```
下载部署文件
```bash
wget https://download.elastic.co/downloads/eck/0.8.0/all-in-one.yaml
```

## Step2. Deploy Elasticsearch

```bash
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1alpha1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.1.0
  nodes:
  - nodeCount: 1
    config:
      node.master: true
      node.data: true
      node.ingest: true
EOF
# kubectl expose pod/quickstart-es-5lvcbjwrdg --name elasticsearch --type=NodePort --port=9200

kubectl get secret quickstart-ca --namespace=default --export -o yaml | kubectl apply --namespace=kube-system -f -
```


## Step3. 部署 Kibana

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1alpha1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 7.1.0
  nodeCount: 1
  elasticsearchRef:
    name: quickstart
EOF
```

## Step4. 操作 Kibana

获取密码

```bash
PASSWORD=$(kubectl get secret quickstart-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode)
echo $PASSWORD

kubectl port-forward service/quickstart-kibana 5601
```

## Step5. 部署 Filebeat



# 使用 HELM 部署

```bash
# Add the Elastic Helm Chart Repo: 
helm repo add elastic https://helm.elastic.co
# Install Elasticsearch: 
helm install --name elasticsearch elastic/elasticsearch
# Install Kibana: 
helm install --name kibana elastic/kibana
```