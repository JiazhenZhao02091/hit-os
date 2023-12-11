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

    /*
        int fpid = fork();
        // exec
        if (fpid == 0)
        {
            // 子进程
            printf("I'm children fork!!\n");
            exit(EXIT_SUCCESS);
        }
        else
        {
            printf("I'm father fork, and my children fork pid is %d\n", fpid);
            int status;
            wait(&status);
            printf("status = %d\n", status);
        }
    */
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
