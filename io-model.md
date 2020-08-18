- socket 知识
    * socket 本身不是协议，是对 TCP-IP 协议的封装，是一个程序的调用接口，通过 socket 可以使用TCP-IP协议栈
    * TCP/IP 只是一个协议栈，就像操作系统的运行机制一样，必须要具体实现，同时还要提供对外的操作接口
    * socket 调用接口的关键信息 是地址，端口
    * socket 区分为客户端 socket, 服务端 socket
    * socket 包含各种函数调用，accept(), connect()，read(), close()
    
    * socket 底层知识
        ```
        new Socket(ip, port) 时对系统内核进行一个 socket syscall 系统调用，得到一个文件描述符，
        然后 socket 绑定地址，端口，socket 此时变成 listen 状态，调用 accept() （阻塞）
        方法才能知道有没有 客户端连接进入
        
        同一个端口的不同状态, listen established 分别对应的是2个不同的 socket
        ```
- linux 服务器 socket 命令
    * proc/pid/task  这个目录中有多少个文件就说明 这个pid有多少个线程
    * proc/pid/fd    这个目录有多少个 socket 文件就是有多少个文件描述符
    * netstat -natp  可以输出哪个pid,进程名字的 socket 端口状态
    * nc localhost 8090 可以直接连接端口发送数据

- IO 模型知识

    * 非 多路复用
        * BIO (阻塞式 IO)
            - 服务端的 socket 不断的调用 socket.accept() 方法，有客户端连进来时该方法会返回一个 socket
            - 然后新开一个线程出处理这个 socket 的读写事件，客户端的读写数据是不确定的
            - socket.read() 方法是 **阻塞** 的（在操作系统的底层是使用 recev_from 系统调用）有数据才会返回
            - 有多个 socket 连接时，不是所有连接都在发送数据，但是浪费了很多线程维持 socket 读写
        
        * NIO
            - 同样是上面的场景，socket.read() 方法不是阻塞的，有数据就返回，没数据就返回一个状态
            - 这里的非阻塞的 底层实现是操作系统 对 socket 设置为 非阻塞的
            - 但是还是避免不了需要不断询问数据是否准备好了
            - **java 的 NIO 不是 NO-BLOCKING, 而是 NEW IO**
            - java nio 包括了通道，缓冲区，选择器，支持 **多路复用** 的 IO 模型
            - java nio 包的 Seletor 类代码注释的第一句话就是 **多路复用**
        
    * **[多路复用](#)**
        - **[多路指一次调用能处理多个socket, 复用指能复用同一个线程](#)**
        
        - **[select](#)**
            - select 的机制
                * 每次内核系统调用都要传入一个文件描述符的set (fd_set)，内核经过处理返回
                    已经准备好IO读写的文件描述符
            - 缺点
                * 1 每次系统调用 select，都需要传入 fd_set 参数
                * 2 内核其实也是对 fd_set 遍历处理，fd_set 很大时，耗时
                * 3 fd_set 大小是有限制的，最大 1024
        - **[poll](#)**
            - 机制与 select 类似，知识通过改变 fd_set 的类型解决了 select 缺点中的第三个问题，
        
        - **[epoll](#)**
            - epoll 的系统调用从一步变为三步，分别是 epoll_create(), epoll_ctl(), epoll_wait()
            - epoll_create() 
                - 调用时内核会生成一个 epoll 对象
                    - rb_root：存储所有 socket 的红黑树 
                    - rdlist：存储有读写事件的socket
            - epoll_ctl() 
                - 调用时将所有 socket 添加到这个rb_root
            - 只要有 socket 有对应的读写事件发生，会产生一个回调，把 rb_root 中的对应的socket 复制到 rdlist 中
            - epoll_wait()
                - 调用时直接返回 rdlist 准备好读写的 socket 列表
                
            - **[nginx, redis, netty(linux)](#epoll)** 都是使用 epoll 模型的
    

| **[对比项](#对比项)** | **[select](#select)** | **[poll](#poll)** | **[epoll](#epoll)** |
|:-----------:|:---------------:|----:|:---:|
| 对 fd 的操作 | 遍历 | 遍历| 回调 |
| 数据结构 | 数组 | 链表 | 红黑树 |
| 事件复杂度 | O(n) | O(n) | O(1) |
| 最大连接数 | 1024 | 无限制 | 无限制 |


```
多路复用与 BIO, NIO 的一个重要区别就是一次操作系统内核调用是否可以处理多个 socket 对应的文件描述符
也就是单个进程可以监视多个文件描述符
处理的意思是检查 socket 是否已经有数据可以准备读写
``` 
