- 队列同步器
```
public abstract class AbstractQueuedSynchronizer  extends AbstractOwnableSynchronizer{
    protected final int getState() {	return state;  }
    protected final void setState(int newState) {    state = newState; }
    
    protected final boolean compareAndSetState(int expect, int update) {
        return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
    }
    
    public final void acquire(int arg) {
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
            if (compareAndSetState(0, 1))
                setExclusiveOwnerThread(Thread.currentThread());
            else
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

- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/同步器原理.png)

- **[同步器依赖内部的同步队列（一个FIFO双向队列）来完成同步状态的管理](#)**
```
当前线程获取同步状态失败时，同步器会将当前
线程以及等待状态等信息构造成为一个节点（Node）并将其加入同步队列，同时会阻塞当前线程，当同步状态释放时，
会把首节点中的线程唤醒，使其再次尝试获取同步状态
```
