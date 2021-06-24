## 基本语法
- Go语言的变量声明格式为：var 变量名 类型
- 变量初始化赋值操作：
    - var i int = 100
    - var i = 100
    - i := 100  (推导声明写法的左值变量必须是没有定义过的变量)
- 指针
    - 变量、指针和地址三者的关系是：每个变量都拥有地址，指针的值就是地址
    - & 取出地址，* 根据地址取出地址指向的值
    - go 里面能用 make 创建的 3 种类型都是引用类型(chan slice 和 map)
    - golang 里传参都是值传递，没有引用传递
    - 结构体的普通方式的实例化是没有new直接定义的，new与& 实例化的是指针类型的结构体
    - 值拷贝，只拷贝了这个指针的内容到一个新的指针，不会把指向的内容再拷贝
    
## 容器
- 数组
  - 数组定义  var arr [3]string{"a","b","c"}
      - var team [3]string
  - 数组初始化 var team = [3]string{"sdfs","ffd","sdgtrg"}
  - 数组遍历
    ```
    for k, v := range team {
        fmt.Println(k, v)
    }
    ```
  - arr[1:2]  获取位置1-2的切片
- 映射 map
  - map 定义 map[key type] value type
    - scene := make(map[string]int)
    - scene["sdhjf"] = 123
  - map 遍历
    ```
     key value 同时遍历
     for k, v := range scene {
        fmt.Println(k,v)
     }
    
     key 为匿名形式遍历
     for _, v := range scene {
        fmt.Println(v)
     }
    
     只遍历 key
     for k, := range scene {
        fmt.Println(k)
     }
    ```
  - 删除一个 key delete(scene, "jfjgj")

- 列表 list (数据结构为双向链表)
  - 列表初始化
    - lista := list.New()
    - var lista list.List
  - 列表插入元素
    - lista.Push Back("srgt")
    - lista.Push Front("45")
    - lista.Insert Before("45", "56")
  - 列表移除元素
    - lista.Remove("45")
  - 遍历列表
    ```
    for i := lista.Front(); i != nil; i = i.next() {
        fmt.Println(i.value)
    }
    ```

## 函数
- 普通函数声明
    ```
    
    func 函数名(参数列表) (返回参数列表) { //go语言支持返回多参数
    
    }
    
    func add(a, b int) int { //参数类型相同的，第一个的类型不用写
        return a+b
    }
    
    func TwoValue() (int, int) {
        return 1, 2
    }
    ```
- 函数调用 result := add(1, 1)
- 函数作为变量
    ```
    func fire() {
        fmt.Println("fire")
    }
    
    func main() {
      var f func() // 定义变量 f 为函数类型
      f = fire    // 将函数 fire 赋值给 f
      f()          // 调用 fire 函数
    }
    ```
- 匿名函数
  - 匿名函数定义
  ```
  func(data int) {
      fmt.Println("hello", data)
  }(100)    // 匿名函数声明后调用
  ```
  - 匿名函数赋值给变量
  ```
  f := func(data int) {
      fmt.Println("hello", data)
  }
  f(100) // 使用f()调用
  ```

## 结构体
- go 语言中使用结构体来实现类似 Java 的类的概念
- go 语言没有类的概念，也不支持类的继承等面向对象的概念
- 结构体定义
  ```
  type Point struct {
      X int
      Y int
  }
  ```
- 结构体实例化
  - 普通的实例化 || var p Point
  - 指针类型的实例化
    - ins := new(Point)  ins 的类型为 *Point, 属于指针
  - 取结构体地址的实例化
    - ins := &Point  ins 的类型为 *Point, 属于指针
- 结构体成员变量实例化
  ```
  type Address struct {
      City string
      province string
  }
  addr := Address {
      "成都",
      "四川"
  }
  ```
- 函数封装
  - go 的类型或结构体没有构造函数，结构体的初始化过程是用 函数封装 实现的
  ```
  func newAddress(city string) *Address {
      return &Address{
            City: city,
      }
  }
  ```
- 方法
  - go 中的方法是一种作用与类型变量的函数，特定类型叫接收器
  - 如果将特定类型理解为结构体或“类”时，接收器的概念就类似于其他语言中的this或者self
  - go 的方法与函数的区别是函数没有作用对象，方法的作用对象是 接收器
  - go 的面向过程没有方法的概念，而是有函数参数与调用关系形成接近方法的概念
  - 接收器
  ```
  func (接收器变量 接收器类型) 方法名(参数列表) (返回参数) {
      函数体
  }
  
  type Address struct{
      City string
  }
  func (a *Address) addCity (name string){  // 这里Address的指针作为参数， Address 是一个接收器
      a.City = name
  }
  
  ``` 
  - 指针类型的接收器
    - 指针的特性，调用方法，修改接收器指针的成员变量，方法结束后修改都是有效的
    ```
    type Property struct {
         value int
    }
    func (p *Property) SetValue(v int) {
        p.value = v  //修改接收器指针成员变量是有效的
    }
    ```
  - 非指针类型的接收器
    - go 代码运行方法时，会将接收器的指复制一份, 对接收器的变量修改无效
    ```
    func (p Property) add(other Property) Property {
        return Property{p.value + other.value}
    }
    ```
  - 指针与非指针接收器的区别
    - 在计算机中，小对象由于值复制时的速度较快，所以适合使用非指针接收器
    - 大对象因为复制性能较低，适合使用指针接收器，在接收器和参数间传递时不进行复制，只是传递指针

## 接口
