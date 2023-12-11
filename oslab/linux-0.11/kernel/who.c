#include <string.h>      //实现置 errno为EINVAL
#include <errno.h>       //调用了strcpy
#include <asm/segment.h> //调用了get_fs_byte, put_fs_byte

#define maxSize 24
char msg[maxSize]; // 这样就可以在内核中保存下来，最后一位是'\0'

int sys_iam(const char *name)
{
    printk("hello, i'm sys_iam\n");
    char tmp[maxSize];
    int i;
    for (i = 0; i < maxSize; i++)
    {
        tmp[i] = get_fs_byte(name + i);
        // printk("%c\n", tmp[i]);
        if (tmp[i] == '\0')
            break; //'\0'表示字符串结束了
    }
    if (i == maxSize)
    {
        return -EINVAL;
    }
    else
    {
        strcpy(msg, tmp); // 感觉在内核中调用C语言库会不太好
        return i;
    }
}

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
