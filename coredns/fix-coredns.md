
# https://codingxx.com/k8s-install/

# 修复coredns1.8 bug，否则coredns pod状态一直异常
# 错误日志为：E0627 18:12:23.287866       1 reflector.go:138] pkg/mod/k8s.io/client-go@v0.21.1/tools/cache/reflector.go:167: Failed to watch *v1.EndpointSlice: failed to list *v1.EndpointSlice: endpointslices.discovery.k8s.io is forbidden: User "system:serviceaccount:kube-system:coredns" cannot list resource "endpointslices" in API group "discovery.k8s.io" at the cluster scope
# 参考链接: https://githubmemory.com/repo/coredns/helm/issues/9
kubectl edit clusterrole system:coredns
# 在最后添加下面内容, 并等待一分钟左右，coredns恢复正常：
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
