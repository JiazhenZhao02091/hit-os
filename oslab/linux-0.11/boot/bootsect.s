!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux
!
SYSSIZE = 0x3000
!
!	bootsect.s		(C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
! iself out of the way to address 0x90000, and jumps there.
!
! It then loads 'setup' directly after itself (0x90200), and the system
! at 0x10000, using BIOS interrupts. 
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no
! problem, even in the future. I want to keep it simple. This 512 kB
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
!
! The loader has been made as simple as possible, and continuos
! read errors will result in a unbreakable loop. Reboot by hand. It
! loads pretty fast by getting whole sectors at a time whenever possible.

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

SETUPLEN = 4				! nr of setup-sectors
BOOTSEG  = 0x07c0			! original address of boot-sector
INITSEG  = 0x9000			! we move boot here - out of the way
SETUPSEG = 0x9020			! setup starts here
SYSSEG   = 0x1000			! system loaded at 0x10000 (65536).
ENDSEG   = SYSSEG + SYSSIZE		! where to stop loading

! ROOT_DEV:	0x000 - same type of floppy as boot.
!		0x301 - first partition on first drive etc
ROOT_DEV = 0x306  ! "设备号0x306指定根文件系统设备是第2个硬盘的第1个分区"

entry _start
_start:
	mov	ax,#BOOTSEG
	mov	ds,ax
	mov	ax,#INITSEG
	mov	es,ax
	mov	cx,#256
	sub	si,si
	sub	di,di
	rep
	movw
	jmpi	go,INITSEG
	
go:	mov	ax,cs
	mov	ds,ax
	mov	es,ax
! put stack at 0x9ff00.
	mov	ss,ax
	mov	sp,#0xFF00		! arbitrary value >>512

! load the setup-sectors directly after the bootblock.
! Note that 'es' is already set up.


! "利用BIOS 0x13中断，将setup模块从第二个扇区中读入到内存0x90200处，共读四个扇区；如果出错直接复位，重复过程"
load_setup:
	mov	dx,#0x0000		! drive 0, head 0
	mov	cx,#0x0002		! sector 2, track 0
	mov	bx,#0x0200		! address = 512, in INITSEG
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors
	int	0x13			! read it
	jnc	ok_load_setup		! ok - continue
	mov	dx,#0x0000
	mov	ax,#0x0000		! reset the diskette
	int	0x13
	j	load_setup

ok_load_setup:

! Get disk drive parameters, specifically nr of sectors/track  "获取磁盘驱动器参数，特别是每道的扇区数量"

	mov	dl,#0x00
	mov	ax,#0x0800		! AH=8 is get drive parameters
	int	0x13
	mov	ch,#0x00
	seg cs
	mov	sectors,cx		!"cx中是每磁道扇区数量"
	mov	ax,#INITSEG
	mov	es,ax

! Print some inane message 				打印输出信息

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#58			; 对应的字节
	mov	bx,#0x0007		! page 0, attribute 7 (normal)
	mov	bp,#msg1
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

! ok, we've written the message, now
! we want to load the system (at 0x10000)

	mov	ax,#SYSSEG
	mov	es,ax				! segment of 0x010000
	call	read_it			! "读磁盘上system模块，es为输入参数"
	call	kill_motor		! "关闭驱动器马达，这样就可以知道驱动器状态了"

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.
! "接下来我们检查使用哪个根文件系统设备，如果已经指定了就使用指定的根文件系统设备；否则就根据BIOS报告的每磁道扇区数来确定使用哪个：/dev/PS0 (2,28) or /dev/at0 (2,8)"

	seg cs
	mov	ax,root_dev
	cmp	ax,#0
	jne	root_defined

	seg cs
	mov	bx,sectors
	mov	ax,#0x0208		! /dev/ps0 - 1.2Mb
	cmp	bx,#15
	je	root_defined
	mov	ax,#0x021c		! /dev/PS0 - 1.44Mb
	cmp	bx,#18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax		! "将检查过的设备号保存在 root_dev 中"

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:

	jmpi	0,SETUPSEG
! "至此，本程序已经结束！"

! "下面是两个子程序，read_it用于读取磁盘上的system的模块，kill_moter用于关闭软驱的马达"
! This routine loads the system at address 0x10000, making sure "该子程序将系统模块加载到内存地址0x10000处，并确保没跨越64KB的内存边界"
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can. "只要可能，每次加载整条磁道的数据"
!
! in:	es - starting address segment (normally 0x1000)
! "输入：es，开始内存段地址的位置"
!

! "1 + SETUPLEN 表示开始时已经读入了1个引导扇区和setup扇区所占扇区数"
sread:	.word 1+SETUPLEN	! sectors read of current track "当前磁道已读扇区数"
head:	.word 0			! current head   "当前磁头号"
track:	.word 0			! current track  "当前磁道号"

read_it:
	mov ax,es
	test ax,#0x0fff
die:	jne die			! es must be at 64kB boundary  "es的值必须位于 64KB地址边界"
	xor bx,bx		! bx is starting address within segment
rp_read:
	mov ax,es
	cmp ax,#ENDSEG		! have we loaded all yet?
	jb ok1_read
	ret



ok1_read:
	seg cs
	mov ax,sectors
	sub ax,sread
	mov cx,ax
	shl cx,#9
	add cx,bx
	jnc ok2_read
	je ok2_read
	xor ax,ax
	sub ax,bx
	shr ax,#9
ok2_read:
	call read_track
	mov cx,ax
	add ax,sread
	seg cs
	cmp ax,sectors
	jne ok3_read
	mov ax,#1
	sub ax,head
	jne ok4_read
	inc track
ok4_read:
	mov head,ax
	xor ax,ax
ok3_read:
	mov sread,ax
	shl cx,#9
	add bx,cx
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read

! "读当前磁道上指定开始扇区和需读扇区数的数据到es:bx开始处"
read_track:
	push ax
	push bx
	push cx
	push dx
	mov dx,track
	mov cx,sread
	inc cx
	mov ch,dl
	mov dx,head
	mov dh,dl
	mov dl,#0
	and dx,#0x0100
	mov ah,#2
	int 0x13
	jc bad_rt
	pop dx
	pop cx
	pop bx
	pop ax
	ret

! "若读磁盘出错，则执行驱动器复位操作，再次跳转 read_track 重试"
bad_rt:	mov ax,#0
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track

!/*
! * This procedure turns off the floppy drive motor, so "这个程序关闭软驱的马达"
! * that we enter the kernel in a known state, and
! * don't have to worry about it later.
! */
kill_motor:
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

sectors:
	.word 0				! "存放当前启动软盘每磁道的扇区数"

msg1:
;  msg的大小 2 + 22 + 2 + 7 + 4  28+28=56+22=
	.byte 13,10
	.ascii "zjz Loading system ..." ; 22
	.byte 13,10
	.ascii "******\n" ; 7
	.ascii "    * \n"
	.ascii "  *   \n"
	.ascii "******\n"
	; .ascii "********\n******"
	.byte 13,10,13,10
;******
;    *  
;  *    
;******      

! "下面语句从地址 508 处开始"
.org 508
root_dev:
	.word ROOT_DEV
! "下面是启动盘具有引导扇区的标志，仅供BIOS中的程序加载引导扇区时识别使用，位于引导扇区的'最后'两个字节"
boot_flag:
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
