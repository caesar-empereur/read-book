- socket 知识
    * socket 本身不是协议，是对 TCP-IP 协议的封装，是一个程序的调用接口，通过 socket 可以使用TCP-IP协议栈
    * socket 调用接口的关键信息 是地址，端口，socket 区分为客户端 socket, 服务端 socket
    * socket 包含各种函数调用，accept(), connect()，read(), close()
    * 同一个端口的不同状态, listen established 分别对应的是2个不同的 socket
    * **[new Socket(ip, port)](#)** 时对内核进行一个syscall系统调用, **[返回一个文件描述符](#)**, 状态是 listen
    * 服务端的 socket 不断的调用 **[socket.accept()](#)** 方法(阻塞)，**[有客户端连进来时该方法会返回一个 socket](#)**
    * 服务端调用 accept 时，连接成功了会返回一个已完成连接的 socket，后续用来传输数据
    * 监听的 socket 和用来传送数据的 socket，是两个socket，一个叫监听 socket，一个叫已完成连接 socket
- **[linux socket 查看某个端口的 socket 连接](#)**
    - **[lsof -i:9090](#)** 查看一个端口的pid和socket情况
    - 找到 pid，定位到 **[proc/pid/fd](#)** 目录下查看有多少个 fd 文件
![2pc](https://github.com/caesar-empereur/read-book/blob/master/photo/socket-fd.png)

- linux 服务器 socket 命令
    * proc/pid/task  这个目录中有多少个文件就说明 这个pid有多少个线程
    * proc/pid/fd    这个目录有多少个 socket 文件就是有多少个文件描述符
    * netstat -natp  可以输出哪个pid,进程名字的 socket 端口状态
    * nc localhost 8090 可以直接连接端口发送数据

- IO 模型知识
    - **[socket 场景举例](#)**
        - 服务端 socket 创建后，有100个客户端 socket 建立了连接，在端口对应的pid proc/pid/fd 目录下有100个fd
        - 在普通的io模型中，要查看 100个 socket 是否有读写发生，就要对100个socket轮流询问，或者启用100个线程询问
    
    - **[普通的阻塞 io](#)**
        - 要查看 100个 socket 是否有读写发生，就要对100个socket轮流询问，或者启用100个线程询问
        - 有多个 socket 连接时，不是所有连接都在发送数据，但是浪费了很多线程维持 socket 读写
            
    - **[多路复用](#)**
        - **[多路指一次调用能处理多个socket, 复用指能复用同一个线程](#)**
        
        - **[select](#)**
            - select 的机制
                * 每次内核系统调用都要传入一个文件描述符的set (fd_set)，内核经过处理返回
                    已经准备好IO读写的文件描述符
                * **[对照上面例子，就是每次系统调用传入 100 个fd的set,内核返回有读写事件的 fd](#)**
            - 缺点
                * 1 每次系统调用 select，都需要传入 fd_set 参数
                * 2 内核其实也是对 fd_set 遍历处理，fd_set 很大时，耗时
                * 3 fd_set 大小是有限制的，最大 1024
        - **[poll](#)**
            - 机制与 select 类似，只是通过改变 fd_set 的类型解决了 select 缺点中的第三个问题
        
        - **[epoll](#)**
            - epoll 的系统调用从一步变为2步，分别是 epoll_create(),  epoll_wait()
            - epoll_create()调用时一次性传入多个 socket fd,内核会生成一个 epoll 对象，包括存储所有 socket 的红黑树，存储有读写事件的 fd 列表
            - 只要有 socket 有对应的读写事件发生，内核 **[事件驱动](#)** 产生一个回调，把该fd复制到 fd 列表
            - epoll_wait() 调用时直接返回准备好读写的 socket fd列表
            - **[对照上面例子，只需要一次性传入100个fd，以后每次epoll_wait() 调用就可返回有读写请求的 fd 列表](#)**
     - **[nginx, redis, netty(linux)](#epoll)** 都是使用 epoll 模型的
    

| **[对比项](#对比项)** | **[select](#select)** | **[poll](#poll)** | **[epoll](#epoll)** |
|:-----------:|:---------------:|:----:|:---:|
| 对 fd 的操作 | 遍历 | 遍历| 回调 |
| 数据结构 | 数组 | 链表 | 红黑树 |
| 事件复杂度 | O(n) | O(n) | O(1) |
| 最大连接数 | 1024 | 无限制 | 无限制 |


```
多路复用与 BIO, NIO 的一个重要区别就是一次操作系统内核调用是否可以处理多个 socket 对应的文件描述符
也就是单个进程可以监视多个文件描述符
处理的意思是检查 socket 是否已经有数据可以准备读写
``` 
