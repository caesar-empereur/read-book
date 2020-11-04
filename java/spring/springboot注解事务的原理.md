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

- TransactionManagementConfigurationSelector
    - ProxyTransactionManagementConfiguration
        - AnnotationTransactionAttributeSource
            - SpringTransactionAnnotationParser
    - AutoProxyRegistrar
        - registerBeanDefinitions(AnnotationMetadata mt, BeanDefinitionRegistry registry)
            - AopConfigUtils.registerAutoProxyCreatorIfNecessary(registry)
                - InfrastructureAdvisorAutoProxyCreator implements BeanPostProcessor
                    - Object postProcessBeforeInstantiation(Class beanClass, String beanName)
                    - getAdvicesAndAdvisorsForBean(beanClass, beanName, targetSource)
                        - TransactionInterceptor
                        
- Transactional 注解流程总结
    - Aop 自动装配，生成事务拦截器对应的bean
    - 一个service注解的类在生成bean 的时候会调用 BeanPostProcessor 的后置bean处理方法
    - 如果判断到这个bean 里面有加了事务注解的话会被解析读取到，找到这个bean对应的Advisor通知器
    - 接下来就是在后置bean处理方法要用切面 TransactionInterceptor 对原来的bean进行封装
    - 封装成一个代理后的对象，切面是事务的拦截器 TransactionInterceptor
    - 以后的每次调用该注解对应的方法的时候都会执行事务拦截器里面的增强后的方法
    - 增强的方法里面的逻辑就是关闭事务自动提交，执行目标方法，没有异常事务提交，有则回滚
