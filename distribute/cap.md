- CAP理论
    - 一个分布式系统最多只能同时满足一致性、可用性和分区容错性这三项中的两项
    - 一致性
        - 一致性，说的就是数据一致性。分布式的一致性
        - 一致性是因为有并发读写才有的问题，因此一定要注意结合考虑并发读写的场景
        - 三种一致性策略(mysql读写分离的场景)
            - 更新过的数据能被后续的访问都能马上看到，这是强一致性
            - 如果能容忍后续的部分或者全部访问不到，则是弱一致性
            - 如果经过一段时间后要求能访问到更新后的数据，则是最终一致性
        - CAP中说，不可能同时满足的这个一致性指的是强一致性
    - 分区容错性
        - 分布式系统在遇到某节点或网络分区故障的时候，仍然能够对外提供满足一致性和可用性的服务
- CA without P
    - 这种情况在分布式系统中几乎是不存在的。首先在分布式环境下，网络分区是一个自然的事实
    - P是一个基本要求，CAP三者中，只能在CA两者之间做权衡，并且要想尽办法提升P
- CP without A
    - 设计成CP的系统其实也不少，其中最典型的就是很多分布式数据库，他们都是设计成CP的
    - 优先保证数据的强一致性，代价就是舍弃系统的可用性
    - Redis、HBase，Zookeeper也是优先保证CP的
    - zookeeper 在选举的过程当中是不可用的，也是CP
    - ZooKeeper是分布式协调服务，它的职责是保证数据在其管辖下的所有服务之间保持同步、一致
    - 注册中心不能因为自身的任何原因破坏服务之间本身的可连通性，这是注册中心设计应该遵循的铁律
    - 注册中心的作用应该是体现在服务的注册，服务节点扩容的时候，而不是每一次服务调用，这样影响才会小