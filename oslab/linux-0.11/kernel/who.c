#include <string.h>      //实现置 errno为EINVAL
#include <errno.h>       //调用了strcpy
#include <asm/segment.h> //调用了get_fs_byte, put_fs_byte

#define maxSize 24
char msg[maxSize]; // 这样就可以在内核中保存下来，最后一位是'\0'

int sys_iam(const char *name)
{
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
        // printk("too long!\n");
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
    int msg_size = 0;
    while (msg[msg_size] != '\0')
        msg_size++;
    // printk("msg_size : %d\n", msg_size);
    // printk("msg : %s\n", msg);
    if (size < msg_size)
        return -EINVAL;
    else
    {

        int i;
        // printk("size : %d\n", size);
        for (i = 0; i < size; i++)
        {
            // printk("ok\n");
            // printk("name : %c\n", name[i]);
            // printk("msg : %c\n", msg[i]);
            put_fs_byte(msg[i], name + i);
            if (msg[i] == '\0')
                break;
        }
        return i;
    }
}
