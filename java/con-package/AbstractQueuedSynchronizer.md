- 队列同步器 AbstractQueuedSynchronizer
```
public abstract class AbstractQueuedSynchronizer  extends AbstractOwnableSynchronizer{
    protected final int getState() {	return state;  }
    protected final void setState(int newState) {    state = newState; }
    
    protected final boolean compareAndSetState(int expect, int update) {
        return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
    }
    
    public final void acquire(int arg) {
        /*
        调用的是 NonfairSync.tryAcquire() 方法，如果还是失败的话 acquireQueued
        acquireQueued() 就是把当前线程加入竞争队列，自旋将自己设置为竞争队列头节点
        成功的话就获得锁
        */
        if (!tryAcquire(arg) && acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
            selfInterrupt();
    }
    
    public final boolean release(int arg) {
        if (tryRelease(arg)) {
            Node h = head;
            if (h != null && h.waitStatus != 0)
                unparkSuccessor(h);
            return true;
        }
        return false;
    }
    
    //释放锁，前提是当前线程获得了锁状态，然后把队列状态重置为 0
    protected final boolean tryRelease(int releases) {
        int c = getState() - releases;
        if (Thread.currentThread() != getExclusiveOwnerThread())
            throw new IllegalMonitorStateException();
        boolean free = false;
        if (c == 0) {
            free = true;
            setExclusiveOwnerThread(null);
        }
        setState(c);
        return free;
    }
}
    同步器的主要使用方式是继承,子类通过覆盖3个方法来实现同步操作
public class ReentrantLock implements Lock{

    private final Sync sync;

    public ReentrantLock() {
        sync = new NonfairSync();
    }
    
    public void lock() {
        NonfairSync.lock(); // 这里调用的也是 NonfairSync.tryAcquire(1);
    }
    
    public void unlock() {
        AbstractQueuedSynchronizer.release(1);
    }
    
    public boolean tryLock() {
        return NonfairSync.tryAcquire(1);
    }
    
    public Condition newCondition() {
        return new ConditionObject();
    }
    //非公平锁
    class NonfairSync extends Sync {
        final void lock() {
            /*
           非公平锁的获得是先将当前线程 CAS 置换，成功的话直接获得锁,
            */
            if (compareAndSetState(0, 1))
                setExclusiveOwnerThread(Thread.currentThread());
            else // 不成功再加入竞争队列，自旋设置自己为队列头节点来获得锁
                acquire(1);
        }

        final boolean tryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            int c = getState();
            if (c == 0) {//同步器当前没有线程获得同步状态(进入锁)，设置当前线程为独占了锁的状态
                if (compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0) // overflow
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
    }
    
    //公平锁
    class FairSync extends Sync {
        final void lock() {
            acquire(1); // 调用的是 AbstractQueuedSynchronizer.acquire()
            //公平锁的获得是直接加入竞争队列，自旋设置自己为队列头节点来获得锁
        }
    
        //尝试获取锁状态
        final boolean tryAcquire(int acquires) {
            Thread current = Thread.currentThread();
            int c = getState();
            //只有是无锁状态才能获得锁, 获得锁状态是通过 CAS 置换
            if (c == 0) {
                if (!hasQueuedPredecessors() && compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            //如果当前线程已经是获得锁状态，则返回
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0)
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
    }
    
    abstract class Sync extends AbstractQueuedSynchronizer{
        abstract void lock();
    }
}
```



```
class ConditionObject implements Condition {

    private transient Node firstWaiter;
    private transient Node lastWaiter;

    // 将当前线程 作为一个 Node 节点加入 condition 等待队列
    private void await() {
        Node t = lastWaiter;
        Node node = new Node(Thread.currentThread(), Node.CONDITION);
        if (t == null)
            firstWaiter = node;
        else
            t.nextWaiter = node;
        lastWaiter = node;
    }
    
    // 通知等待队列的线程，默认是通知队列的第一个，把第一个节点从链表里面移除出来
    public final void signal() {
        if (!isHeldExclusively())
            throw new IllegalMonitorStateException();
        Node first = firstWaiter;
        do {
            if ( (firstWaiter = first.nextWaiter) == null)
                lastWaiter = null;
            first.nextWaiter = null;
        } while (!transferForSignal(first) && (first = firstWaiter) != null);
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

- 公平锁，非公平锁
- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/公平锁.png)

- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/队列与同步器.png)

- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/同步器原理.png)


- ReentrantLock 队列同步器锁的总结
    - 队列同步器的数据结构
        - 队列同步器是通过 **[2 种队列](#)**, 和一个**[当前独占锁的线程变量](#)** 来达到线程的竞争执行和等待，和定向通知的
        - 2 种队列一种是 **[竞争队列](#)**，在 AbstractQueuedSynchronizer 里面维护
        - **[竞争队列的头节点是获得锁的线程](#)**，同时也会存在当前独占锁的线程变量 里面
        - 2 种队列另一种是 **[等待队列](#)**，在 ConditionObject 里面维护，Lock.newCondition() 返回的就是这个对象
        - 这 2 种队列实际上在代码上没有引用或者关联关系
    - 线程获得锁的过程 **[lock.lock()](#)**
        - **[公平锁](#)**：将当前线程封装为 Node 节点，**[加入竞争队列，自旋设置自己为队列头节点来获得锁](#)**
        - **[非公平锁](#)**：锁的获得是先 **[将当前线程 CAS 置换](#)** (置换同步器的一个变量)，成功的话直接获得锁, 不成功再加入竞争队列
    - 当前线程进入等待状态 **[condition.await()](#)**
        - 将当前线程 作为一个 Node 节点加入 condition 等待队列
    - 线程的定向通知 **[condition.signal()](#)**
        - 默认是通知队列的第一个，把第一个节点从链表里面移除出来
    - 线程释放锁的过程 **[lock.unlock()](#)**
        - 竞争队列的头节点从队列释放，当前独占锁的线程变量置为空
        




```
public class ThreadPoolExecutor extends AbstractExecutorService {
    class Worker  extends AbstractQueuedSynchronizer  implements Runnable{
        public void lock()        { acquire(1); 	//这里的参数1实际上没有用，方法是用 CAS(0,1) }
        public void unlock()      { release(1); }
    }
}
```
