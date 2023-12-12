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

# 实验四：进程运行轨迹的跟踪与统计

## 实验内容

- 基于模板 process.c 编写多进程的样本程序，实现如下功能： 
  + 所有子进程都并行运行，每个子进程的实际运行时间一般不超过 30 秒； 
  + 父进程向标准输出打印所有子进程的 id，并在所有子进程都退出后才退出；
- 在 Linux0.11 上实现进程运行轨迹的跟踪
  - 基本任务是在内核中维护一个日志文件 /var/process.log，把从操作系统启动到系统关机过程中所有进程的运行轨迹都记录在这一 log 文件中
- 在修改过的 0.11 上运行样本程序，通过分析 log 文件，统计该程序建立的所有进程的等待时间、完成时间（周转时间）和运行时间，然后计算平均等待时间，平均完成时间和吞吐量
- 修改 0.11 进程调度的时间片，然后再运行同样的样本程序，统计同样的时间数据，和原有的情况对比，体会不同时间片带来的差异

## 4.1 编写样本程序

从实验材料中我们可以发现，`process.c`模板程序已经提供了`cupio_bound`函数来模拟各个子程序的运行时间，包括CPU时间、IO时间等

因此，需要实现的就是在`process.c`中的`main`函数使用`fork`和`wait`系统调用来创建多个子程序，然后每个子程序执行各自的`cpuio_bound`函数来模拟实际情况，父进程等待所有子进程之后再向`stdout`来输出所有的子进程`id`.

这里给出两版代码，一版是广义情况下调用库函数的代码，另外一版是调用系统调用的一版

process.c :
```c
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <sys/times.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#define HZ 100

void cpuio_bound(int last, int cpu_time, int io_time);

/*
    + 所有子进程都并行运行，每个子进程的实际运行时间一般不超过 30 秒；
    + 父进程向标准输出打印所有子进程的 id，并在所有子进程都退出后才退出；
    fork();
    wait();
*/
int main(int argc, char *argv[])
{
    /*

    */
    int pid_list[5];                // pid list
    int pid_index = 0;              // pid index/number
    int fork_numer = atoi(argv[1]); // 参数1， 参数0为./process
    srand(time(NULL));              // init time to get random.
    if (argc < 2)
    {
        printf("argment count is to less!!!\n");
        return 0;
    }

    for (int i = 0; i < fork_numer; i++)
    {
        int pid = fork();
        if (pid == -1)
            printf("create fork errr!\n");
        if (!pid)
        {
            // int total_time = rand() % 10 + 1;
            int total_time = getpid() % 29 + 1; // time <= 30
            printf("I'am %d children fork. total time is %d\n", getpid(), total_time);
            cpuio_bound(total_time, i, total_time - i); // total_time cpu_time io_time
            exit(EXIT_SUCCESS);
        }
        else
        {
            pid_list[pid_index++] = pid;
        }
    }

    /*
        wait all children fork exit;
        wait() 只会等待任意一个子进程退出，因此需要for循环来等待子进程结束
    */
    for (int i = 0; i < fork_numer; i++)
    {
        int pid = wait(NULL);
        printf("I'm father process and I'm end wait, children_pid = %d\n", pid);
    }
    // output all children fork pid;
    for (int i = 0; i < pid_index; i++)
        printf("process %d pid is %d.\n", i, pid_list[i]);
    return 0;
}

/*
 * 此函数按照参数占用CPU和I/O时间
 * last: 函数实际占用CPU和I/O的总时间，不含在就绪队列中的时间，>=0是必须的
 * cpu_time: 一次连续占用CPU的时间，>=0是必须的
 * io_time: 一次I/O消耗的时间，>=0是必须的
 * 如果last > cpu_time + io_time，则往复多次占用CPU和I/O
 * 所有时间的单位为秒
 */
void cpuio_bound(int last, int cpu_time, int io_time)
{
    struct tms start_time, current_time;
    clock_t utime, stime;
    int sleep_time;

    while (last > 0)
    {
        /* CPU Burst */
        times(&start_time);
        /* 其实只有t.tms_utime才是真正的CPU时间。但我们是在模拟一个
         * 只在用户状态运行的CPU大户，就像“for(;;);”。所以把t.tms_stime
         * 加上很合理。*/
        do
        {
            times(&current_time);
            utime = current_time.tms_utime - start_time.tms_utime;
            stime = current_time.tms_stime - start_time.tms_stime;
        } while (((utime + stime) / HZ) < cpu_time);
        last -= cpu_time;

        if (last <= 0)
            break;

        /* IO Burst */
        /* 用sleep(1)模拟1秒钟的I/O操作 */
        sleep_time = 0;
        while (sleep_time < io_time)
        {
            sleep(1);
            sleep_time++;
        }
        last -= sleep_time;
    }
}
```

