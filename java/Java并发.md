### Thread.join() yield()方法

- **[join 方法目的是让调用该方法的线程先执行完，再到其他线程执行，让并发的执行变成串行的](#)**
```

    Thread  t1 = new Thread();
    Thread  t2 = new Thread();
    t1.start();
    t1.join(); // t1 执行完才轮到 t2 执行
    t2.start();
    
    t1.join(long time); //让t1 先执行 time 时间后 就让多线程交替执行了
    
    原理
    public class Thread{
        public final void join() throws InterruptedException {
            wait(); //调用的是 Object 类里面的 wait() 方法
        }
    }
```

- **[yield 让出CPU执行器的当前使用权](#)**
```
    yield意味着放手，放弃，投降。
    一个调用yield()方法的线程对调度器的一个暗示，表示愿意让出CPU执行器的当前使用权，
    但是调度器可以自由忽略这个提示但是，实际中无法保证yield()达到让步目的,
    因为让步的线程还有可能被线程调度程序再次选中
    
    yield()从未导致线程转到等待/睡眠/阻塞状态。在大多数情况下，
    yield()将导致线程从运行状态转到可运行状态，但有可能没有效果
```

- **[Object 的 wait(), notify(), join() 方法 都是 native 方法](#)**

### JAVA死锁
```
    public Object lock1 = new Object();
    public Object lock2 = new Object();
    
    synchronized (lock1) {
        synchronized (lock2){
        //
        }
    }
    synchronized (lock2) {
        synchronized (lock1){
        //
        }
    }
```
- 死锁出现的原因 : 
    ```
    因为异常原因没有释放锁，或者释放锁异常，锁里面又加锁
    ```
- 死锁的排查 :
    ```
    dump 线程信息，jstack -l pid > thread.log，如果发现有 java.lang.thread.state:BLOCKED，就是死锁
    ```
- 死锁的避免：
    ```
    避免一个线程同时获取多个锁
    避免一个线程在锁内同时占用多个资源
    锁定时设置超时时间
    数据库锁，加锁与释放锁必须在同一个连接里面
    ```


### synchronized关键字的原理

- 并大编程的3大原则：可见性，顺序性，原子性，volatile保证了可见性，**[synchronized保证了原子性](#)**
- **[synchronized用的锁是存在Java对象头里的](#)**
- **[synchronized的底层是使用操作系统的mutex lock实现的](#)**
- **[操作系统的 mutex lock 是由总线锁与缓存锁来实现的](#)**
```
总线锁：多核CPU操作同一个内存的变量时，一个CPU进入操作会发出总线锁信号，其他CPU不能操作内存

缓存锁：CPU会将内存区域加载到缓存中，修改数据时锁定缓存，写到内存的时候修改内存地址，其他CPU
回写到内存的时候发现地址失效会重新处理

```
- java 的锁底层实现
    - synchronized在 **[JVM里面是由 monitorenter 和 monitorexit 指令实现的](#)**
    - 执行monitorenter指令时，首先要去尝试获取对象的锁，成功后执行 monitorexit 后对象锁的计数器减为0

![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/synchronized.png)

- **[锁的升级：无锁-->偏向锁-->轻量级锁-->重量级锁](#)**

- 重量级锁
```
由于Java的线程是映射到操作系统的原生线程之上的，如果要阻塞或唤醒一条线程，都需要操作系统来帮忙完成，
这就需要从用户态转换到核心态中，因此状态转换需要耗费很多的处理器时间。所以synchronized是Java语言中的一个重量级操作。
在JDK1.6中，虚拟机进行了一些优化，譬如在通知操作系统阻塞线程之前加入一段自旋等待过程，避免频繁地切入到核心态中
```

- 偏向锁
    - **[偏向锁是为了在只有一个线程执行同步块时提高性能，为了让线程获得锁的代价更低而引入了偏向锁](#)**
    - **[存在多个线程竞争时，CAS 置换对象头的mark word 操作会撤销偏向锁](#)**
```
为了减少重量级锁导致的操作系统的用户态到核心态的转换，JDK1.6开始进行了锁优化。
大部分情况下，锁不存在竞争，只是单个线程的多次获得释放。
```
- 锁的升级

![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/锁的升级.png)

- JAVA 是怎么实现原子操作的？
  - 锁和循环CAS


### 线程的状态图

![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/线程状态含义.png)
![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/线程状态图.png)


