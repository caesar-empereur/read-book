## rabbitmq的基本组件
- channel
    - 客户端与服务器肯定是需要保持对应的tcp链接
    - 每个tcp链接的创建与消费比较消耗性能
    - 因此一个tcp连接里面可以构建一些虚拟的连接，这个就是channel
    - 一个tcp里面可以维护多个的channel虚拟连接
    - 每个channel是有对应的线程维护这些连接的
- queue
    - rabbitmq里面没有topic这种概念，就是直接的队列来处理消息
- exchange-routingkey-bindingkey
    - rabbit发送消息的时候不是直接往队列里面发的
    - 而是先让 exchange 通过 bindingkey 跟queue绑定
    - exchange 跟 queue 的绑定关系确定了exchange 的消息只会往哪些 queue 发
    - exchange 与 queue 是多对多的关系
    - 发送消息的时候消息属性的 routingkey 确定了只会通过 exchange 往哪个 queue 发
      ![rocketmq](https://github.com/caesar-empereur/read-book/blob/master/photo/mq/rabbitmq-exchange.png)

- vhost
    - vhost 本质上就是一个 mini 版的 RabbitMQ 服务器, 提供了逻辑上的隔离
    - 它拥有自己的队列、交换器、绑定等，同时它也有自己的权限控制
    - 在一个公司有统一的rabbitmq服务器情况下，每个部门可以建立自己的 vhost，实现消息数据的隔离与管理
## rabbitmq的集群模式
- 普通集群模式
    - 在多台机器上启动多个RabbitMQ实例
    - queue只会放在一个RabbitMQ实例上
    - 放queue的实例宕机了, 就会导致这个队列的数据无法被消费
    - 这个方案主要是提高吞吐量, 就是让集群中多节点来服务queue的读写操作
- 镜像集群模式
    - 创建的queue会存在多个mq实例上
    - 每次发送消息都会把消息同步到多个实例的对应的 queue 上
    - 其中一台实例宕机了，也不会影响队列的消息消费，实现了高可用的设计
    - 缺点
        - 性能开销比较大，因为一个消息需要同步到多个实例上，一个消息存多份，占用磁盘
        - 比较难扩展，当一个队列的消息比较多，很难通过增加节点来扩容服务器

## rabbitmq 的其他问题
- rabbitmq 的消息存储机制
    - rabbitmq 的消息默认是存储到内存当中的
    - 当消息没来得及消费，服务器挂掉了，消息就会丢失
    - 可以开启持久化到磁盘的选项，确保消息持久化存储
- rabbitmq 的消费者如何保证消息成功消费
    - 消息消费完默认是自动ack的，就是返回给服务器已经消费成功了
    - 可以关掉自动的 ack 机制，开启手动 ack，处理完才回复 ack，确保消息消费成功
