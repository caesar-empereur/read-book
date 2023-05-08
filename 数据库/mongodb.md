## mongodb 事务
- MongoDB 3.0版本引入WiredTiger存储引擎之后开始支持事务 
- MongoDB 3.6之前的版本只能支持单文档的事务 
- MongoDB 4.0版本开始支持复制集部署模式下的事务
- MongoDB 4.2版本开始支持分片集群中的事务
- mongodb 也有类似Mysql binlog 日志类似的 oplog 文件，记录事务的操作

## mongodb 数据迁移导出导入

- mongodb 导出
```
mongoexport --host localhost:27017 -d build -c member_coupon_document 
-q {\"receiveTime\":{\"$gte\":\"2023-01-01\b00:00:00\",\"$lt\":\"2023-04-25\b00:00:00\"}} 
-o D:\mongo-export\document-2023-01-01.json
```

- mongodb 导入
```
mongoimport --host localhost:27017 -d build -c coupon_document_2023_01_01 
--file D:\mongo-export\document-2023-01-01.json
```
