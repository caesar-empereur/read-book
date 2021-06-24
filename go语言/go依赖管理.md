### go mod
```
开启 go mod 的命令
go env -w GO111MODULE=on
go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct

在go语言中，第三方依赖的管理工具经过了一个漫长的发展过程。
在GO1.11 发布之前govendor、dep等工具百花齐放。知道go mod 出现，开始一统天下

使用go mod 管理项目，就不需要非得把项目放到GOPATH指定目录下，你可以在你磁盘的任何位置新建一个项目，
比如：在任何一个项目的路径输入 go env 中的 GOPATH 不需要是当前项目目录


新建一个名为 wserver 的项目，项目路径 D:\test\wserver （注意，该路径并不在GOPATH里）

go mod init
已有项目名字的 该命令后面不用加名字，没有项目名字后面需要加项目名

执行 go run main.go 运行代码会发现 go mod 会自动查找依赖自动下载

go mod init 执行后出现 outside GOPATH, module path must be specified 需要
go mod init project
```
