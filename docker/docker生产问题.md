- docker 干掉 jvm 进程
```
https://www.cnblogs.com/duanxz/p/10248762.html

https://blog.csdn.net/lbh199466/article/details/90062636?utm_medium=distribute.pc_relevant.none-task-blog-baidujs_baidulandingword-1&spm=1001.2101.3001.4242
```

```
那么Java是如何获取到Host的内存信息的呢？没错就是通过/proc/meminfo来获取到的
默认情况下，JVM的Max Heap Size是系统内存的1/4
Docker通过CGroups 实现对容器内存的限制，/proc/meminfo 是以只读形式挂载到容器中的，
容器中的 Java 程序启动的时候读取到的是 /proc/meminfo，不会感知到 CGroups 对容器内存的上限。
这种不兼容情况会导致，如果容器分配的内存小于JVM的内存，JVM进程会被理解杀死。
JVM 的 Xmx 设置的跟 容器的内存限制差不多大的时候，容易被容器进程 kill 掉，但是 Jvm 并没有
OOM 的日志输出，因为 Java 程序需要的内存除了 堆之外，还有方法区，栈，元空间，加起来可能会大于
CGroup 对容器内存的大小上限

docker stats 容器id 可以看到容器实际使用的内存，以及 docker 对容器内存的大小限制
ubuntu 默认的 docker 通过 CGroup 对容器内存的大小上线 跟 宿主机 的内存是一样的

docker 运行启动容器的时候如果指定了 容器的内存限制 超过容器程序需要的内存，容器不会启动成功，系统也会有日志报错
Memory cgroup out of memory: Kill process 9284 (java) score 1035 or sacrifice child
[Thu May 27 17:21:07 2021] Killed process 9284 (java) total-vm:3311600kB, anon-rss:406452kB, file-rss:16648kB, shmem-rss:0kB

kubectl get pod
status oomkilled

root@leon:/home/base-service/k8s/app# kubectl get pod
NAME                                  READY   STATUS      RESTARTS   AGE
webapi-service-xmx-5bc86d8dbf-mpvh5   0/1     OOMKilled   4          115s
```
