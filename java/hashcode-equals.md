- hashcode 和 equals 的关系
    - equals 相等的对象他们的 hashcode 一定是相等的
    - hashcode 相等的对象 equals 不一样相等
    - equals 不相等的不一定要返回不同的 hashcode, 但是返回不同 hashcode 可以提高哈希表的性能
    - 这2个方法主要用在 Set, HashSet, Map HashMap 集合中，用来将一个对象作为 key 存放到集合中
```
一个对象作为 key 算出的hashcode是用来计算出在map中的下标，如果 equals 是一样的，说明对象是一样的
他们的 hashcode 必须算出来是一样才能定位到一样的 map 下标，继而在下表的链表上判断到 已经存在
equals 一样的 对象，这样 map 才能判断到已经存在一样的 key 了

```

- 重写 equals 与重写 hashcode 的关系

```
如果重写了 equals，没有重写 hashcode, 会导致 equals 一样的 hashcode 不一样
这个对象一样的 作为 key 在 map 里面会定位到不同的下标，2个 相等对象的 key 居然可以存到 map 里面
破坏了 map 的 key 不能重复的规则

```

- 为什么 String Integer 这些类是 final 的？
```
final 限定有一部分原因是为了防止重写 hashcode 跟 equals，导致 equals 一样的 hashcode 不一样
这样结果就是同一个对象作为 key 存放到 集合中，put 进去了，但是 get 的时候 hashcode 不一样，
导致get出来为空
```
