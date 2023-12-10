### Record some condition about hit-os.

# 实验一

- 制作镜像

```shell
cd ~/oslab/linux-0.11
make all 
```

- 启动镜像

```shell
cd ~/oslab/
./run
```

- 调试
  - 汇编级调试
  
  ```shell
  cd ~/oslab
  ./dbg-asm
  ```
  
  - C语言级调试

    启动一个窗口

    ```shell
    cd ~/oslab
    ./dbg-c
    ```
    再启动一个窗口
    ```shell
    cd ~/oslab
    ./rungdb
    ```

- 文件交换
```shell
cd ~/oslab/
sudo ./mount-hdc
# 进入挂载后的目录
cd ~/oslab/hdc
ls-al
# 卸载文件系统
cd ~/oslab/
sudo umount hdc
```


# 实验三 系统调用

需要实现的系统调用函数如下：

```c 
int iam(const char * name);                // 将字符串内容保存到内核中
int whoami(char* name, unsigned int size); // 在内核中将iam()保存的信息拷贝到指定的用户地址空间中
```

测试
```shell
./iam zhaojiazhen
./whoami

zhaojiazhen
```
补充：调用系统调用和调用一个普通的自定义函数在代码上并没有什么区别，但是不同的是，系统调用可能会涉及到内核交互
 
- 系统调用函数通过使用call来讲系统调用的号传递到eax中，把参数传给其余寄存器，然后使用int 0x80中断
- 我们在这里直接实现了`sys_whoami`和`sys_iam`，然后进行调用相当于直接执行了系统调用代码
- 传统应用代码，例如`printf`则是通过头文件中的`syscall`来访问`system_call.s`进而调用80中断来，然后调用`sys_xxx`函数实现的 

首先我们需要知道实现一个系统调用需要修改哪些部分:

- 在用户空间使用系统调用都是通过库函数或者直接调用`sys_call`
  - `sys_call1`
  - `sys_call2`
  - `sys_call3`
  - 目前最多只支持三个参数,因为保存参数的寄存器只有三个
- `sys_call`则是通过传入参数到`int 0x80`实现的
- `int 0x80`进行系统调用的原理是通过`system_call.s`实现的
- `system_call.s`通过`system_call_table`实现,进而根据中断号调用系统调用函数
- 综上所述:
- 我们需要在`unistd.h`添加有关`__NR_IAM`和`__NR_whoami`的系统调用号
- 在`system_call.s`中更新系统调用数量
- 在`linux/sys.h`中添加
  - `extern int sys_iam`
  - `extern int sys_whoami`
  - 在`call_table`数组中添加相关调用

完成上述修改后,还需要根据教程修改Makefile

- 修改 OBJS
- 修改 Dependices

通过教程我们可以发现,用户态和核心态数据交互所需要的函数为:

- include/asm/segment.h/get_fs_byte
- include/asm/segment.h/put_fs_byte

接下来就可以开始实现 iam() 和 whoami()函数了

- 在kernel/下创建who.c
- 参考代码如下:
- ```c
  int sys_iam(const char *name)
  {
      printk("hello, i'm sys_iam\n");
      char tmp[maxSize];
      int i;
      for (i = 0; i < maxSize; i++)
      {
          tmp[i] = get_fs_byte(name + i);
          if (tmp[i] == '\0')
              break; 
      }
      if (i == maxSize)
          return -EINVAL;
      else
      {
          strcpy(msg, tmp); 
          return i;
      }
  }
  ```
- ```c
  int sys_whoami(char *name, unsigned int size)
  {
      printk("hello, i'm sys_whoami\n");
      int msg_size = 0;
      while (msg[msg_size] != '\0')
          msg_size++;
      if (size < msg_size)
          return -EINVAL;
      else
      {
          int i;
          for (i = 0; i < size; i++)
          {
              put_fs_byte(msg[i], name + i);
              if (msg[i] == '\0')
                  break;
          }
          return i;
      }
  }
  ```
之后编译IMG,进入linux0.11之后,编译`iam`和`whoami`运行如下命令即可
```shell
./iam zhaojiazhen
./whoami
zhaojiazhen
```
出现上述,证明完成了实验

实验报告

- 问题1:前文已经做出了解答
- 问题2:可以参考前文,这里不再赘述:cry:

# 实验三：进程运行轨迹的跟踪与统计

