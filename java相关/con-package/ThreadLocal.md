### ThreadLocal

```
public class ThreadLocal<T> {

    public void set(T value) {
        Thread thread = Thread.currentThread();
        ThreadLocalMap  map =  thread.threadLocalMap;
        if (map != null) {
            map.set(this, value);
        }
        else {
            thread.threadLocalMap = new ThreadLocalMap(this, value);
        }
    }
    
    public T get() {
         Thread thread = Thread.currentThread();
         ThreadLocalMap map = thread.threadLocalMap;
         if (map != null) {
             ThreadLocalMap.Entry e = map.getEntry(this);
             if (e != null) {
                  return (T)e.value;
             }
         }
         T value = null;
         if (map != null)
            map.set(this, value);
         else
            thread.threadLocalMap = new ThreadLocalMap(this, value);
        return value;
    }
}


```

```
class ThreadLocalMap {
    private Entry[] table;
    private int size = 0 , INITIAL_CAPACITY = 16;
    
    class Entry extends WeakReference<ThreadLocal<T>> {
        Object value;
    }
    private void set(ThreadLocal<T> key, Object value) {
        //根据 key 的哈希值算出 table 的下标, 新建一个节点放到这个下标, 节点包含 value
    }
    private Entry getEntry(ThreadLocal<T> key) {
        //算出key在table的下标，确保该下表的节点的key 与这个key相等，返回节点
    }
}
```

- 原理
- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/conc/ThreadLocal.png)

```
key 为ThreadLocal，在同一个线程对象中，多次set操作设置的key是同一个，是为了确保同一个key能
把value覆盖掉，同一个key的原因是变量一直用的是为new 出来的同一个对象
```

- ThreadLocalMap 类内部为什么有Entry数组，而不是Entry对象？
    - 因为业务代码能new好多个ThreadLocal对象,但是一个Thread只有一个 ThreadLocalMap
    - 为了在一个Thread对象的唯一一个 ThreadLocalMap 里面存多个ThreadLocal,因此适用Entry数组
    - Entry 是存的键值对，key 是 ThreadLocal, value 是 ThreadLocal 对应的泛型值
    ```
    private static final ThreadLocal<String> THREAD_LOCAL_A = new ThreadLocal<>();
    private static final ThreadLocal<String> THREAD_LOCAL_B = new ThreadLocal<>();

    public static void main(String[] args) {
        THREAD_LOCAL_A.set("A");
        THREAD_LOCAL_B.set("B");
        test();
    }

    private static void test(){
        System.out.println("THREAD_LOCAL_A 的值 " + THREAD_LOCAL_A.get());
        System.out.println("THREAD_LOCAL_B 的值 " + THREAD_LOCAL_B.get());
    }
  
    输出
    Connected to the target VM, address: '127.0.0.1:3836', transport: 'socket'
    THREAD_LOCAL_A 的值 A
    THREAD_LOCAL_B 的值 B
    这里说明业务代码new出来的多个 ThreadLocal 放在一个线程里面的map, 是不会互相影响的
    ```
- ThreadLocal 的数据存储在jvm的哪个区域
    - 不是线程私有的栈，ThreadLocal对象也是对象，对象就在堆。只是JVM通过一些技巧将其可见性变成了线程可见
- ThreadLocal真的只是当前线程可见吗
    - 通过 InheritableThreadLocal 类可以实现多个线程访问ThreadLocal的值
- ThreadLocal 里的对象一定是线程安全的吗
    ```
    未必，如果在每个线程中ThreadLocal.set()进去的东西本来就是多线程共享的同一个对象，比如static对象，
    那么多个线程的ThreadLocal.get()获取的还是这个共享对象本身，还是有并发访问线程不安全问题
    ```

- 内存泄漏问题
```
实际上 ThreadLocalMap 中使用的 key 为 ThreadLocal 的弱引用，弱引用的特点是，如果这个对象只存在弱引用，
那么在下一次垃圾回收的时候必然会被清理掉。

正常情况下 ThreadLocal 在代码里面是根对象的话，是不存在被回收的，也就是修饰为 final, static 的根对象。
出现内存泄漏，ThreadLocal 作为 key 被回收，应该是在代码里面定义成实例变量，局部变量之类的会被回收的内存对象
```

- InheritableThreadLocal 在父子线程之间传递变量的类
  - ThreadLocal 作为线程变量传递的类，只能在一个线程上下文传递，无法跨线程传递
  - 对于要将变量传递到异步线程，子线程，需要用这个 继承的ThreadLocal
  - 子线程继承父线程的变量，与子线程自己的 ThreadLocal 本身不会冲突覆盖，因为是2个ThreadLocal
  - 子线程可以继承的变量的方式包括新建线程，线程池提交线程，不管什么方式，只要是操作系统的子线程，就满足
  ```
  private static final ThreadLocal<String> THREAD_LOCAL_IN = new InheritableThreadLocal<>();
  private static final ThreadLocal<String> THREAD_LOCAL = new ThreadLocal<>();
  private static final ExecutorService EXECUTOR_SERVICE = Executors.newFixedThreadPool(1);
  
  public static void main(String[] args) {
        THREAD_LOCAL_IN.set("A");
        System.out.println("当前线程 " + Thread.currentThread().getName());

        new Thread(new Runnable() {
            @Override
            public void run() {
                THREAD_LOCAL.set("B");
                System.out.println("当前线程 " + Thread.currentThread().getName());
                System.out.println("当前线程 获取到父线程的变量 " + THREAD_LOCAL_IN.get() + " " + THREAD_LOCAL.get());
            }
        }).start();

        EXECUTOR_SERVICE.submit(new Runnable() {
            @Override
            public void run() {
                THREAD_LOCAL.set("B");
                System.out.println("当前线程 " + Thread.currentThread().getName());
                System.out.println("当前线程 获取到父线程的变量 " + THREAD_LOCAL_IN.get() + " " + THREAD_LOCAL.get());
            }
        });
    }
  
   输出
  当前线程 main
  当前线程 Thread-0
  当前线程 获取到父线程的变量 A B
  当前线程 pool-1-thread-1
  当前线程 获取到父线程的变量 A B
  
  ```
