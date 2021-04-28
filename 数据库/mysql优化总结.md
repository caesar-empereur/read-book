## mysql 自增主键用完了会怎么样
- mysql int的数字范围是 正负 2 的32次方，大概是20亿，不管是 int(*) 多少
- mysql bigint的数字范围是正负 2 的 64次方，大概是万亿的万倍，不管是bigint(*)多少
- 因此自增主键除非经常删除数据，否则是很难用完的
- 如果真的用完了，那么往后生成的主键都一直是最大的，插入会报主键重复的错误

## mysql 的 int，bigint 后面跟的几位数是什么作用
- int,bigint的数字范围是2的32次方，跟64次方，跟后面跟的几位数没关系
- 后面跟的几位数字叫显示宽度，也叫零填充，int(4) 的话是 0001，超过9999的数字是显示不了的

## mysql 优化的依据分析
- **[show profile 可以看到执行计划中每个步骤的执行时间](#)**
    - show profile 可以看到执行计划中每个步骤的执行时间
    ```
    select * from ***;
    show profiles; //这一句可以输出 query id
    show profile for query <queryid>
    send data 时间很长说明有大量的磁盘 io
    ```
* **[mysql explain 输出信息详解](#)**
   * type （对表访问方式，效率从上到下提高）
      * ALL：Full Table Scan， MySQL将遍历全表以找到匹配的行
      * index: Full Index Scan，index与ALL区别为index类型只遍历索引树
      * range: 范围扫描，一个有限制的索引扫描，就是条件带了范围查询
      * ref:   where age=20 返回匹配到某个值的多行记录
      * eq_ref: 使用的是唯一索引，返回只有一条记录，where order_no=**
      * const、system: 进行优化，并转换为一个常量时，使用这些类型访问, where id=123
   * possible_keys，keys
      * 显示查询使用了哪些索引, 以及实际上使用的是哪些索引
   * ref
      * 即哪些列或常量被用于查找索引列上的值
   * rows
      * 估算的扫描行数，越少越好
   * **[Extra](#)**
      * **[Using index](#)**：这发生在对表的请求列都是同一索引的部分的时候
          ```
          mysql> explain select id from film order by id;
          +----+-------------+-------+-------+---------------+---------+---------+------+------+-------------+
          | id | select_type | table | type  | possible_keys | key     | key_len | ref  | rows | Extra       |
          +----+-------------+-------+-------+---------------+---------+---------+------+------+-------------+
          |  1 | SIMPLE      | film  | index | NULL          | PRIMARY | 4       | NULL |    3 | Using index |
          +----+-------------+-------+-------+---------------+---------+---------+------+------+-------------+ 
          ```
      * **[Using where](#)**：mysql服务器将在存储引擎检索行后再进行过滤。就是先读取整行数据，再按 where 条件进行检查，符合就留下，不符合就丢弃
        ```
        mysql> explain select * from film where id > 1;
        +----+-------------+-------+-------+---------------+----------+---------+------+------+--------------------------+
        | id | select_type | table | type  | possible_keys | key      | key_len | ref  | rows | Extra                    |
        +----+-------------+-------+-------+---------------+----------+---------+------+------+--------------------------+
        |  1 | SIMPLE      | film  | index | PRIMARY       | idx_name | 33      | NULL |    3 | Using where; Using index |
        +----+-------------+-------+-------+---------------+----------+---------+------+------+--------------------------+
        ```
      * Using filesort：mysql 会对结果使用一个外部索引排序，而不是按索引次序从表里读取行, 常见于排序操作
      
      * Using temporary：表示MySQL需要使用临时表来存储结果集，常见于排序和分组查询，常见 group by ; order by
 
## mysql show processlist 结果分析
- 结果集中的 time 列是当前查询已经从开始到这个命令锁消耗的时间
- 如果一个慢查询消耗20s的时间，那么从19s的时候执行这个show命令，会看到time为20
- 查询执行结束后，show 命令重新查的话已经没有刚刚那个慢查询了
- 慢查询查出的是当前正在活跃，处理的查询线程，查询结束，就不会在show的结果集中展示的
## mysql 表设计的原则
- 表数据量的设计
    - 单表数量在2000w的不用考虑分表
    - 如果涉及多表关联查询，单表的数据量就要限制，可考虑分区表或者自己按时间范围分表
- 字段设计
    - 将经常访问的列与不常访问的列分开存放表
    - 不要将列用在存大数据，例如图片或者文件
    - 主键不要带有业务含义，带有业务含义的话，因为业务会变更
    - 字段不要有 null 的定义
- 索引设计
    - 单表索引数量不超过5个
    - 避免重复的索引，使用联合索引，联合索引最常使用的字段放在左边
    - 不在索引字段上进行函数运算
- 数据归档
    - 对于已经稳定运行的应用，数据预计会线性增长的情况，要设计归档数据，也就是冷热数据分离
- 读写分离
    - 读写分离是为了解决读比写多的情况，分散读写压力
- 分库分表
    - 分库分表是为了解决写入的压力，包括单库的IO压力，将写入压力分散到多个库里

## mysql 常见优化场景
- 大数据分页查询优化
    - 放弃全表count, 改成 select max(id)
    - 关联多表的分页查询
        - 不能用常见的偏移量查，要先用子查询限定结果集查出id，然后外面查询用 where id in()
        ```
        SELECT aa.id,aa.checkin_photo,aa.checkin_status,aa.checkin_time,aa.checkout_photo,aa.checkout_status,aa.checkout_time,"
        aa.CODE,aa.date,aa.schedule_id,ac.clear_hour,ac.early_hour,ac.late_hour,ac.total_hour 
        FROM (SELECT * FROM t_attendance_log_2000w 
         WHERE id IN ( SELECT id FROM ( SELECT id FROM t_attendance_log_2000w WHERE id BETWEEN ?1 AND ?2 ORDER BY id DESC ) tt )) aa
        ```

## 数据库设计的3大范式
- 第一范式：字段原子性，属性不可分割
    - 字段还能再分割的话应该继续分割，例如地址信息，应该是省，市，区
- 第二范式：表中的字段必须完全依赖主键(与主键相关)
    - 主键用来确定唯一性，表中的其他字段依赖于主键来确定唯一性
    - 例如用户表中，张三的年龄性别等字段必须是根据主键确定到的张三的这行信息，而不是别人的
- 第三范式：应该消除传递依赖，消除冗余
    - 订单表中有用户信息，应该只有 userid 字段，不应该有用户名，手机号，性别等其他用户的信息

## mysql varchar(4000) 的索引优化
- 长度这么大的索引效率很低，可以做 text 全文索引，也可以用加个字段来存md5值，对这个字段索引
