### go get 下载安装包无响应的问题解决
- gopm 之前是一个解决方式，但是 gopm.io 的网站现在关闭了，因此行不通
- 把 go 的镜像改成阿里云的
```
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct
```

- go get 安装 github 上的依赖的时候，只需要进入项目的根目录

- beego 应用启动的时候  cannot find main module
```
如果你是使用go mod 管理依赖，首先检查：项目根目录有没有go.mod文件

如果没有, 执行命令go mod init在当前目录下生成一个go.mod文件
```

### beego 项目初始化

- go get github.com/astaxie/beego
- go get github.com/beego/bee
- bee new project
- go mod init 或者 go mod init project
```
采用 go mod 依赖管理模式
```
- 项目依赖下载后代码还是报红色的依赖错误
```
可以在 goland 的 setting go modules 里面的 enable 勾选上
```
