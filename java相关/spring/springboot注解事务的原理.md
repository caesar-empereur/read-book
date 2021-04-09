TransactionAutoConfiguration
PlatformTransactionManager
TransactionInterceptor

```
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Import(TransactionManagementConfigurationSelector.class)
public @interface EnableTransactionManagement {
}

```
- 从 spring.factories 里面声明的自动配置开始 包含了事务的自动配置 TransactionAutoConfiguration
- TransactionAutoConfiguration 里面生成了一个bean，bean 加了 @EnableTransactionManagement 事务自动开启注解
- @EnableTransactionManagement import 了 TransactionManageSelector
- TransactionManageSelector 根据通知类型返回导入哪个类
- 返回了 AutoProxyRegistrar 自动事务注册器
    - AutoProxyRegistrar
        - registerBeanDefinitions(AnnotationMetadata mt, BeanDefinitionRegistry registry)
            - AopConfigUtils.registerAutoProxyCreatorIfNecessary(AdvisorAutoProxyCreator, registry)
                - AdvisorAutoProxyCreator implements BeanPostProcessor
                    - Object postProcessBeforeInstantiation(Class beanClass, String beanName)
                    - getAdvisorsForBean(beanClass, beanName, targetSource)
                        - 通过 SpringTransactionAnnotationParser 解析类里面的注解
                        - 找到 通知器(切面)为 TransactionInterceptor
                  
        - TransactionInterceptor
            ```
            protected Object invokeWithinTransaction(Method method, Class targetClass, final InvocationCallback invocation) {
                TransactionAttributeSource tas = getTransactionAttributeSource();
                final TransactionAttribute txAttr = (tas != null ? tas.getTransactionAttribute(method, targetClass) : null);
                final PlatformTransactionManager tm = determineTransactionManager(txAttr);
                final String joinpointIdentification = methodIdentification(method, targetClass, txAttr);
                if (txAttr == null || !(tm instanceof CallbackPreferringPlatformTransactionManager)) {
                    TransactionInfo txInfo = createTransactionIfNecessary(tm, txAttr, joinpointIdentification);
                    Object retVal = null;
                    try {
                        // 这是环绕通知
                        retVal = invocation.proceedWithInvocation();
                    }
                    catch (Throwable ex) {
                        completeTransactionAfterThrowing(txInfo, ex);
                        throw ex;
                    }
                    finally {
                        cleanupTransactionInfo(txInfo);
                    }
                    commitTransactionAfterReturning(txInfo);
                    return retVal;
                }
                //transaction attribute为空的话按照非事务的方式执行
            }
            ```
                        
- Transactional 事务注解流程总结
    - springboot的事务的自动装配执行
        - springboot 的 spring.factories 声明了很多组件的自动装配，其中就包含了事务的自动配置 TransactionAutoConfiguration
        - TransactionAutoConfiguration 里面生成了一个bean，bean 加了 @EnableTransactionManagement 事务自动开启注解
        - @EnableTransactionManagement import 了 TransactionManageSelector
        - TransactionManageSelector 根据通知类型返回导入哪个类
        - 根据代理的通知类型返回了 AutoProxyRegistrar 自动事务注册器
    - 自动事务注册器向容器注册一个特殊的bean，这个bean实现了 BeanPostProcessor 接口
        - 该注册器向容器注册了一个特殊的bean, AdvisorAutoProxyCreator 实现了 BeanPostProcessor 接口
        - 所有的 bean 在初始化之前会调用 BeanPostProcessor 的后置bean处理方法
        - 这个后置处理方法的逻辑是传入一个 bean，返回一个新的 bean，因此可以在方法里面对bean做封装
    - 对bean进行判断封装
        - 找出bean的通知器，有的话需要代理，没有就不用代理
        - 通过反射解析bean的类里面加了事务注解，那通知器(切面)就是 TransactionInterceptor
        - 用事务拦截器对目标的bean进行代理，相当于封装成一个新的bean
        - 事务拦截器逻辑就是关闭事务自动提交，用try catch 执行目标方法，没有异常事务提交，有则回滚
    - 事务方法的执行
        - 以后每次调用目标方法，都会走事务拦截器的逻辑

- 以上的事务的流程同样适用与通用的 aop 自动装配

- 事务注解的超时时间的不同分析
    - 当执行事务的线程是在执行数据库操作，数据库阻塞了，线程还是在运行的(runable)，则超时时间是按照事务配置的
    - 当执行事务的线程是某种条件进入 sleep 状态，则超时时间要等到线程恢复，但是也会抛超时异常
    ```
    举个例子，超时配置3秒，当执行数据库阻塞的时候，3秒后线程抛超时异常终止，
    当执行线程由于某种条件进入 sleep状态，sleep 5秒，则会在5秒后恢复并且抛出超时异常，
    这是因为事务的超时的计时也是在事务的线程，线程sleep，没法进入计时，只能等到恢复运行后，
    计算时间发现已经超时了，才会抛异常终止
    ```
