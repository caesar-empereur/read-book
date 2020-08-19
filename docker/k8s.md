## Kubernetes

```
Docker中有成百上千的容器需要启动，如果一个一个的启动那得多费时间，因此需要

对多个容器进行有计划的组织规划，包括指定好部署计划，对资源统一调度，当运行不满足计划时能有自行调节的功能
```
- Kubernetes具有完备的集群管理能力，包括多层次的安全防护和准入机制
- 多租户应用支撑能力、透明的服务注册和服务发现机制、内建的智能负载均衡器
- 强大的故障发现和自我修复能力、服务滚动升级和在线扩容能力
- 可扩展的资源自动调度机制，以及多粒度的资源配额管理能力

## k8s 架构与基本组件
- 架构 
![2pc](https://github.com/caesar-empereur/read-book/blob/master/photo/k8s-arch.png)


- **[Master](#)**
    - Master 的作用
        - Kubernetes里的Master指的是集群控制节点，在每个Kubernetes集群里都需要有一个Master来负责整个集群的管理和控制
        - Kubernetes的所有控制命令都发给它，它负责具体的执行过程
    - Master 运行的关键服务
        - **[kube-apiserver](#)** 提供了HTTP Rest接口的关键服务进程，是Kubernetes里所有资源的增、删、改、查等操作的唯一入口
        - **[kube-controller-manager](#)** Kubernetes里所有资源对象的自动化控制中心，可以将其理解为资源对象的“大总管”
        - **[kube-scheduler](#)** 负责资源调度（Pod调度）的进程，相当于公交公司的“调度室”
        - **[etcd](#)** 所有资源的状态都存储在这个 key-value 存储系统中
- **[Node](#)**
    - Node是Kubernetes集群中的工作负载节点，每个Node都会被Master分配一些工作负载（Docker容器）
    - Node 的关键进程
        - **[kubelet](#)** 负责Pod对应的容器的创建、启停等任务，同时与Master密切协作，实现集群管理的基本功能
        - **[kube-proxy](#)** 实现Kubernetes Service的通信与负载均衡机制的重要组件
        - **[docker](#)** Docker引擎，负责本机的容器创建和管理工作
    - Node可以在运行期间动态增加到Kubernetes集群, 会向Master注册自己, Master 会监控所有Node的状态
- **[Pod](#)**
    - Pod 是为了将提供同一种服务的多个容器组成一个单位统一管理
    - Pod 出现是因为 同一种服务的多个容器有几个挂掉后需要判定该服务目前状态是否可用，需要 *% 才算可用
    - 每个Pod都有一个特殊的被称为“根容器”的Pause容器
    - 多个业务容器共享Pause容器的IP，共享Pause容器挂接的Volume
    - 简化了密切关联的业务容器之间的通信问题，也很好地解决了它们之间的文件共享问题
    - Kubernetes为每个Pod都分配了唯一的IP地址，称之为Pod IP，一个Pod里的多个容器共享Pod IP地址
- **[Label](#)**
    - 一个Label是一个key=value的键值对,用来对各种资源添加属性
    - 随后可以通过Label Selector（标签选择器）查询和筛选拥有某些Label的资源对象
    - Label可以被附加到各种资源对象上，例如Node、Pod、Service、RC等
    - 一个资源对象可以定义任意数量的Label，同一个Label也可以被添加到任意数量的资源对象上
    - 一些常用的标签，例如版本标签，环境标签
- **[Replication Controller](#)**
    - 相当于一个声明了某种Pod以及数量，并且能实时调整运行的Pod数量状态的控制器
    - RC 包含的属性：某种类型的Pod, 预期的Pod数量，帅选Pod的标签选择器
    - RC 也是一个K8S资源，提交到集群后，集群会更具生命的Pod 动态调整
    - **[RC在新版里面叫 ReplicaSet](#)**
- **[Horizontal Pod Autoscaler](#)**
    - HPA 相当于一个根据设定好的指标对Pod副本数量进行动态的扩容收缩的机制
```
通过手工执行kubectl scale命令，我们可以实现Pod扩容或缩容。如果仅仅到此为止，
显然不符合谷歌对Kubernetes的定位目标——自动化、智能化
```

- **[StatefulSet](#)**
    - 在Kubernetes系统中，Pod的管理对象RC、Deployment、DaemonSet和Job都面向无状态的服务
    - 但现实中有很多服务是有状态的，特别是一些复杂的中间件集群，mysql, mongodb, zookeeper, akka
    - 这些服务对应的Pod有特定的属性，固定id，规模稳定，有状态，需要持久化到磁盘
    - 因此定义 StatefulSet 的时候需要对应的Pod 也是有对用的特定的属性