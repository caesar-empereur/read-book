## spring 启动流程
- **[配置获取解析]()** 并且注入到环境对象
- **[容器，上下文创建]()**，bean的创建，后置处理，注入容器
- 预处理上下文
- 刷新上下文
  - bean的后置处理接口的初始化调用
     - 解析启动类上的注解，扫描factory文件下的类，执行 **[自动装配]()**
  - 应用的上下文监听的接口初始化调用
  - **[创建启动tomcat服务]()**
    - tomcat 基本原理
        - 创建tomcat对象，创建连接器并且赋给 tomcat对象
        - 配置tomcat的各个子容器，context, host, engine
        - 一个tomcat server就是一个tomcat程序，可以部署多个service，对应到多个应用
        - 每个应用的有自己的连接器与容器，连接器可以有多个，容器只有一个
    - 内置tomcat启动处理请求流程
        - 创建tomcat对象，创建连接器并且赋给 tomcat对象
        - 启动一个 Acceptor 线程，run 方法里面每隔 50 毫秒从 ServerSocketChannel accecpt 一个socket 出来
        - Acceptor 线程将socket封装好之后提交到tomcat的线程池，接下来就是 http-nio-exec 的线程来处理业务
        - http-nio-exec 线程需要解析socket为请求对象，service方法处理后解析为 response 对象返回


## springboot starter 的原理
- 定义一个配置类，@Configuration 注解的类
- 在 resources/META-INFO 目录下新建一个 spring.factories，写上以下内容
- org.springframework.boot.autoconfigure.EnableAutoConfiguration=com.demo.starter.config.DemoConfig