process2.c

```c
#include <stdio.h>
#include <unistd.h>  
int main(int argc, char * argv[])
{
    int id = fork();
    if(!id) {
        printf("id == %d\n", id);
        printf("I am child process, my id is [%d] and my parent process is [%d].\n", getpid(), getppid());
    }
	return 0;
}
```

## log 文件

观察`init/main.c`代码可以发现，`main`函数在执行完所有的初始化后使用`fork()`来创建进程1，并在进程1中执行`init`函数，而原本的父进程0则是不断执行`pause()`系统调用

在`init`函数中，进程首先会初始化文件描述符，并分别将0,1,2绑定至`stdin stdout stderror`，因此我们可以在这里将文件描述符3绑定至我们的`log`文件

```c
void init(void)
{
	int pid, i;
setup((void *)&drive_info);
	(void)open("/dev/tty0", O_RDWR, 0);									// stdin  0
	(void)dup(0);														// stdout  1
	(void)dup(0);														// stderror  2
	(void)open("/var/process.log", O_CREAT | O_TRUNC | O_WRONLY, 0666); // log  3
  // ....
}
```

接下来为了让`log`文件开启的时间提前，记录所有进程的状态，我们将上述代码移动至内核开启代码后，即`move_to_user`之后

```c
  move_to_user_mode();
	// 加载文件系统
	setup((void *)&drive_info);
	(void)open("/dev/tty0", O_RDWR, 0);									// stdin  0
	(void)dup(0);														// stdout  1
	(void)dup(0);														// stderror  2
	(void)open("/var/process.log", O_CREAT | O_TRUNC | O_WRONLY, 0666); // log  3
	if (!fork())
	{ /* we count on this going ok */
		init();
	}
```

至此，`log`文件就已经开启成功

### 写log文件

实验楼环境为我们提供了写`log`文件的函数，直接将它复制到`kernel/printk.c`中即可，以后我们使用`fprink()`函数并加上对应的文件描述符即可实现对`log`文件日志的写入

```c
#include <stdarg.h>
#include <stddef.h>

#include <linux/kernel.h>

#include "linux/sched.h"
#include "sys/stat.h"

static char buf[1024];
static char logbuf[1024];

extern int
vsprintf(char *buf, const char *fmt, va_list args);

int printk(const char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	i = vsprintf(buf, fmt, args);
	va_end(args);
	__asm__("push %%fs\n\t"
			"push %%ds\n\t"
			"pop %%fs\n\t"
			"pushl %0\n\t"
			"pushl $buf\n\t"
			"pushl $0\n\t"
			"call tty_write\n\t"
			"addl $8,%%esp\n\t"
			"popl %0\n\t"
			"pop %%fs" ::"r"(i) : "ax", "cx", "dx");
	return i;
}

// write（）实现
// 写入Log
int fprintk(int fd, const char *fmt, ...)
{
	va_list args;
	int count;
	struct file *file;
	struct m_inode *inode;

	va_start(args, fmt);
	count = vsprintf(logbuf, fmt, args);
	va_end(args);
	/* 如果输出到stdout或stderr，直接调用sys_write即可 */
	if (fd < 3)
	{
		__asm__("push %%fs\n\t"
				"push %%ds\n\t"
				"pop %%fs\n\t"
				"pushl %0\n\t"
				/* 注意对于Windows环境来说，是_logbuf,下同 */
				"pushl $logbuf\n\t"
				"pushl %1\n\t"
				/* 注意对于Windows环境来说，是_sys_write,下同 */
				"call sys_write\n\t"
				"addl $8,%%esp\n\t"
				"popl %0\n\t"
				"pop %%fs" ::"r"(count),
				"r"(fd) : "ax", "cx", "dx");
	}
	else
	/* 假定>=3的描述符都与文件关联。事实上，还存在很多其它情况，这里并没有考虑。*/
	{
		/* 从进程0的文件描述符表中得到文件句柄 */
		if (!(file = task[0]->filp[fd]))
			return 0;
		inode = file->f_inode;

		__asm__("push %%fs\n\t"
				"push %%ds\n\t"
				"pop %%fs\n\t"
				"pushl %0\n\t"
				"pushl $logbuf\n\t"
				"pushl %1\n\t"
				"pushl %2\n\t"
				"call file_write\n\t"
				"addl $12,%%esp\n\t"
				"popl %0\n\t"
				"pop %%fs" ::"r"(count),
				"r"(file), "r"(inode) : "ax", "cx", "dx");
	}
	return count;
}
/*
// 向stdout打印正在运行的进程的ID
fprintk(1, "The ID of running process is %ld", current->pid);
// 向log文件输出跟踪进程运行轨迹
fprintk(3, "%ld\t%c\t%ld\n", current->pid, 'R', jiffies);
*/
```

