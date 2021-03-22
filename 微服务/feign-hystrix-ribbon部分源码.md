```
RetryTemplate  retryTemplate.setRetryPolicy()

LoadBalancedRetryPolicy  retryTemplate.execute() 远程调用的方法，重试机制调用的也是 execute() 

feign 的超时时间配置，在实际的调用中超时机制是 2倍 的，因为 实际的超时是 feign 的超时加上 ribbon 的超时
feign 的重试次数跟当前负载均衡的节点有关，如果服务名对应有多个实例时，当前的实例重试次数达到之后，
会选择另外一个实例进行重试，重试的前提条件是重试次数还没到
```




```
FeignRetryPoilicy extends InterceptorRetryPolicy {
    public boolean canRetry(RetryContext context) {
        if (context.getRetryCount() == 0) {
            return true;
        }
        return super.canRetry(context);
    }
}

InterceptorRetryPolicy {

    private HttpRequest request;
	private RibbonLoadBalanceRetryPolicy policy;
	private ServiceInstanceChooser serviceInstanceChooser;
	private String serviceName;
	
    public boolean canRetry(RetryContext context) {
        LoadBalancedRetryContext lbContext = (LoadBalancedRetryContext) context;
        if (lbContext.getRetryCount() == 0 && lbContext.getServiceInstance() == null) {
            lbContext.setServiceInstance(this.serviceInstanceChooser.choose(this.serviceName));
            return true;
        }
        return this.policy.canRetryNextServer(lbContext);
    }
}


RibbonLoadBalanceRetryPolicy {

    public boolean canRetrySameServer(LoadBalancedRetryContext context) {
        return sameServerCount < lbContext.getRetryHandler().getMaxRetriesOnSameServer() && HttpMethod.GET == method;
    }
    public boolean canRetryNextServer(LoadBalancedRetryContext context) {
        // 失败一次重试次数加一次
        return nextServerCount <= lbContext.getRetryHandler().getMaxRetriesOnNextServer() && HttpMethod.GET == method;
    }
    
    public boolean canRetry(LoadBalancedRetryContext context) {
        HttpMethod method = context.getRequest().getMethod();
        return HttpMethod.GET == method || lbContext.isOkToRetryOnAllOperations();
    }
    
    public void registerThrowable(LoadBalancedRetryContext context, Throwable throwable) {
    
        if (!canRetrySameServer(context) && canRetryNextServer(context)) {
            context.setServiceInstance(loadBalanceChooser.choose(serviceId));
        }
        
        if (sameServerCount >= lbContext.getRetryHandler().getMaxRetriesOnSameServer() && canRetry(context)) {
            // reset same server since we are moving to a new server
            sameServerCount = 0;
            nextServerCount++;
            if (!canRetryNextServer(context)) {
                context.setExhaustedOnly();
            }
        }
        else {
            sameServerCount++;
        }
    }
}
```
