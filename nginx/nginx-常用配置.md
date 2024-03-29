### 应用HTTPS部署

>> 应用实现HTTPS部署有2种方式，在应用里面实现和利用 nginx 实现

- 应用里面实现HTTPS
  * 把证书和私钥放在应用的配置文件的目录下，启动的时候读取这些文件
  
- nginx 配置实现HTTPS
  * 把证书和私钥放在nginx目录下，利用nginx配置实现
  
- 证书和私钥的生成操作
  * 确保正确安装 openssl 工具
  * 进入到要生成的证书的目录下面，按照顺序执行如下命令
  * 生成私钥
    * genrsa -des3 -out zhengshu.key 2048
  * 去掉私钥密码
    * rsa -in zhengshu.key -out zhengshu.key
  * 生成证书签名请求的文件
    * req -new -key zhengshu.key -out zhengshu.csr
  * 用私钥和请求文件生成证书
    * x509 -req -days 365 -in zhengshu.csr -signkey zhengshu.key -out zhengshu.crt

```
第二条命令是用来把私钥里面的密码去掉的，不去掉密码的话 nginx 启动会报错：error:2006D002:BIO routines:BIO_new_file:system lib

生成证书签名请求的文件 的时候需要输入域名，这个域名跟你接下来要用这个证书部署的域名 没有直接关系，域名不一样也是可以部署成功的
```

- linux nginx 安装
```
apt-get install gcc
apt-get install libpcre3 libpcre3-dev
apt-get install zlib1g zlib1g-dev

sudo apt-get install openssl 
sudo apt-get install libssl-dev

tar -zxvf nginx-1.18.0.tar.gz
cd nginx-1.18.0
./configure --prefix=/home/dev/base-service/nginx/compile/nginx-1.18.0 --pid-path=/home/dev/base-service/nginx/compile/nginx-1.18.0/logs/nginx.pid --with-http_ssl_module --with-http_v2_module --with-http_stub_status_module
make
make install

```

- nginx 安装需要的模块



```
linux才可以添加模块，windos 的nginx 是一个执行文件，添加不了模块，但是已经内置了ssl等基本的模块
windos nginx-1.19.0 版本测试过，把下面的配置文件复制过去，证书放好位置，直接启动访问是没问题的

linux 的 nginx 如果没有ssl模块的话需要添加，执行下面的命令

./configure --prefix=/home/base-service/nginx/compile/nginx-1.19.0 --pid-path=/home/base-service/nginx/compile/nginx-1.19.0/logs/nginx.pid --with-http_ssl_module --with-http_v2_module --with-http_stub_status_module
make
make install

./configure --prefix=/home/dev/base-service/nginx/compile/nginx-1.18.0 --pid-path=/home/dev/base-service/nginx/compile/nginx-1.18.0/logs/nginx.pid --with-http_ssl_module --with-http_v2_module --with-http_stub_status_module


openresty 安装
wget https://openresty.org/download/openresty-1.15.8.3.tar.gz
./configure --prefix=/home/base-service/nginx/compile/openresty-1.15.8.3 --with-luajit --without-http_redis2_module --with-http_ssl_module --with-http_v2_module --with-http_stub_status_module --add-module=/home/base-service/nginx/modules/ngx_dynamic_upstream-0.1.6
make
make install
```

