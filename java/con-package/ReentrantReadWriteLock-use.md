```
public class MyTask {

    private ReentrantReadWriteLock lock = new ReentrantReadWriteLock();
    
    public void read() {
        try {
            lock.readLock().lock();
            System.out.println(Thread.currentThread().getName() + " start");
            Thread.sleep(10000);
            System.out.println(Thread.currentThread().getName() + " end");
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            lock.readLock().unlock();
        }
    }
}

public class ReadReadTest {

    public static void main(String[] args) {
        final MyTask myTask = new MyTask();
        
        Thread t1 = new Thread(new Runnable() {

            @Override
            public void run() {
                myTask.read();
            }
        });
        t1.setName("t1");
        
        Thread t2 = new Thread(new Runnable() {

            @Override
            public void run() {
                myTask.read();
            }
        });
        t2.setName("t2");
        
        t1.start();
        t2.start();
    }
}

t2 start
t1 start
t1 end
t2 end
```
