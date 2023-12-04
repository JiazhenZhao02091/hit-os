BOOTSEG=0x07c0   !左移4位后就是0x7c00，占512B，所以偏移512B（0x0200）后得0x7e00；
SETUPSEG=0x07e0        
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
    mov cx,#28		;msg size
    mov bp,#msg2
!  "移动段寄存器 es"
    mov ax,cs
    mov es,ax
! 	"写字符串并移动光标"
    mov ax,#0x1301
    int 0x10


	
!	"设置无限循环"
inf_loop:
    jmp inf_loop

msg2:
    .byte   13,10
    .ascii  "Now we are in SETUP..."
    .byte   13,10,13,10
    
.org 510

!"引导扇区正确结束的标志"
boot_flag:
    .word   0xAA55
