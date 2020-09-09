- 使用spring框架的好处是什么？
    - 不用自己手动写 servlet 程序，spring已经封装好了
    - 实现了mvc框架
    - 实现了orm，dao, 例如JPA, jdbc
    - 事务管理
    - 面向切面的编程(AOP)
- 什么是Spring的依赖注入？
    - 不用创建对象，而只需要描述它如何被创建，以及在那些地方需要使用这些对象
- 有哪些不同类型的依赖注入方式？
    - 构造器依赖注入
    - Setter方法注入
- Spring Bean的作用域有哪些?
    - 单例singleton
        - 默认情况下都是单例的，它要求在每个spring 容器内不论你请求多少次这个实例，都只有一个实例
        - 单例特性是由beanfactory本身维护的
    - **[单例bean是线程安全的吗?]()**
        - Spring框架不对单例的bean做任何多线程的处理
        - 而实际上,大多数spring bean没有可变状态(例如服务和DAO的类),这样的话本身是线程安全的
        - 如果您的bean有可变状态(例如视图模型对象),这就需要你来确保线程安全
        - 解决方案是改变bean Scope，可变的bean从“单例”到“原型”
    - 原型prototype
        - 这个bean的实例和单例相反,一个新的请求产生一个新的bean实例
    - 请求request
        - 在一个请求内,将会为每个web请求的客户端创建一个新的bean实例
        - 一旦请求完成后,bean将失效，然后被垃圾收集器回收掉
- spring不同的bean自动注入模式?
    - byName
        - 基于bean的名称的依赖项注入。当自动装配在bean属性,用属性名搜索匹配的bean定义配置文件
    - byType
        - 基于bean的类型的依赖项注入。当在bean属性需要自动注入时,使用属性类的类型来搜索匹配的bean定义配置文件
    - constructor
        - 注入bean时,它在所有构造函数参数类型中寻找匹配的构造函数的类类型参数,然后进行自动注入
- spring 是如何解决循环依赖的？
    - bean 生命周期，bean 是怎么来的，BeanDefinition

- **[spring bean 的生命周期]()**
    - **[实例化, 完了之后放到一个 map 中]()**
        - 容器从 xml 或者配置类中读取 bean 的定义，生成一个 BeanDefinition 并实例化
        - 对于BeanFactory容器是懒加载，获取bean的时候发现没有才会 进行实例化
        - 对于ApplicationContext容器，当容器启动结束后，便实例化所有的bean
        - 实例化对象被包装在BeanWrapper对象中
    - **[属性赋值]()**
        - Spring根据bean的定义 BeanDefinition 填充所有的属性(**[循环依赖]()**)
        - 并且通过BeanWrapper提供的设置属性的接口完成依赖注入
    - **[初始化]()**
        - Spring会检测该 bean 是否实现了xxxAware接口, 并将相关的xxxAware实例注入给bean
        - 检查 bean 是否实现了BeanPostProcessor, InitializingBean 接口，调用对应方法
    - **[销毁]()**
        - 经过以上的工作后，Bean将一直驻留在应用上下文中给应用使用，直到应用上下文被销毁
        - 销毁的时候也可以实现接口DispostbleBean，做一些处理逻辑
```
@Component
public class A {
  private B b;
}
@Component
public class B {
  private A a;
}

```
- **[spring 是如何解决循环依赖的]()**
    - 首先，循环依赖是发生在 bean 的生命周期当中
    - spring bean 的实例化赋值包括 当前对象实例化和对象属性的实例化
    - 过程如下
        - 首先Spring尝试通过ApplicationContext.getBean()方法获取A对象的实例,发现没有，就创建A
        - 发现A依赖了B，递归调用 getBean() 方法获取B，发现B没有，创建B
        - 此时A，B对象都有了(半成品)，但是还没有属性赋值
        - 创建B的时候发现依赖了A，A实例已经有了，因此A返回，B的属性A就设置进去
        - B实例和它的属性弄完之后到了A，A 属性依赖B，就去 getBean()把B拿出来设置到A里面
        - A，B 对象在半成品的时候，其实是一个 ObjectFactory 对象