## jiffies

`jiffies`是系统滴答数，它代表了系统从开机到现在为止经过的滴答数，在`sched_init()`中我们也可以发现时钟处理函数被初始化为`time_interuupt`，其中每次执行该函数都会让`jiffies`的值加一

下面这部分代码用于设置每次时钟中断的间隔`LATCH`

```c
// 设置8253模式
outb_p(0x36, 0x43);
outb_p(LATCH&0xff, 0x40);
outb_p(LATCH>>8, 0x40);
```

linux0.11环境下的`jiffies`为`10ms`

## 寻找状态切换点

为了在合适的地方记录状态的变化，并将其写入日志之中，我们需要考虑一下几种情况

- 新建 --> 就绪
- 就绪 --> 运行
- 运行 --> 就绪
- 运行 --> 睡眠（可中断，不可中断）
- 睡眠 --> 就绪

了解到可能存在的状态变化之后，我们只需要在相对应的代码位置进行记录即可，主要修改的函数包括：

- 就绪到运行：`schedule()`
- 运行到睡眠：`sleep_on()`和`interruptible_sleep_on()`
- 进程主动睡眠：`sys_pause()`和`sys_waitpid()`
- 睡眠到就绪：`wake_up()`

这里给出**一部分**参考代码，具体的可以查看`dev3`分支

```c
/*
  schedule()部分
*/
	while (1)
	{
		c = -1;
		next = 0;
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i)
		{
			if (!*--p)
				continue;
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c)
				c = (*p)->counter, next = i;
		}
		if (c) // 找到counter最大的进程并且是就绪态
			break;
		for (p = &LAST_TASK; p > &FIRST_TASK; --p)
			if (*p)
				(*p)->counter = ((*p)->counter >> 1) +
								(*p)->priority;
	}
	// switch_to 切换进程，但是由于这里是通过汇编进行切换，因此需要提前记录
	if (task[next]->pid != current->pid)
	{
		if (current->state == TASK_RUNNING)
			fprintk(3, "%ld\t%c\t%ld\n", current->pid, 'J', jiffies);
		fprintk(3, "%ld\t%c\t%ld\n", task[next]->pid, 'R', jiffies);
	}
	switch_to(next);
```
在上面我们需要关注的点是，每次记录之前需要使用`if()`进行判断，是否状态真的发生了改变，避免重复的记录

其中进程0即父进程在系统无事可做的时候，会不断调用`pause()`系统调用，以激活调度算法，此时它可以是等待态，也可以是运行态，因为它是唯一一个在CPU上运行的程序


## 管理log文件

- 每次退出`bochs`之前记得使用`sync`刷新缓存
- 可以使用`mount`来挂载文件，将`process.log`文件拷贝到主机环境，方便处理阅读

## 数据统计

这里给出进行测试的步骤

- 将实验楼提供的测试代码拷贝至主机环境
- 使用挂载命令，将前面的`process.c`程序上传到`linux0.11 root/`中
- 在`linux0.11`中编译运行`process.c`程序
- 使用挂载命令，将`linux0.11`中的`process.log`拷贝至主机环境
- 使用`stat_log.py`对`process.log`进行测试
```shell
chmod +x ./stat_log.py
./stat_log.py process.log 1 2 3 4  # 只统计pid为1 2 3 4的进程
./stat_log.py process.log # 统计所有进程
```

## 修改时间片

根据实验指导，我们就可以发现，`nice`系统调用不会执行，只有`scdule.h`中的`INIT_TASK`宏会修改`state counter priority`，因此我们直接在这里修改即可完成对时间片的修改

```c
/*scdele.h*/
#define INIT_TASK \
    { 0,15,15,
// 上述三个值分别对应 state、counter 和 priority;
```
当就绪进程`counter`为0的时候，会被更新成初始`priority`的值

## 实验报告

- 结合自己的体会，谈谈从程序设计者的角度看，单进程编程和多进程编程最大的区别是什么？
  - 单进程编程无需考虑系统资源的调用部分，独占CPU即可
  - 多进程编程需要考虑各个进程之间的资源调度、运行优先级、运行时间分配等问题

- 你是如何修改时间片的？仅针对样本程序建立的进程，在修改时间片前后，log 文件的统计结果（不包括 Graphic）都是什么样？结合你的修改分析一下为什么会这样变化，或者为什么没变化？
  - 修改时间片前文已经给出了
  - 作者偷了个懒，没有比较，等待以后补充...
  - 据作者猜测应该没什么变化，因为运行优先级等都是确定过的，只影响了运行时间