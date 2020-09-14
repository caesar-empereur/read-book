- https 连接建立的过程
![https](https://github.com/caesar-empereur/read-book/blob/master/photo/https.png)

- **[websocket 协议的升级过程](#)**
    - WebSocket复用了HTTP的握手通道。具体指的是，客户端通过HTTP请求与WebSocket服务端协商升级协议
    - 协议升级完成后，后续的数据交换则遵照WebSocket的协议
    - **[1 客户端：申请协议升级](#)**
    ```
    GET / HTTP/1.1
    Host: localhost:8080
    Origin: http://127.0.0.1:3000
    Connection: Upgrade 表示要升级协议
    Upgrade: websocket 表示要升级到websocket协议
    Sec-WebSocket-Version: 13 表示websocket的版本。如果服务端不支持该版本，需要返回一个Sec-WebSocket-Version
    Sec-WebSocket-Key: w4v7O6xFTi36lq3RNcgctw==
    ```
    - **[2 服务端：响应协议升级](#)**
    ```
    HTTP/1.1 101 Switching Protocols 协议转换了
    Connection:Upgrade  协议确认升级
    Upgrade: websocket  表示要升级到websocket协议
    Sec-WebSocket-Accept: Oy4NRAQ13jhfONC7bP8dTKb4PTU=
    ```
