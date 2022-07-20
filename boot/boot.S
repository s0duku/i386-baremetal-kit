#include <inc/mmu.h>

# mmu 内存管理方面，boot 刚开始只是处理了段表，方便进入32位模式
# 随后在内核boot初期设置了临时页表，开启虚拟内存，方便处理虚拟内存到物理内存的映射

# boot 状态下，没有 c 的运行时环境，比如各种栈寄存器，所以不能直接写 C 代码
# 需要汇编过度
# 切换 CPU 到 32 位模式，跳转到 C 代码
# BIOS 将会自动加载 硬盘上第一个分区到内存物理地址 0x7c00，开始以实模式运行
# %cs=0 %ip=7c00.

# 类似 define 的东西
.set PROT_MODE_CSEG, 0x8         # 内核代码段选择子偏移
.set PROT_MODE_DSEG, 0x10        # 内核数据段选择子偏移
.set CR0_PE_ON,      0x1         # 保护模式


.globl start # 指示链接器entry point

start:
  .code16                     # 告诉编译器cpu的应该是再16位模式，此时32位操作
                              # 指令会有 0x66 前缀
  cli                         # 清空中断
  cld                         # 串指令复位

  # 设置重要数据段寄存器
  xorw    %ax,%ax             # Segment number zero
  movw    %ax,%ds             # -> Data Segment 数据段
  movw    %ax,%es             # -> Extra Segment 额外段
  movw    %ax,%ss             # -> Stack Segment 栈段

  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.1

  movb    $0xd1,%al               # 0xd1 -> port 0x64
  outb    %al,$0x64

seta20.2:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.2

  movb    $0xdf,%al               # 0xdf -> port 0x60
  outb    %al,$0x60

  # 从实模式切换到保护模式，使用一个启动 GDT(全局描述符表)和段转换
  # 使虚拟地址映射到物理地址，因此已经映射的内存不会再切换过程中改变

  lgdt    gdtdesc

  # cr0 寄存器 CR0_PE_ON 位 置一
  movl    %cr0, %eax
  orl     $CR0_PE_ON, %eax
  movl    %eax, %cr0
  

  # 利用 ljmp 修改 cs 寄存器，方便切换到 32 bit mode
  
  ljmp    $PROT_MODE_CSEG, $protcseg

  .code32                     # Assemble for 32-bit mode
protcseg:
  # 设置保护模式的数据段寄存器
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS
  movw    %ax, %ss                # -> SS: Stack Segment
  
  # 设置好栈底指针，调用 C 语言启动函数
  # 0xa0000 到 0x100000 属于设备区，不方便占用
  # 0x100000 一般是 32 位内核代码
  # boot 在  0x7c00 到 0x7d00
  # 0x7c00 之前就可以拿来用
  movl    $start, %esp
  call bootmain

  # 一般来说 bootmain 不该返回，如果返回，就无限循环
spin:
  jmp spin

# Bootstrap GDT
.p2align 2                                # 强制四字节对齐
# 全局描述符表
gdt:
  SEG_NULL				# 第0个置空
  SEG(STA_X|STA_R, 0x0, 0xffffffff)	# 第一个放代码段，基地址0，直到 0xffffffff
  SEG(STA_W, 0x0, 0xffffffff)	        # 数据段其实和代码段一样，基地址 0，这样就不改变boot原始映射的状态

# 全局描述符
gdtdesc:
  .word   0x17                            # sizeof(gdt) - 1
  .long   gdt                             # address gdt

