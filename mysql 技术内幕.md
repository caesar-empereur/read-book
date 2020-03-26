## 1 章 mysql 技术体系

- 实例与数据库的区别
  * mysql 数据库是指操作系统文件的集合
  * mysql 实例是系统进程与内存区域的组成
  * 数据库实例才是处理数据的
  
- innodb 存储引擎的特点

  * 支持事务
  * 行锁设计
  * 插入缓冲
  * 二次写
  * 自适应哈希索引
  
- innodb 存储引擎架构

![架构](https://github.com/caesar-empereur/read-book/blob/master/photo/mysql/innodb.png)
