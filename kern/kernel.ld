/* 内核链接脚本，查看 ld 手册了解语法 */

/* https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html */


OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	/* Link the kernel at this address: "." means the current address */
	/* .自然增长  */
	. = 0x400000;

	/* AT(...) 给定指定节区设置加载地址，来告诉bootloader加载内核的物理地址*/
	/* 应为我们的 bootloader 刚启动时，并没有设置好 MMU, 所以还不能以虚拟地址直接运行程序 */
	/* 此时地址操作直接对应物理地址，如果把程序加载到 0xF0000000，可能根本没这么大内存 */
	/* 所以先加载到 1mb 位置，然后 MMU 开启映射后，内核就可以正常执行 */
	/* *代表所有文件 */
	/* 节名 起始地址 : ... */
	/* AT 指示LMA加载地址，一般来说和 VMA是一样的，但现在手动设置一下 */
	.text : AT(0x400000) {
		*(.text .stub .text.* .gnu.linkonce.t.*)
	}

	PROVIDE(etext = .);	/* Define the 'etext' symbol to this value */

	.rodata : {
		*(.rodata .rodata.* .gnu.linkonce.r.*)
	}

	/* Include debugging information in kernel memory */
	.stab : {
		PROVIDE(__STAB_BEGIN__ = .);
		*(.stab);
		PROVIDE(__STAB_END__ = .);
		BYTE(0)		/* Force the linker to allocate space
				   for this section */
	}

	.stabstr : {
		PROVIDE(__STABSTR_BEGIN__ = .);
		*(.stabstr);
		PROVIDE(__STABSTR_END__ = .);
		BYTE(0)		/* Force the linker to allocate space
				   for this section */
	}

	/* Adjust the address for the data segment to the next page */
	. = ALIGN(0x1000);

	/* The data segment */
	.data : {
		*(.data)
	}

	.bss : {
		PROVIDE(edata = .);
		*(.bss)
		PROVIDE(end = .);
		BYTE(0)
	}


	/DISCARD/ : {
		*(.eh_frame .note.GNU-stack)
	}
}
