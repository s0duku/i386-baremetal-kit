/*引入 内存初始化相关 */
#include <inc/mmu.h>
#include <inc/memlayout.h>



###################################################################
# 入口点
###################################################################

.text

# _start 变量描述 ELF 入口点，既然bootloader此时还没有设置虚拟地址，
# 我们需要 bootloader 跳转到 entry point 的物理地址

.globl		_start
_start = entry

.globl entry
entry:

	# 裸机程序不需要分页
	mov	$relocated, %eax
	jmp	*%eax
relocated:
	# 准备 c 代码运行时环境
	# 清除栈帧，这样一旦我们开始调试C代码，堆栈回溯将被正确终止。
	movl	$0x0,%ebp

	# 设置栈底指针
	movl	$(bootstacktop),%esp

	# 跳去 C 代码
	call	i386_init

	# 死循环
spin:	jmp	spin


.data
###################################################################
# boot 栈
###################################################################
	.p2align	PGSHIFT		# force page alignment
	.globl		bootstack
bootstack:
	.space		KSTKSIZE
	.globl		bootstacktop   
bootstacktop:

