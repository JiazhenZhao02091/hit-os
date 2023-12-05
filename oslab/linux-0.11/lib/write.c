/*
 *  linux/lib/write.c
 *
 *  (C) 1991  Linus Torvalds
 */

#define __LIBRARY__
#include <unistd.h>
// 系统调用
/*
    printf 库函数实现格式化输出，将各种格式送入 write.c，通过syscall宏定义展开为0x 80中断，操作系统进入中断处理，根据中断号去查询中断程序表，
    调用中断程序
        -->  调用syscall
            --> syscall 宏定义展开调用了 int 0x80中断
*/
_syscall3(int, write, int, fd, const char *, buf, off_t, count)

    /*
        --> syscall3宏展开
    */
