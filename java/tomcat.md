- tomcat 的线程池默认是200，最大连接数是1W
    ```
    这么设计的原因是大部分应用不是CPU密集型的，链接建立了，线程在处理请求，
    但是大部分场景都是在等待，要么是数据库查询等待，磁盘IO等待，网络IO等待
    CPU真正执行的时间是比较短的，因此连接数会比线程数大很多，提高CPU利用率
    
    tomcat 的连接数与线程数的关系是如果是BIO模式的话，2个是一样的，
    如果是NIO的话，连接数明显要比线程数高一个数量级
    
    NioEventLoop底层会根据系统选择select或者epoll。如果是windows系统，
    则底层使用WindowsSelectorProvider（select）实现多路复用；如果是linux，则使用epoll
    ```
    
- JDK的线程池已经很强大了，为什么 tomcat 要扩展自己的线程池？
    - 通常情况下，认为分为 CPU 密集型和 IO 密集型
    - CPU 密集型因为线程一直在执行，这种情况需要少创建线程，线程多会造成上下文切换
    - IO 密集型线程大部分是在等待，等待IO的返回，因此增加线程数可以增加并发处理能力
    - JDK 原生的线程池适合CPU密集型的，但是大部分web应用都是IO密集型的，因此需要扩展自己的线程池
    - tomcat 扩展线程池的方式是继承了JDK的线程池的类，
- tomcat 连接会影响到线程的运行吗？
    - tomcat 的HTTP连接没有设置超时时间的话，线程可能会一直在 WAITING
    - 大量连接对应的请求没有设置超时，大量的线程在 WAITING, 会将线程池占满，导致无法处理请求
    - 因此，一个接口在没有超时时间，很容易就会因为瞬间并发量大而占满线程池，无法再处理请求