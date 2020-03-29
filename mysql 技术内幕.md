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

![innodb](https://raw.githubusercontent.com/caesar-empereur/read-book/master/photo/mysql/innodb.png?token=AGG6JXBIXZRC7AVYK4R26R26PXDZU)


- mysql 数据文件
  * 表都是根据主键顺序组织存放的，这种存储方式的表称为索引组织表
  * 页 是mysql 磁盘上最小单位的数据存储形式，也叫 块，每页的数据大小是 16 KB
  * 页存放的行记录也是有硬性定义的，最多允许存放16KB / 2-200行的记录，即7992行记录
