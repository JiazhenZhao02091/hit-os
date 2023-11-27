#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>

int main(void)
{
    char cmd[20];
    while (1)
    {
        scanf("%s", cmd);
        if (!fork())
            exec(cmd);
        else
            while (1)
            {
                /* code */
            }
    }
}