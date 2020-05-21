### JVM 内存相关
- 1 JVM 内存结构
    - 堆 heap
    - 栈 stack
        * 本地方法栈
        * 虚拟机栈
    - 方法区
    - 程序计数器

- 2 对象的创建过程
    - new 指令时，检查对象的类是否已经加载，没有则先加载类
    - 类加载完后，为对象分配内存空间，优先在栈上分配
    - 设置对象头的信息，包括哈希码，锁信息，偏向线程id，分代年龄，类型指针
    - 分配内存后，执行对象的 init 方法

- 3 对象的内存布局
    - 对象头 （8个子节）
        * 哈希码，分代年龄
        * 指向锁的指针，偏向线程id
        * 类型指针
    - 实例数据 （8个子节）
    - 对齐填充

- 4 对象的访问定位
    - 通过句柄访问对象
        * 堆中有一个句柄池的地方，存储的是堆中对象的地址，
        本地变量表的引用指向的就是句柄池的地址
        
    - 通过直接指针访问对象
        * 栈中的本地变量表的引用指向的就是堆中的对象的地址

```
优缺点
直接指针访问速度快
句柄访问 reference 存储的是句柄中稳定的地址，不会变，对象移动（GC）时reference 不需要修改
```

### GC 相关

- 1 分区比例
    - young 新生代
        - eden区 80%
        - 2个survivor 区，各10%
    - old 老年代
    - metaspace (1.8之后代替永久区)

- 2 gc 过程

    - 对象优先在方法线程栈上分配内存空间，方法调用结束后栈帧弹出，内存自动释放，不需要回收对象
    - 没有在栈上分配的则在 eden 区分配， eden 区空间不足会产生一次 minor gc
    - 每次minor gc 时，把eden区，一个 survivor 区的垃圾回收，存活对象放到另一个survivor
    - 在survivor 中每熬过一次gc，对象头的分代年龄加1，到了15次之后进入老年代
    - old 空间不足会引发 major gc，full gc 是针对整个堆的 gc
    
    
- 3 full gc 的触发条件

    - old 空间不足，新生代转移过来的对象大于old剩余空间
    - System.gc, 不一定会执行
    - minor gc ，设置了空间分配担保，存活对象大小大于old剩余空间，也会触发

- 4 pararell gc

    - jdk1.8 默认是pararell gc 是使用复制算法的并行多线程收集器
    - pararell 有 pararell scavenge gc 和 pararell old gc
    - cms 是缩短停顿时间， pararell 是控制吞吐量，停顿时间短适合用户交互，pararell适合后台计算
    
- 5 CMS
    - cms 是缩短停顿时间， pararell 是控制吞吐量，停顿时间短适合用户交互，pararell适合后台计算
    - 初始标记-->并发标记-->重新标记-->并发清理
    - 初始标记，重新标记需要stw,初始标记是按照根搜索找出到根对象没有引用链的对象
    - 并发标记是与工作线程同时进行的，因此标记过程中工作线程会改变到根对象的引用链关系，
      所以需要重新标记

### JVM 调优参数

- 1 打印 JVM 得所有参数，大概有几百个
    - java -XX:+PrintFlagsFinal
    
- 2 打印 JVM 被用户设置过得参数
    - java -XX:+PrintCommandLineFlags
    
- 3 JVM 常用参数配置
    - 堆配置参数
        * -Xms: 初始堆大小
        * -Xmx: 最大堆大小，与上面的设置一样，可以避免内存空间重新分配
        * -Xmn: 新生代大小
        * -Xss: 每个线程的堆栈大小
        * -XX:NewSize 设置年轻代大小
        * -XX:MaxNewSize 年轻代最大值
        * -XX:NewRatio: 设置新生代和老年代的比值。为3，表示年轻代与老年代比值为1：3
        * -XX:SurvivorRatio: 新生代中Eden区与两个Survivor区的比值
        * -XX:MaxTenuringThreshold: 设置转入老年代的存活次数
    - GC 统计信息
        * -XX:+PrintGC
        * -XX:+PrintGCDetails
        * -XX:+PrintGCTimeStamps
        * -Xloggc: /usr/jvm-gc.log
    - 其他配置参数
        * -XX:+HeapDumpOnOutOfMemoryError 发生内存溢出时导出堆内存现场
        * -XX:HeapDumpPath=/usr/heap.hprof 文件可以通过JVisiaulVM工具查看分析

### JVM 常用命令
- jps 查看当前所有 java 进程的 pid
    - jps

- jmap  查看堆内存的信息
    - jmap -heap pid （打印进程为 pid 的堆的使用信息，输出结果为）
        * young generation 大小与已使用比例
            * Eden
            * From Space (就是 survivor)
            * To Space (就是 survivor)
        * old generation 大小与已使用比例
        
    - jmap -histo pid  （输出 pid 的JVM进程的所有对象的信）
    - jmap -histo pid | head -20  (输出前20个实例化最多的对象的信息)
    - jmap -dump:file=/home/heap.hprof pid (堆信息转储到文件，下载后用 VisiaulVM 分析)
    
```
jmap 命令把整个 JVM 的工作线程停止 full gc，在线上是不能随便使用的，特别是堆设置的特别大的时候，
完成这个转储蓄需要一定时间，因此在高可用环境可使用，或者加上 HeapDumpOnOutOfMemoryError
```
    
- jstack 查看JVM线程的运行状况
    - jstack pid  命令行输出
    - jstack pid >/home/thread.log  转储到文件
    - 常用于排除死锁的情况
    
- jstat 查看JVM 资源使用，性能，GC 情况
    - jstat -class pid 查看已经加载的类
    - jstat -gc pid  查看当前堆中各个区域的使用情况，GC情况
    - jstat -gcutil pid  查看当前GC情况

- jinfo  查看JVM 配置的参数
    - jinfo pid 最小最大堆的参数，新生代，老年代，eden, survivor 的各种配置参数


### JVM 常见线上错误与排查方法

- OutOfMemoryError: GC overhead limit exceeded
    * 原因：程序基本上耗尽了所有的可用内存, GC也清理不了
    * 表现：GC花费的时间超过 98%, 并且GC回收的内存少于 2%
    
    * 排查方法
        * 1 在线上 jmap -dump:file=/home/heap.hprof pid
        * 2 在本地把该文件导入到 VisualVM 等分析工具里面，查看哪个类的对象比较多
        * 3 排查产生较多对象的代码的逻辑，对该方法调试压测
        * 4 本地代码复现，程序本地运行压测，用 Visual GC 工具查看 GC 情况

- OutOfMemoryError: Java heap space
    * 堆内存中的空间不足以存放新创建的对象，就会抛出该异常
    * 堆内存使用量达到最大内存限制, 就会抛出该异常
    * 原因：堆中内存占用太多，没有被清理掉
    
    * 排查方法
        * 1 有可能是堆设置的太小，可以尝试把堆调大，如果每能解决
        * 2 堆设置大一点有可能只是推迟这个错误的发生，代码有问题迟早会有这个问题爆发的
        * 3 本质上也是有些类的对象创建太多，占用内存，没有被清理，方式跟上面的一样
    

