- BitSet
    - 本质上就是用一个数字来存储多个数字
    - 例如要存2个数字，9，14
    - 就是把 1 位运算左移 9位=512, 11左移14位=16384
    - 然后 512跟16384或运算相当于 相加 16896
    - 传入9的时候，1还是左移 9位=512, 512跟 16896与运算,如果结果还是512，说明521也就是9这个数字存在

```

    BitSet map=new BitSet();

    System.out.println(map.size());

    int a[]={2,3,14,7,0};

    //赋值
    for(int num:a){
        map.set(num,true);
    }
    //排序

    for (int i = 0; i < map.size(); i++) {
        if(map.get(i)){
            System.out.print(i+" ");
        }
    }
输出
64
0 2 3 7 14
```
