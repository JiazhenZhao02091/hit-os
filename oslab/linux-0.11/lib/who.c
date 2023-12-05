#define __LIBRARY__
#include <unistd.h>

_syscall1(int, iam, const char *, name);

_syscall1(int, whoami, char *, name, unsigned int, size);

/*
    添加系统调用的过程：
    库函数提供API
    函数调用API
    库函数实际上就是系统调用
    传入 __NR__##name 和 fd
    根据系统调用返回的值来进行输出
*/