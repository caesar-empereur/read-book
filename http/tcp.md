- TCP 三次握手四次挥手

    - 3次握手
    ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/tcp握手.png)
    - 为什么是3次，不是2次握手?
    
        * 简单的理解：2次握手相当于发送一次，对方确认并回复一次，发送方多一次确认的作用相当于，保证之前发出去的
        报文是建立连接的准确标志。
            ```
            有一种是发送的 SYN 报文延迟了，连接都已经关闭了，这时候SYN才到达，如果不对这个
            SYN 做确认，会导致连接重新建立
            ```
    - 4次挥手
    ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/tcp挥手.png)
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


