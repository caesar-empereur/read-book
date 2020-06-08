## nginx 灰度发布项目

#### 项目大致介绍

- 背景：一种常见的应用灰度发布的实现
```
一个线上的应用部署有 4台服务器，nginx 做了负载均衡，策略可能为 ip_hash，轮询，权重 之类的。
每次的请求可能分发到不同的服务器

在应用发布的时候，先把 发布的文件部署到一台服务器上，并且把这台服务器设置为内部访问，nginx 这时把
这台服务器不加入到负载均衡里面，线上的流量只访问到其他3台节点。测试人员通过内部ip访问到这台新发布应用的
节点，在测试完成之后就把这台服务器重新加入到负载均衡里面。

以上的工作都是运维完成的，相当于重复的工作


```

- 灰度发布系统需要的功能功能
    - 1 维护一个服务对应的有几台服务器节点和端口信息
    - 2 可以对特定节点动态设置为只能内部访问，或者负载均衡的值很小，线上只有 1/8 的流量会进入这个节点
    - 3 nginx 会动态的获取到这些节点的信息，判断到一台节点被设置为内部访问了，就不加入到负载均衡
    - 4 对这台节点进行应用发布，发布完之后进行线上测试验证
    - 5 特定节点服务器验证完之后重新动态的设置为正常节点
    - 6 nginx 重新又把该节点加入到 负载均衡

- 方案
    - 1 发布系统需要又一个页面维护节点的ip，端口信息
    - 2 界面可以动态修改这个某个节点的属性，例如设置为内部访问，或者把权重的值降得很低
    - 3 以上信息作为基本信息维护在数据库，并且同步到 redis，数据库一有更新就同步到 redis
    - 4 nginx 里面加上 nginx_lua，lua_redis 模块
    - 5 nginx 每次处理请求得时候都通过lua获取到redis 里面得节点信息
    - 6 lua 里面判断哪些节点做特殊处理，例如客户端为一个公司内部ip就访问到这个节点，线上流量不进入这个节点
    - 7 为了防止异常出现，nginx 里面还是要维护这些节点的信息，在redis 不可用的时候，直接跳过上面的逻辑

- 方案需要的工具
    - 1 nginx
    - 2 luajit 环境
    - 3 lua_nginx_module， redis2-nginx-module 这2个模块
    - 4 redis，mysql 环境
    - 5 节点信息的维护页面接口需要一个后台，可用 springboot 或者 gin
    
- 方案开搞步骤

    - 1 windos 的 gcc 环境安装配置
        - 1 下载安装配置 mingw64（windos的gcc的编译运行环境）
        - 1 下载 x86_64-8.1.0-release-posix-seh-rt_v6-rev0
        - 2 解压然后进入 mingw64/bin 吧这个目录配置到 path 里面
        - 3 检查安装正常，命令行 gcc -v
    - 2 windos luajit 环境安装配置
        - 1 载luajit-2.0.5 依赖
        - 2 进入根目录执行命令 mingw32-make E:\LuaJIT-2.1.0-beta3>mingw32-make
        - 3 编译完成之后，将src下面的luajit.exe和lua51.dll两个文件拷贝到新建的E:/LuaJIT文件夹下面，
            并将src下面的jit文件夹拷贝到E:/LuaJIT/lua下面
        - 4 创建一个lua脚本test.lua print("hello world") 然后使用luajit进行编译生成bytecode
        - 5 E:\Test\lua>luajit -b test.lua 1.lua
    - 3 nginx 添加依赖的模块
        - ./configure --add-module=D:\dev\app\nginx\module\ngx_devel_kit-0.3.1 --add-module=D:\dev\app\nginx\module\lua-nginx-module-0.10.16rc5
        
lua 测试 403 需要管理员模式启动命令行 tasklist /fi “imagename eq nginx.exe”
taskkill /f /pid {pid} 把对应 pid 的nginx 干掉，脚本干掉nginx 进程可能会有一些无法 kill，是命令行权限问题
