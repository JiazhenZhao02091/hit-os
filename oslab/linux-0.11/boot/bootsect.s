BOOTSEG=0x07c0   !左移4位后就是0x7c00，占512B，所以偏移512B（0x0200）后得0x7e00；
SETUPSEG=0x07e0    ! "setup 位置"    
SETUPLEN=2  !linus写的是4，教程是2
entry _start
_start:
! 屏幕输出功能
!	"读取光标位置"
    mov ah,#0x03
    xor bh,bh
    int 0x10
!	"获取信息"
    mov bx,#0x0007
    mov cx,#32
    mov bp,#msg1
!  "移动段寄存器 es"
    mov ax,#BOOTSEG
    mov es,ax
! 	"写字符串并移动光标"
    mov ax,#0x1301
    int 0x10


!	"加载setup"
load_setup:
     mov dx,#0x0000
     mov cx,#0x0002  !	扇区不是从0开始的，而是从1开始的，1是bootsect所在的扇区，setup从扇区2开始
     mov bx,#0x200   !es:bx 指向将要存放的内存地址
     mov ax,#0x0200+SETUPLEN !读2个扇区到内存
	 !"使用 0x13 中断读取两个扇区参数"
     int 0x13


     jnc ok_load_setup ! "成功就跳转到ok_load_setup执行"


     mov dx,#0x0000
     mov ax,#0x0000 !"复位软盘"
     int 0x13
     jmp load_setup


!跳转到setup执行
ok_load_setup:
     jmpi 0,SETUPSEG !	"段间跳转指令  cs = SETUPSEG , ip = 0"
     	
    
msg1:

    .byte   13,10
    .ascii  "Jiazhen's OS is Loading..."
    .byte   13,10,13,10
    
.org 510


!"引导扇区正确结束的标志"
boot_flag:
    .word   0xAA55
