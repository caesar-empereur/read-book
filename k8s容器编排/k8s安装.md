## k8s安装 

- 1 kubeadm  kubectl  kubelet 安装
```
apt-get update && apt-get install -y apt-transport-https
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat /etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
apt-get update
apt-get install -y kubelet kubeadm kubectl
```
- 2 kubeadm 初始化
```
kubeadm init --kubernetes-version=1.18.3 --image-repository registry.aliyuncs.com/google_containers --pod-network-cidr 10.244.0.0/16

注意： --pod-network-cidr 10.244.0.0/16 这个参数后面的地址必须与 kube-flannel.yml 里面配置的地址对应

cp /etc/kubernetes/admin.conf $HOME/.kube/config

```

- 其他节点加入master
```
kubeadm init 输出的结果里面有一条 join 命令，复制出来
kubeadm join 192.168.220.198:6443 --token vveu0f.ffqwvhoq785r3ghg 
--discovery-token-ca-cert-hash sha256:36c49f135c3578b591a2e8b3d42062f2ca55c6852769941de4ad902ab6dad3fb

把master也当作node的命令
kubectl taint node --all node-role.kubernetes.io/master-

把master恢复为master的命令
kubectl taint node --all node-role.kubernetes.io/master="":NoSchedule
```

- 3 安装pod网络插件flannel
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f /home/base-service/k8s/kube-flannel.yml

发现coredns还是pedding 这个没关系,我们还需要安装Pod Network插件,这里安装的是

kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/etcd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/rbac.yaml
kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/calico.yaml
```

- 4 查看所有的pod 是否为 running
```
NAMESPACE              NAME                                         READY   STATUS    RESTARTS   AGE
kube-system            coredns-7ff77c879f-c78sd                     1/1     Running   0          6h4m
kube-system            coredns-7ff77c879f-xkwzh                     1/1     Running   0          6h4m
kube-system            etcd-leon                                    1/1     Running   0          6h5m
kube-system            kube-apiserver-leon                          1/1     Running   0          6h5m
kube-system            kube-controller-manager-leon                 1/1     Running   0          6h5m
kube-system            kube-flannel-ds-amd64-lp7z5                  1/1     Running   0          5h58m
kube-system            kube-proxy-6tb7z                             1/1     Running   0          6h4m
kube-system            kube-scheduler-leon                          1/1     Running   0          6h5m
kubernetes-dashboard   dashboard-metrics-scraper-694557449d-fcgdb   1/1     Running   0          30m
kubernetes-dashboard   kubernetes-dashboard-7d9ddf9f8f-wf8rv        1/1     Running   0          30m
```

- 5 安装 dashboard 管理界面

    - kubectl apply -f /home/base-service/k8s/dashboard-ns.yaml
    - 自己生成证书
        - openssl genrsa -out dashboard.key 2048
        - openssl req -new -out dashboard.csr -key dashboard.key -subj '/CN=192.168.246.200'
        - openssl x509 -req -in dashboard.csr -signkey dashboard.key -out dashboard.crt
    - 把证书加入到 kubectl
        - kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kubernetes-dashboard
        - 有问题再删除证书 kubectl delete secret kubernetes-dashboard-certs -n kubernetes-dashboard
    - 输出页面登陆用的 token
        - kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
    - kubectl apply -f /home/base-service/k8s/dashboard.yaml
    - 重新执行配置文件创建 dashboard
        - kubectl delete -f /home/base-service/k8s/dashboard.yaml
    - 拿到 token 到页面登陆
```
自带的校验的证书是不可用的，在浏览器打开会报错
因此需要自己生成证书，并且把这个证书加入到 kubectl 里面，还必须加上 dashboard 对应的 kubernetes-dashboard 命名空间的参数
但是dashboard yml 文件还没执行的时候，这个 kubernetes-dashboard 命名空间是还没创建的，
因此需要先把 yml 文件里面的命名空间配置拿出来单独放置，然后先执行这个文件创建空间，再这个证书加入到 kubectl 里面，
再执行创建 kubernetes-dashboard 其他的资源
```



## kubectl 常用命令
- kubectl get pod --all-namespaces
- kubectl get pod -n kube-system
- kubectl get nodes
- kubectl get svc --all-namespaces
- kubectl delete pod j5wmf -n *** --force --grace-period=0
- kubectl describe pod lx2xh -n ku
- netstat -lntup | grep nginx
- kubectl logs -f ingress-controller-n4pd6 -n ingress-nginx