- nginx 配置详细配置文件

    * nginx.conf 配置文件配置
    ```
    #user  nobody;
    worker_processes  1;
    error_log  logs/error.log;
    #pid        logs/nginx.pid;
    
    events {
        worker_connections  1024;
    }
    
    
    http {
        include       mime.types;
        default_type  application/octet-stream;
    
    	log_format  main  '$remote_addr - $time_local - $status $body_bytes_sent';
        access_log  logs/access.log;
        sendfile        on;
        keepalive_timeout  65;
    	
    	# 如果证书能支持多级域名的话，可以用这 2 个全局证书配置
        ssl_certificate 	 D:/dev/app/nginx/SSL/nginx/create/zhengshu.pem;
        ssl_certificate_key  D:/dev/app/nginx/SSL/nginx/create/zhengshu.key;
    	
    	server {
    		listen   80 default;
    		server_name  _;
    		return 403;
    	}
    
    	server_names_hash_bucket_size 64; 
    
    	include vhost/*.conf;
    }
    ```
    
    * 常规的 https 后端服务配置
    ```
    server {
    	
    	listen       80;
    	server_name  manager.com;
    	return   301 https://$server_name$request_uri;
    }
    
    server {
    	
    	listen       443 ssl http2;
    	server_name  manager.com;
    
    	ssl_certificate      $ssl_cert_file;
    	ssl_certificate_key  $ssl_cert_key;
    	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    	ssl_session_cache    shared:SSL:1m;
    	ssl_session_timeout  5m;
    	ssl_ciphers  HIGH:!aNULL:!MD5;
    	ssl_prefer_server_ciphers  on;
    
    	location / {
    		proxy_pass http://localhost:8083;
    		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    		proxy_set_header X-Forwarded-Proto $scheme;
    		proxy_set_header X-Forwarded-Port $server_port;
    		proxy_set_header X-Real-IP $remote_addr;
    		proxy_set_header Host $http_host;
    		proxy_set_header X-NginX-Proxy true;
    	}
    }
    ```
    
    * 负载均衡的配置单独配置文件
    ```
    server {
    
    	listen       80;
    	server_name  webapi.com;
    	return   301 https://$server_name$request_uri;
    }
    
    server {
    
    	listen       443 ssl http2;
    	server_name  webapi.com;
    
    	ssl_certificate      $ssl_cert_file;
    	ssl_certificate_key  $ssl_cert_key;
    	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    	ssl_session_cache    shared:SSL:1m;
    	ssl_session_timeout  5m;
    	ssl_ciphers  HIGH:!aNULL:!MD5;
    	ssl_prefer_server_ciphers  on;
    
    	location / {
    		proxy_pass http://webapi_list;
    		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    		proxy_set_header X-Forwarded-Proto $scheme;
    		proxy_set_header X-Forwarded-Port $server_port;
    		proxy_set_header X-Real-IP $remote_addr;
    		proxy_set_header Host $http_host;
    		proxy_set_header X-NginX-Proxy true;
    	}
    }
    ```
    
    * websocket 协议的配置文件
    ```
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }
    
    server {
    
    	listen 80;
    	listen 443 ssl http2;
    
    	ssl_certificate 	D:/dev/app/nginx/SSL/nginx/aliyun/constantinopolis/constantinopolis.top.pem;
    	ssl_certificate_key D:/dev/app/nginx/SSL/nginx/aliyun/constantinopolis/constantinopolis.top.key;
    
    	server_name constantinopolis.top;
    	
    	location /wss {
    		proxy_pass http://localhost:9090;
    		
    		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    		proxy_set_header X-Forwarded-Proto $scheme;
    		proxy_set_header X-Forwarded-Port $server_port;
    		proxy_set_header X-Real-IP $remote_addr;
    		proxy_set_header Host $http_host;
    		proxy_set_header X-NginX-Proxy true;
    	
    		proxy_http_version 1.1;
    		proxy_set_header Upgrade $http_upgrade;
    		proxy_set_header Connection "upgrade";
    	}
    }
    ```
    
    * 前端项目部署的配置
    ```
    server {
    
    	listen       80;
    	server_name  vue-admin-web.top;
    	return   301 https://$server_name$request_uri;
    	
    }
    
    server {
    
    	listen       443 ssl http2;
    	server_name  vue-admin-web.top;
    	
    	ssl_certificate		D:/dev/app/nginx/SSL/nginx/aliyun/vue-admin-web/vue-admin-web.top.pem;
    	ssl_certificate_key D:/dev/app/nginx/SSL/nginx/aliyun/vue-admin-web/vue-admin-web.top.key;
    	
    	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    	ssl_session_cache    shared:SSL:1m;
    	ssl_session_timeout  5m;
    	ssl_ciphers  HIGH:!aNULL:!MD5;
    	ssl_prefer_server_ciphers  on;
    
    	location / {
    		root D:\dev\project\vue\vue-admin-web\dist;
    		index index.html index.htm;
    	}
    }
    ```
    

- springboot 配置文件需要加的项
```properties
server.tomcat.remote_ip_header=x-forwarded-for
server.tomcat.protocol_header=x-forwarded-proto
server.tomcat.port-header=X-Forwarded-Port
server.use-forward-headers=true
```
