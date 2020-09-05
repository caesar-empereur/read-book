```
public class ReentrantReadWriteLock implements ReadWriteLock {

    private final ReentrantReadWriteLock.ReadLock readerLock;
    private final ReentrantReadWriteLock.WriteLock writerLock;
    
    final Sync sync;
    
    public ReentrantReadWriteLock(boolean fair) {
        sync = fair ? new FairSync() : new NonfairSync();
        readerLock = new ReadLock(this);
        writerLock = new WriteLock(this);
    }
    
    public WriteLock writeLock() { return writerLock; }
    public ReadLock  readLock()  { return readerLock; }
    
    static class ReadLock implements Lock{
        private final Sync sync;
        
        /*
        读锁的获取 是先判断当前有无写锁，没有写锁的话则 当前读锁 加 1 ，获取成功
        有写锁并且不是自己的话 则将当前线程变成 Node
        加入 AQS 队列等待被唤醒后重新获取，相当于等待写锁操作完，避免写锁饥饿
        */
        public void lock() {
            if (tryAcquireShared(1) < 0) {
                doAcquireShared(1);
            }
        }
        
        final int tryAcquireShared(int unused) {
            Thread current = Thread.currentThread();
            int c = getState();
            if (exclusiveCount(c) != 0 && getExclusiveOwnerThread() != current)
                return -1;  //当前有写锁的线程并且该线程不是自己，获取读锁失败
            int r = sharedCount(c);
            //没有写锁，读锁计数器 CAS 加1成功的话读锁获取成功
            if (!readerShouldBlock() && r < MAX_COUNT && compareAndSetState(c, c + SHARED_UNIT)) {
                if (r == 0) { //当前没有其他获取读锁的线程
                    firstReader = current;
                    firstReaderHoldCount = 1;
                } else if (firstReader == current) { //当前线程是第一个获取读锁的线程
                    firstReaderHoldCount++;
                } else {
                    HoldCounter rh = cachedHoldCounter;
                    if (rh == null || rh.tid != getThreadId(current))
                        cachedHoldCounter = rh = readHolds.get();
                    else if (rh.count == 0)
                        readHolds.set(rh);
                    rh.count++;
                }
                return 1;
            }
            // 这里 CAS 加1失败的话进行补偿操作，其实是 自旋中 对读锁 CAS 加1，成功则返回
            return fullTryAcquireShared(current);
        }
                
        private void doAcquireShared(int arg) {
            final Node node = addWaiter(Node.SHARED); //作为一个节点加入队列
            boolean failed = true;
            try {
                boolean interrupted = false;
                for (;;) {
                    //在队列中自旋，一直等到当前节点是第二个，获取读锁，成功则返回
                    final Node p = node.predecessor();
                    if (p == head) { //如果当前节点是头节点的下一个，
                        int r = tryAcquireShared(arg);
                        if (r >= 0) {
                            setHeadAndPropagate(node, r);
                            p.next = null; // help GC
                            if (interrupted)
                                selfInterrupt();
                            failed = false;
                            return;
                        }
                    }
                    if (shouldParkAfterFailedAcquire(p, node) && parkAndCheckInterrupt())
                        interrupted = true;
                }
            } finally {
                if (failed)
                    cancelAcquire(node);
            }
        }
        
        /*
        读锁的释放，实际就是读锁的个数 在自旋CAS 操作减去 1，成功则唤醒队列中的写锁
        没有获取过读锁却释放会报错
        */
        public void unlock() {
            if (tryReleaseShared(1)) {
                doReleaseShared();
                return true;
            }
            return false;
        }
        
        final boolean tryReleaseShared(int unused) {
            Thread current = Thread.currentThread();
            if (firstReader == current) {
                if (firstReaderHoldCount == 1)
                    firstReader = null;
                else
                    firstReaderHoldCount--;
            } else {
                HoldCounter rh = cachedHoldCounter;
                if (rh == null || rh.tid != getThreadId(current))
                    rh = readHolds.get();
                int count = rh.count;
                if (count <= 1) {
                    readHolds.remove();
                    if (count <= 0)
                        throw unmatchedUnlockException();
                }
                --rh.count;
            }
            for (;;) {
                int c = getState();
                int nextc = c - SHARED_UNIT;
                if (compareAndSetState(c, nextc))
                    return nextc == 0;
            }
        }
        
        // 自旋中进行  头节点的唤醒操作，应该是读锁释放后需要唤醒
        // 写锁，是否有写锁的判断依据是 AQS 队列中头节点的状态是否为需要唤醒的
        private void doReleaseShared() {
            for (;;) {
                Node h = head;
                if (h != null && h != tail) {
                    int ws = h.waitStatus;
                    if (ws == Node.SIGNAL) { //如果队列中的头节点是需要唤醒的状态
                        if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
                            continue;//进行 CAS 置换设置头节点为 0 唤醒
                        unparkSuccessor(h); // 唤醒头节点的线程
                    }
                    else if (ws == 0 && !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                        continue;
                }
                if (h == head) //如果头节点改变了，继续自旋
                    break;
            }
        }
    }
    
    static class WriteLock implements Lock{
        private final Sync sync;
    
        /* 写锁的获取，如果当前有读锁，或者当前写锁不是自己的话，获取失败
            当前没有读锁或者写锁，则写锁 加1，获取成功
            写锁加1 失败则 进去队列
        */
        public void lock() {
            if (!tryAcquire(1) && acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
                selfInterrupt();
        }
        
        final boolean tryAcquire(int acquires) {
            Thread current = Thread.currentThread();
            int c = getState();
            int w = exclusiveCount(c);
            if (c != 0) {
                // (Note: if c != 0 and w == 0 then shared count != 0)
                if (w == 0 || current != getExclusiveOwnerThread())
                    //如果当前有读锁，或者当前写锁不是自己的话，获取失败
                    return false;
                if (w + exclusiveCount(acquires) > MAX_COUNT)
                    throw new Error("Maximum lock count exceeded");
                setState(c + acquires);
                //当前没有读锁或者写锁，则写锁 加1，获取成功
                return true;
            }
            if (writerShouldBlock() || !compareAndSetState(c, c + acquires))
                return false;
            setExclusiveOwnerThread(current);
            return true;
        }
        
        /*
        写锁加1 失败则 进入队列，一直自旋等待直到当前节点为 第二个节点，再次获取写锁
        成功则返回，失败则中断
        */
        final boolean acquireQueued(final Node node, int arg) {
            boolean failed = true;
            try {
                boolean interrupted = false;
                for (;;) {
                    final Node p = node.predecessor();
                    if (p == head && tryAcquire(arg)) {
                        setHead(node);
                        p.next = null; // help GC
                        failed = false;
                        return interrupted;
                    }
                    if (shouldParkAfterFailedAcquire(p, node) &&
                        parkAndCheckInterrupt())
                        interrupted = true;
                }
            } finally {
                if (failed)
                    cancelAcquire(node);
            }
        }
        /*
        写锁的释放，当前线程必须是获得写锁，否则报错
        释放成功后唤醒队列中的第一个线程, 锁状态减 1
        */
        public void unlock() {
            if (tryRelease(1)) {
                Node h = head;
                if (h != null && h.waitStatus != 0)
                    unparkSuccessor(h);
                return true;
            }
            return false;
        }
        
        protected final boolean tryRelease(int releases) {
            if (!isHeldExclusively())
                throw new IllegalMonitorStateException();
            int nextc = getState() - releases;
            boolean free = exclusiveCount(nextc) == 0;
            if (free)
                setExclusiveOwnerThread(null);
            setState(nextc);
            return free;
        }
    }
    
}
```
- ReentrantReadWriteLock 的锁获取总结
    - 读锁与写锁在获取时有另一个锁在执行，则需要等待对方释放
    - 读锁的获取
        - 没有写锁，读锁计数器 CAS 加1成功的话读锁获取成功
        - CAS 加1失败的话进行补偿操作，其实是 自旋中 对读锁 CAS 加1，成功则返回
    - 读锁的释放
        - 读锁的计数 在自旋CAS 操作减去 1，成功则唤醒队列中的写锁
    - 写锁的获取
        - 当前没有读锁或者写锁，则写锁 加1，获取成功
        - 写锁加1 失败则进入队列，一直自旋直到当前节点为 第二个节点，再次获取写锁 成功则返回，失败则中断
    - 写锁的释放
        - 释放成功后唤醒队列中的第一个线程, 锁计数减 1
        
- ReentrantReadWriteLock 的总结思路
    - 读锁与写锁的获取都是对锁计数加1，成功则返回
    - 读锁获取只需要等待一个写锁释放，写锁获取则需要等待所有读锁释放
    - 读锁释放后需要唤醒队列的写锁(如果有)，写锁释放后需要唤醒队列的第一个锁
