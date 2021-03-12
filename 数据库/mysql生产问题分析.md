- mysql cpu 占用过高怎么解决？
    - top -H 找出占用CPU高的mysql线程id(这里找出的id是操作系统的线程id)
    - mysql 的线程id有 thread_id(mysql内部使用的) 和 thread_os_id(操作系统使用的)
    - select * from performance_schema.threads where thread_os_id=top -H 找出来的
    - 从上面的结果中找到 thread_id
    - show processlist 中找出该线程id=thread_id, kill 掉
    - show processlist 结果中出现 Creating sort index，说明有大数据的排序sql，磁盘，cpu性能消耗大
    
- mysql cpu 占用过高的原因
    - 慢查询
        - order by, group by, join，distinct 大数据量的时候，出现临时表，大量io, 文件排序等消耗cpu操作
        - mysql 的profile命令可以分析单个查询id，如果send data 比例很高，说明大量磁盘io
        - mysql 大量磁盘io，计算大量结果集的时候，不是将结果一次性发送到客户端的，而是边发边查的
        - mysql show processlist 的结果是当前正处理的查询线程，查询结束就不会在结果集中了
    - 并发高

- mysql服务器，应用服务器负载低，压测 tps,qps 很低的情况分析
    - 数据库，应用的负载都不高，接口吞吐量上不去，就是机器资源没利用起来
    - 这种低qps还有个情况就是单个查询效率很高，几十毫秒返回，show processlist只能看到连接数，time都是0
