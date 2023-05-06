## mongodb 事务

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
