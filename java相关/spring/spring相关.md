- 使用spring框架的好处是什么？
    - 不用自己手动写 servlet 程序，spring已经封装好了
    - 实现了mvc框架
    - 实现了orm，dao, 例如JPA, jdbc
    - 事务管理
    - 面向切面的编程(AOP)
- 什么是Spring的控制反转与依赖注入？
    - **[依赖注入是从应用程序的角度在描述]()**，应用程序依赖容器创建并注入它所需要的外部资源
    - **[而控制反转是从容器的角度在描述]()**，由容器反向的向应用程序注入应用程序所需要的外部资源
- Spring框架的IOC是怎么样的?
    - BeanFactory，ApplicationContext 等容器是IOC框架的基础
    - BeanFactory是Spring IoC容器真实展现,负责管理各种bean
- 有哪些不同类型的依赖注入方式？
    - 构造器依赖注入
    - Setter方法注入
    - 接口注入
- Spring Bean的 **[作用域]()** (运行模式)有哪些?
    - **[单例 singleton]()**
        - 默认情况下都是单例的，它要求在每个spring 容器内不论你请求多少次这个实例，都只有一个实例
        - 单例特性是由beanfactory本身维护的
    - **[单例bean是线程安全的吗?]()**
        - Spring框架不对单例的bean做任何多线程的处理
        - 而实际上,大多数spring bean没有可变状态(例如服务和DAO的类),这样的话本身是线程安全的
        - 如果您的bean有可变状态(例如视图模型对象),这就需要你来确保线程安全
        - 解决方案是改变bean Scope，可变的bean从“单例”到“原型”
    - **[原型 prototype]()**
        - 这个bean的实例和单例相反,一个新的请求产生一个新的bean实例
    - **[请求 request]()**
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
        - *[此时A，B对象都有了(半成品)，但是还没有属性赋值]()**
        - 创建B的时候发现依赖了A，A实例已经有了，因此A返回，B的属性A就设置进去
        - B实例和它的属性弄完之后到了A，A 属性依赖B，就去 getBean()把B拿出来设置到A里面
        - A，B 对象在 **[半成品]()** 的时候，其实是一个 ObjectFactory 对象
- ioc容器有几种类型？
    - BeanFactory 和 ApplicationContext.
- BeanFactory 和 ApplicationContext 有什么区别？
    - BeanFactory 是基本容器，而 ApplicationContext 是高级容器。Applicationcontext 是扩展了 BeanFactory 的接口
    - apc 提供了更多的有用的功能。如国际化，访问资源，载入多个（有继承关系）上下文
    - apc 使得每一个上下文都专注于一个特定的层次，消息发送、响应机制，AOP
    - beanfactory 的bean 是懒加载实例化，获取的时候发现没有才会实例化，Applicationcontext是启动完就会实例化
- 构造器注入和 set 注入的区别是什么?
    - 构造器注入没有部分注入。set允许部分注入
    - 如果有任何修改构造器会创建一个新实例。如果属性改变设置器并不会创建一个新实例
    - 构造器适合用于有非常多的属性的情况。设置器适合属性比较少的情况
    
- **[spring 事务机制与实现]()**
    - 事务最重要的两个特性，是事务的传播级别和隔离级别。
        - 传播级别定义的是事务的控制范围
        - 事务隔离级别定义的是事务在数据库读写方面的控制范围
        
    - spring 定义的是事务的传播级别，隔离级别是在数据库实现的，spring 的事务本质上是以来数据库的事务的
    - spring的事务传播行为
    ```
    传播行为怎么理解？
    最直接的体现就是代码里面，A 方法加了事务注解(指定一个传播级别)，A方法里面调用了B方法
    B方法也加了事务注解，这就是有多个事务的体现，传播级别就是定义这些事务之间是如何影响的
    ```
    - 事务的几种传播级别
        - REQUIRED：如果当前没有事务，就创建一个新事务，如果当前存在事务，就加入该事务，该设置是最常用的设置
        - SUPPORTS：支持当前事务，如果当前存在事务，就加入该事务，如果当前不存在事务，就以非事务执行
        - REQUIRES_NEW：创建新事务，无论当前存不存在事务，都创建新事务
        - NEVER：以非事务方式执行，如果当前存在事务，则抛出异常

