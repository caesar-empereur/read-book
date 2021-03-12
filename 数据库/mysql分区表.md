## mysql 分区表

- 分区表是什么
    - 分区表是mysqL的一个高级特性，可以将一个大的逻辑表在物理上分成多个表
    - 对于用户来说，是一个逻辑表，但是底层是按照一定规则分成多个物理子表
    - 分区表的一个主要目的是将单个表的数据在物理上分开，提高数据查询的效率
- 分区表的应用场景
    - 表的数据只有少部分是热点数据，大部分是历史存档数据
    - 根据业务属性判断，数据表呈现出线性增长的趋势，则分区表或者分库分表是要考虑的
    - 提高单表的数据量的存储限制
    - 将某些有共同属性的数据分开存放，例如按照日期(月份)分区，同一个月的数据存放在一起
    
- 分区表的一些属性
    - 一个表的分区子表是有限制的，5.7的版本是8000多个子表
    - 分区的字段必须是唯一索引的字段
    - 分区表无法适用外键
    - 分区表的增删改查执行的时候，需要将所有分区表锁定，然后根据条件定位到对应的分区表
- 分区表如何适用
    - mysql 建表的语句加上分区的规则
    ```
    CREATE TABLE members01 (
        id int(11) NOT NULL AUTO_INCREMENT,
        username VARCHAR(16) NOT NULL,
        joined DATETIME NOT NULL,
        PRIMARY KEY (id,joined),
        UNIQUE KEY `uk_username` (username,email,joined)
    )
    PARTITION BY RANGE( TO_DAYS(joined) ) (
        PARTITION p20170801 VALUES LESS THAN (736908),
        PARTITION p20170802 VALUES LESS THAN (736909)
    );
    ```
- 分区表的规则有几种
    - 按照范围分区 (PARTITION BY RANGE( TO_DAYS(joined) ))
        - 常见的范围分区是按照日期分区，在查询时将不符合条件的历史数据过滤掉，提高查询效率
        - 日期分区适合日期字段是连续的数据，这样每隔分区表的数据分布才均匀
        - 适合 where 查询里面加上日期范围查询的
    - 按照列表分区 (PARTITION BY LIST( TO_DAYS(joined) ))
        - 适合离散的数据，针对自己业务特性进行离散的分区，可以非常灵活的将数据打散到不同的分区
        - 适合固定值的in条件查询
    - 根据主键分区 (PARTITION BY key(joined))
        - 如果主键只有一列，可以直接 BY KEY
        - 适合查询条件都是有主键的场景
