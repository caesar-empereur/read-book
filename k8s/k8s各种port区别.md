- container port
```
container port  是 pod 里面的 docker 容器的端口，必须要跟应用配置的启动的
端口一致
```

- target port
```
targetPort是pod上的端口，从port/nodePort上来的数据，经过kube-proxy流入到后端pod的targetPort上，最后进入容器
```


- port
```
port是暴露在cluster ip上的端口，:port提供了集群内部客户端访问service的入口，即clusterIP:port
```

- node port
```
nodePort 提供了集群外部客户端访问 Service 的一种方式，nodePort 提供了集群外部客户端访问 
Service 的端口，通过 nodeIP:nodePort 提供了外部流量访问k8s集群中service的入口
```
