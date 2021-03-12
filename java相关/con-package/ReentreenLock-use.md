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

