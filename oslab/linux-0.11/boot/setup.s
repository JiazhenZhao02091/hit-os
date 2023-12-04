BOOTSEG=0x07c0   !左移4位后就是0x7c00，占512B，所以偏移512B（0x0200）后得0x7e00；
SETUPSEG=0x07e0        
SETUPLEN=2  !linus写的是4，教程是2
INITSEG=0x9000
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

	mov ax,cs
	mov es,ax
! "init ss:sp"
	mov ax,#INITSEG
    mov ss,ax
    mov sp,#0xFF00
! "Get Params"
    mov ax,#INITSEG
    mov ds,ax
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov [0],dx
    mov ah,#0x88
    int 0x15
    mov [2],ax
    mov ax,#0x0000
    mov ds,ax
    lds si,[4*0x41]
    mov ax,#INITSEG
    mov es,ax
    mov di,#0x0004
    mov cx,#0x10
    rep
    movsb

! "Be Ready to Print"
    mov ax,cs
    mov es,ax
    mov ax,#INITSEG
    mov ds,ax

! "Cursor Position"
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#18
    mov bx,#0x0007
    mov bp,#msg_cursor
    mov ax,#0x1301
    int 0x10
    mov dx,[0]
    call    print_hex
! "Memory Size"
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#14
    mov bx,#0x0007
    mov bp,#msg_memory
    mov ax,#0x1301
    int 0x10
    mov dx,[2]
    call    print_hex
! "Add KB"
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#2
    mov bx,#0x0007
    mov bp,#msg_kb
    mov ax,#0x1301
    int 0x10
! "Cyles"
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#7
    mov bx,#0x0007
    mov bp,#msg_cyles
    mov ax,#0x1301
    int 0x10
    mov dx,[4]
    call    print_hex
! "Heads"
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#8
    mov bx,#0x0007
    mov bp,#msg_heads
    mov ax,#0x1301
    int 0x10
    mov dx,[6]
    call    print_hex
! "Secotrs"
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#10
    mov bx,#0x0007
    mov bp,#msg_sectors
    mov ax,#0x1301
    int 0x10
    mov dx,[12]
    call    print_hex


!	"设置无限循环"
inf_loop:
    jmp inf_loop

print_hex:
! 	"4个十六进制数字"
	mov cx,#4
print_digit:
	rol    dx,#4
    mov    ax,#0xe0f
    and    al,dl
    add    al,#0x30
    cmp    al,#0x3a
    jl     outp
    add    al,#0x07
outp:
    int    0x10
    loop   print_digit
    ret
print_nl:   	!"打印回车换行"
    mov    ax,#0xe0d     ! CR
    int    0x10
    mov    al,#0xa     ! LF
    int    0x10
    ret

msg2:
    .byte   13,10
    .ascii  "Now we are in SETUP..."
    .byte   13,10,13,10
msg_cursor:
    .byte 13,10
    .ascii "Cursor position:"
msg_memory:
    .byte 13,10
    .ascii "Memory Size:"
msg_cyles:
    .byte 13,10
    .ascii "Cyls:"
msg_heads:
    .byte 13,10
    .ascii "Heads:"
msg_sectors:
    .byte 13,10
    .ascii "Sectors:"
msg_kb:
    .ascii "KB"    





.org 510

!"引导扇区正确结束的标志"
boot_flag:
    .word   0xAA55
