### Thread.join() yield()方法

- **[join 方法目的是让调用该方法的线程先执行完，再到其他线程执行，让并发的执行变成串行的](#)**
```

    hread  t1 = new Thread();
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


### ReentreenLock与Condition

```
private static final Lock LOCK = new ReentrantLock();//构造方法是有参数的，true 就是公平锁，false是非公平锁，默认是非公平
private static final Condition CONDITION = LOCK.newCondition();

LOCK.lock();
try {	
    // 1
    CONDITION.await();//线程 释放锁之后进入休眠状态，让出CPU,不会往下执行了，需要等待通知唤醒
    // 2
} finally{
    LOCK.unlock();
}




LOCK.lock();
//进入这一步必须再次持有锁对象, ReentrantLock 这个名称也说明了可重入锁
try {	
    // 3
    CONDITION.signal();//唤醒其他等待该条件的锁的线程
    // 4
} finally{
    LOCK.unlock();
}
执行顺序：1-->3-->4-->2
```

- 生产者消费者模式
```
private static final Lock LOCK = new ReentrantLock();
private static final Condition CONSUMER_CONDITION = LOCK.newCondition();
private static final Condition PRODUCER_CONDITION = LOCK.newCondition();
//消费者线程
try {
    LOCK.lock();
    while (STORAGE == null) { // 仓库为空的时候不消费
        CONSUMER_CONDITION.await();//执行到这里就释放锁，线程休眠，让出CPU
    }
    STORAGE = null; // 不为空的时候 消费，就是把值设置为 null
    PRODUCER_CONDITION.signal();
}
finally {
    LOCK.unlock();
}
//生产者线程
try {
    LOCK.lock();
    while (STORAGE != null) { // 仓库有东西的时候不生产
        PRODUCER_CONDITION.await();//执行到这里就释放锁，线程休眠，让出CPU
    }
    STORAGE = value; // 仓库为空的时候生产
    CONSUMER_CONDITION.signal();
}
finally {
    LOCK.unlock();
}
```

- 公平锁，非公平锁
- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/公平锁.png)

- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/队列与同步器.png)


- 队列同步器
```
public abstract class AbstractQueuedSynchronizer  extends AbstractOwnableSynchronizer{
    protected final int getState() {	return state;  }
    protected final void setState(int newState) {    state = newState; }
    
    protected final boolean compareAndSetState(int expect, int update) {
        return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
    }
}
    同步器的主要使用方式是继承,子类通过覆盖3个方法来实现同步操作
public class ReentrantLock implements Lock{
    private final Sync sync;
    abstract static class Sync extends AbstractQueuedSynchronizer
}

public class ThreadPoolExecutor extends AbstractExecutorService {
    class Worker  extends AbstractQueuedSynchronizer  implements Runnable{
        public void lock()        { acquire(1); 	//这里的参数1实际上没有用，方法是用 CAS(0,1) }
        public void unlock()      { release(1); }
    }
}
```

```
ReentrantLock
Condition
ReentrantReadWriteLock
CountDownLatch 
等并发类都是由这个队列同步器 AbstractQueuedSynchronizer 实现得
```

- - ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/同步器原理.png)

- **[同步器依赖内部的同步队列（一个FIFO双向队列）来完成同步状态的管理](#)**
```
当前线程获取同步状态失败时，同步器会将当前
线程以及等待状态等信息构造成为一个节点（Node）并将其加入同步队列，同时会阻塞当前线程，当同步状态释放时，
会把首节点中的线程唤醒，使其再次尝试获取同步状态
```
