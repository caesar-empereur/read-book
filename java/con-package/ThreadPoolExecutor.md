- ThreadPoolExecutor
```
public class ThreadPoolExecutor extends AbstractExecutorService {
private final AtomicInteger atomicInteger = new AtomicInteger(-567870912);
private final BlockingQueue<Runnable> workQueue;
private final ReentrantLock mainLock = new ReentrantLock();
private final HashSet<Worker> workers = new HashSet<Worker>();
private final Condition termination = mainLock.newCondition();
private volatile ThreadFactory threadFactory;
private volatile RejectedExecutionHandler handler = new AbortPolicy();
private volatile boolean allowCoreThreadTimeOut;
private volatile int corePoolSize, int maximumPoolSize, long keepAliveTime;

public void execute(Runnable command) {
int c = atomicInteger.get();	//c=-567870912
if (workerCountOf(c) < corePoolSize) { // 1当前池中线程数量少于核心线程数，新建线程执行任务
    if (addWorker(command, true))
        return;
    c = atomicInteger.get();
}
if (isRunning(c) && workQueue.offer(command)) { // 2.核心池已满，但任务队列未满，添加到队列中
    int recheck = atomicInteger.get();
    if (! isRunning(recheck) && remove(command))
        reject(command);
    if (workerCountOf(recheck) == 0)
        addWorker(null, false);
    return;
}
if (!addWorker(command, false)) //3.核心池已满，队列已满，试着创建一个新线程
    //如果创建新线程失败了，说明线程池被关闭或者线程池完全满了，拒绝任务
    reject(command);
}

private boolean addWorker(Runnable firstTask, boolean core) {
    retry:
    for (;;) {
        int c = atomicInteger.get();
        int rs = runStateOf(c);
  //线程池是停止状态并且队列不为空，加入的线程任务为空，则返回执行不成功
        if (rs >= SHUTDOWN && ! (rs == SHUTDOWN && firstTask == null && ! workQueue.isEmpty()))
            return false;
        for (;;) { //自旋锁的应用
            int wc = workerCountOf(c); //获取池中工作线程数，大于默认容量或者核心线程数，则不能添加到 worker 线程
            if (wc >= CAPACITY || wc >= corePoolSize)
                return false;
            if (atomicInteger.getAndIncrement())
                break retry;
            c = atomicInteger.get(); 
            if (runStateOf(c) != rs)
                continue retry; //如果线程池状态发生改变，回到最外层循环重新开始
        }
    }
    boolean workerStarted = false, workerAdded = false;
    Worker w = null;
    try {
        w = new Worker(firstTask);
        final Thread t = w.thread;
        if (t != null) {
            final ReentrantLock mainLock = this.mainLock;
            mainLock.lock();
            try {
                int rs = runStateOf(atomicInteger.get());
                    //线程池是运行状态，才能把 worker 线程添加到 worker 集合中
                if (rs < SHUTDOWN || (rs == SHUTDOWN && firstTask == null)) {
                    workers.add(w);
                    int s = workers.size();
                    if (s > largestPoolSize)
                        largestPoolSize = s; //更新最大线程数为 worker 集合size
                    workerAdded = true;
                }
            } finally {
                mainLock.unlock();
            }
            if (workerAdded) {
                t.start();   workerStarted = true; //启动线程，这里是调用 runWorker()方法
            }
        }
    } finally {
        if (! workerStarted)
            addWorkerFailed(w);
    }
    return workerStarted;
}

private void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    Runnable task = w.firstTask;
    w.firstTask = null;
    w.unlock(); // allow interrupts
    boolean completedAbruptly = true;
    try {
         //如果传进来的worker线程是空的，则从队列中拿出线程执行
        while (task != null || (task = getTask()) != null) {
            //规定时间内没有拿到线程，说明队列为空，当前线程池中不需要
            //那么多的线程存活可以把多余核心线程数的线程停止
            w.lock();
            if (//线程池不是运行状态的，中断线程)
                wt.interrupt();
            try {  task.run(); } //这里就是真正的执行线程
      finally { task = null; w.completedTasks++;  w.unlock(); }
        }
        completedAbruptly = false;
    } finally {
        processWorkerExit(w, completedAbruptly);
    }
}
}
```

- ThreadPoolExecutor 参数解释
```

corePoolSize：         核心线程数，会一直存活，即使没有任务，线程池也会维护线程的最少数量
maximumPoolSize： 线程池维护线程的最大数量
keepAliveTime：      线程池维护线程所允许的空闲时间，当线程空闲时间达到keepAliveTime，该线程会退出，直到线程数量等于corePoolSize。
如果allowCoreThreadTimeout设置为true，则所有线程均会退出直到线程数量为0。
unit： 线程池维护线程所允许的空闲时间的单位、可选参数值为：TimeUnit中的几个静态属性：
workQueue： 线程池所使用的缓冲队列，常用的是：java.util.concurrent.ArrayBlockingQueue、LinkedBlockingQueue、SynchronousQueue
handler： 线程池中的数量大于maximumPoolSize，对拒绝任务的处理策略，默认值ThreadPoolExecutor.AbortPolicy()。

public class Executors {
    public static ExecutorService newCachedThreadPool() {
        return new ThreadPoolExecutor(0, Integer.MAX_VALUE, 60L, TimeUnit.SECONDS, new SynchronousQueue<Runnable>());
    }
    public static ExecutorService newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads, 0L, TimeUnit.MILLISECONDS,  new LinkedBlockingQueue<Runnable>());
    }
    public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
       return new ThreadPoolExecutor(corePoolSize, Integer.MAX_VALUE, 0L, NANOSECONDS,  new DelayedWorkQueue<Runnable>());
    }
    public static ExecutorService newSingleThreadExecutor() {
        return new ThreadPoolExecutor(1, 1,  0L, TimeUnit.MILLISECONDS,  new LinkedBlockingQueue<Runnable>());
    }
}
public interface ScheduledExecutorService extends ExecutorService {
    ScheduledFuture<?> schedule(Runnable command, long delay, TimeUnit unit);
    <V> ScheduledFuture<V> schedule(Callable<V> callable,  long delay, TimeUnit unit);
    ScheduledFuture<?> scheduleAtFixedRate(Runnable command,  long initialDelay,  long period,  TimeUnit unit);
    ScheduledFuture<?> scheduleWithFixedDelay(Runnable command, long initialDelay, long delay, TimeUnit unit);
}
```