```
public class Service {
    @Override
    @Transactional
    public void createUser(String name) {
        jdbcTemplate.update("INSERT INTO `user` (name) VALUES(?)", name);
        addAccount(name, 10000);
        throw new RuntimeException("");
    }
    /*
    addAccount()方法的事务是不会起作用的，同一个类的 A 方法调用 B 方法，A B 都有事务
    B 的事务是不会起作用的，因为spring的事务用的是JDK动态代理，动态代理的目标里面调用本类的方法
    是不会走代理的
    */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void addAccount(String name, int initMoney) {
        String accountid = new SimpleDateFormat("yyyyMMddhhmmss").format(new Date());
        jdbcTemplate.update("insert INTO account (accountName,user,money) VALUES (?,?,?)", accountid, name, initMoney);
    }
}
```

```
public class Service {
    @Transactional
    public void createUser(String name) {
        jdbcTemplate.update("INSERT INTO `user` (name) VALUES(?)", name);
        // 暴露proxy 对象 调用accountService添加帐户
        ((UserSerivce) AopContext.currentProxy()).addAccount(name, 10000);
        // 人为报错
        throw new RuntimeException("");
    ｝
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void addAccount(String name, int initMoney) {
        String accountid = new SimpleDateFormat("yyyyMMddhhmmss").format(new Date());
        jdbcTemplate.update("insert INTO account (accountName,user,money) VALUES (?,?,?)", accountid, name, initMoney);
    }
}
```

- Spring AOP
    - OOP关注的是对象，AOP关注的是切面，AOP 是面向切面编程的思想，是OOP的一种补充
    - AOP的编程思想就是把业务逻辑和横切的问题进行分离，从而达到解耦的目的，使代码的重用性和开发效率高
    
    - AOP的应用场景有哪些?
        - 日志记录
        - 权限验证
        - 事务管理
    - spring AOP 默认使用jdk动态代理还是cglib？
        - 要看条件，如果实现了接口的类，是使用jdk。如果没实现接口，就使用cglib
    - 是编译时期进行织入，还是运行期进行织入？
        - 运行期，生成字节码，再加载到虚拟机中，JDK是利用反射原理，CGLIB使用了ASM原理
- spring aop 或者是 事务注解的原理
    - springboot 的 spring.factories 声明了很多组件的自动装配，其中就包含了事务(或者aop)的自动配置组件
    - 这个组件会向容器注册事务(或者aop)的代理对象，只要扫描的类方法里面有事务注解(aop注解)就会注册代理对象
    - 这些有事务注解的bean在容器里面创建对象的时候，创建的bean对象实际是一个代理对象
    - 代理对象持有原对象的一个引用，对原对象的方法调用进行前后封装
    - 前后封装是指原对象的方法用了 try catch 包起来，每一场事务提交，有异常事务回滚
    - 以后每次调用原对象的方法都是调用代理对象的方法
  
- spring 常用的设计模式
    - 工厂模式
        - Spring使用工厂模式可以通过 BeanFactory 或 ApplicationContext 创建 bean 对象
    - 代理模式
        - 代理模式包括静态代理，动态代理
        - AOP 使用的是动态代理
        - 代理方式可以减少系统的重复代码，降低模块间的耦合度，并有利于未来的可拓展性和可维护性
    - 单例模式
        - 默认的bean是单例模式的
        - 在我们的系统中，有一些对象其实我们只需要一个，比如说：线程池、缓存、注册表、日志对象
        - 这一类对象只能有一个实例，如果制造出多个实例就可能会导致一些问题的产生
    - 模板方法模式
        - 模板方法包括抽象类，抽象方法，子类实现抽象方法
        - Spring 中 jdbcTemplate、hibernateTemplate 就使用到了模板模式
    - 观察者模式
        - 观察者模式是一种对象与对象之间具有依赖关系，当一个对象发生改变的时候，这个对象所依赖的对象也会做出反应
        - spring中各种 event, listener 类就是这种模式
        - ApplicationEvent，ApplicationListener
