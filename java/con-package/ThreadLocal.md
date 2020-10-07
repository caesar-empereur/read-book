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
- ![innodb](https://github.com/caesar-empereur/read-book/blob/master/photo/ThreadLocal.png)

```
key 为ThreadLocal，在同一个线程对象中，多次set操作设置的key是同一个，是为了确保同一个key能
把value覆盖掉，同一个key的原因是变量一直用的是为new 出来的同一个对象
```

- 内存泄漏问题
```
实际上 ThreadLocalMap 中使用的 key 为 ThreadLocal 的弱引用，弱引用的特点是，如果这个对象只存在弱引用，
那么在下一次垃圾回收的时候必然会被清理掉。
所以如果 ThreadLocal 没有被外部强引用的情况下，在垃圾回收的时候会被清理掉的，这样一来 ThreadLocalMap中使用这个 
ThreadLocal 的 key 也会被清理掉。但是，value 是强引用，不会被清理，这样一来就会出现 key 为 null 的 value。
ThreadLocalMap实现中已经考虑了这种情况，在调用 set()、get()、remove() 方法的时候，会清理掉 key 为 null 的记录。
如果说会出现内存泄漏，那只有在出现了 key 为 null 的记录后，没有手动调用 remove() 方法，
并且之后也不再调用 get()、set()、remove() 方法的情况
```
