```
Forbidden!Configured service account doesn't have access. Service account may have been revoked

kubectl create clusterrolebinding endpoints-reader-mydefault --clusterrole=endpoints-reader --serviceaccount=ns-booker:default

kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts
```


- 查看kubelet的运行日志 journalctl -xeu kubelet
