- TCP 三次握手

    - 为什么是3次，不是2次握手?
    
        * 简单的理解：2次握手相当于发送一次，对方确认并回复一次，发送方多一次确认的作用相当于，保证之前发出去的
        报文是建立连接的准确标志。
            ```
            有一种是发送的 SYN 报文延迟了，连接都已经关闭了，这时候SYN才到达，如果不对这个
            SYN 做确认，会导致连接重新建立
            ```
    
    - 为什么不是4次握手？
        * 4次相当于 客户端发送一次，等待回复确认，服务端发送一次，等待回复确认
            ```
            1  SYNC  -->
            2  ACK   <--
            3  SYNC  <--
            4  ACK   -->
            
            2， 3 步 是可以合并成一次发送的
            ```
        
    - 为什么4次挥手？
        * 每个端都需要发送 FIN, 等到ACK, FIN发送后，该端处于半关闭状态，仍然可以接收数据包
        * 另一端收到 FIN 后，可能不会马上关闭，还有剩余的数据要发送，等发完了再发 FIN
    
        ```
        为什么3次握手，4次挥手的原因：
        1 为实现TCP这种全双工（full-duplex）连接的可靠释放
        2 为使旧的数据包在网络因过期而消失
        ```
    
    - 怎样确定一个TCP连接？
        * 源IP, 源端口，目标IP，目标端口

- TCP time_wait 状态

    * time_wait 是什么？
      ```
      主动关闭连接的一方，会在发送完最后一个 ACK 报文之后进入 time_wait 状态，
      并且持续 MSL的时间，大概是一分钟，才入真正关闭连接，在MSL期间，这个连接不能被释放或者重新分配
      ```
    * time_wait 状态产生的原因？
    
        * 为实现TCP全双工连接的可靠释放
            ```
            FIN_WAIT    FIN  -->   CLOSE_WAIT
                        ACK  <--
                        FIN  <--
            TIME_WAIT   ACK  -->
             |2MSL|                 CLOSED
            CLOSED
            
            根据挥手的状态图，主动关闭方在发送完最后一个 ACK 报文丢失后，被动方没收到 ACK, 重新
            发送 FIN 信号，这时候如果主动方时关闭状态，可能会RST响应这个报文，对方认为有错误发生
            ```
        * 为使旧的数据包在网络中丢失
            ```
            假设主动关闭方发完最后一个 ACK 后，就是 CLOSED 状态，前面的传输的报文因为延迟还没到达，
            该连接被重新分配发送数据，旧数据跟新数据一起达到另一方，会导致数据错乱
            ```
        * time_wait 的弊端
            ```
            线上服务器如果有太多 连接处于 time_wait 的话，会导致无法建立新的连接
            ```


- 浏览器建立关闭连接的过程
    
    * 浏览器打开一个页面的时候，可以看到浏览器会保持一个连接，状态是 ESTABLISHED
    * 用多个 tab 打开同一个网站，用的是同一个连接
    * 关闭一个网站之后，该TCP连接不会马上关闭，操作系统对该连接设置为 time_wait 状态
    * 在同一个网站的TCP连接还处于 time_wait 状态时再打开该网站，是会重新建立一个连接的，只是本地端口不一样

- linux 查看tcp状态的命令
    * netstat -an|grep tcp
    
- tcp 状态图

| 客户端的状态 | 服务端的状态 | 共有的状态 |
|:-----------:|:---------------:|--------:|
| SYNC_SENT | LISTEN | ETABLISHED |
| FIN_WAIT1 | SYN_RCVD | CLOSED |
| FIN_WAIT2 | CLOSE_WAIT |
| CLOSING | LAST_ACK |
| TIME_WAIT |  |

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
