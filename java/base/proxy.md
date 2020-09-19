- JDK的动态代理
    - 就是程序运行的过程中，根据被代理的接口来动态生成代理类的class文件，并加载运行的过程
- JDK 动态代理的写法
    - JDK 动态代理需要这几部分内容：接口、实现类、代理对象。
    - 代理对象需要继承 InvocationHandler，代理类调用方法时会调用 InvocationHandler 的 invoke 方法。
    - Proxy 是所有代理类的父类，它提供了一个静态方法 newProxyInstance(目标接口，代理对象) 动态创建代理对象
![proxy](https://github.com/caesar-empereur/read-book/blob/master/photo/Jdk-proxy.png)
- 为什么 JDK 动态代理要基于接口实现？而不是基于继承来实现？
    - 因为 JDK 动态代理生成的对象默认是继承 Proxy ，Java 不支持多继承，所以 JDK 动态代理要基于接口来实现
- JDK 动态代理中，目标对象调用自己的另一个方法，会经过代理对象么？
    - 内部调用方法使用的对象是目标对象本身，被调用的方法不会经过代理对象
    
- **[动态代理解决了什么问题？]()**
    - 它是一个代理机制,可以看作是对调用目标的一个包装，这样我们对目标代码的调用不是直接发生的，而是通过代理完成
    - 通过代理可以让调用者与实现者之间解耦。
    - 比如进行 RPC 调用，通过代理，可以提供更加友善的界面；还可以通过代理，做一个全局的拦截器
- 动态代理和反射的关系是什么？
    - 反射可以用来实现动态代理，但动态代理还有其他的实现方式，比如 ASM（一个短小精悍的字节码操作框架）、cglib 等
- Spring 动态代理的实现方式
    - Spring 动态代理的实现方式有两种：cglib 和 JDK 原生动态代理
- JDK 原生动态代理和 cglib 有什么区别?
    - JDK 原生动态代理是基于接口实现的,继承 Proxy，不需要添加任何依赖
    - cglib 不需要实现接口，可以直接代理普通类
- cglib 可以代理任何类这句话对吗？为什么？
    - 这句话不完全对，因为 cglib 只能代理可以没有 final 修饰的普通类。
    - 因为 cglib 的底层是通过继承代理类的子类来实现动态代理的，所以不能被继承类无法使用 cglib