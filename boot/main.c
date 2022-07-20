#include <inc/x86.h>
#include <inc/elf.h>

/**********************************************************************
 * 非常简单的 boot 程序，只是简单的启动一个 ELF 格式的内核镜像
 * 
 *
 * 硬盘布局
 *  * boot.S和main.c是bootloader，应该存储在磁盘的第一个扇区
 *  * 第二个扇区应该保存内核镜像
 *
 *  * 内核镜像必须是 ELF 格式
 *
 * BOOT 步骤
 *  * CPU boots 时，加载 BIOS 到内存中并执行
 *
 *  * BIOS 初始化设备，设置好中断例程，并且读取boot设备的第一个扇区到内存并且跳转过去
 *
 *  * 假设boot loader 存在第一个山区，这段代码占据
 *
 *  * boot.S 启动代码设置保护模式以及栈，来让C代码运行，调用 bootmain 
 *
 *  * bootmain 获取执行流，读取kernel，跳转执行
 **********************************************************************/

#define SECTSIZE	512 // 扇区大小
// 暂存的地址得选好，不能搞的和内核程序段加载的地址冲突，也不能把其他的保留地址冲突
#define ELFHDR		((struct Elf *) 0x30000) // 暂存 ELF 的地址

void readsect(void*, uint32_t);
void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
	struct Proghdr *ph, *eph;

	// 读取磁盘上一个页大小
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0); 

	// 是否一个有效的 ELF 魔术字
	if (ELFHDR->e_magic != ELF_MAGIC)
		goto bad;

	// 加载每一个程序段，忽略 ph 标志

	// 指向 program header 表开头
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	// program header 表最后一个 entry 地址
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
		// p_pa 这个segment加载到的目的地址，现在也就是 物理地址
		// p_offset 偏移，这个函数都是以kernel开始的位置酸，memsz 是 segment 大小
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);

	// 调用 ELF 的入口点
	// 注意一般不反回
	((void (*)(void)) (ELFHDR->e_entry))();

bad:
	outw(0x8A00, 0x8A00);
	outw(0x8A00, 0x8E00);
	while (1)
		/* do nothing */;
}


//读取 kernel offset 处 count 个字节到物理地址 pa
// 可能读取多于要求的数据，应为是按扇区读取
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
	// 结束地址
	uint32_t end_pa;

	end_pa = pa + count;

	// 四舍五入到扇区边界
	pa &= ~(SECTSIZE - 1);

	// 把 offset 从byte转换成sector 单位，kernel 从 sector 1 开始
	offset = (offset / SECTSIZE) + 1;

	// 如果太慢，我们可以一次读取许多扇区，我们可能写超过要求的数据到扇区，但是无所谓
	// 按递增顺序，加载数据
	while (pa < end_pa) {
		// 我们还没有开启分页，所以现在是直接映射地址到物理地址 (boots.S 还没开启分页)
		// 所以可以直接用物理地址，一旦开启MMU，CPU内存管理单元后就不能这样了
		readsect((uint8_t*) pa, offset);
		pa += SECTSIZE;
		offset++;
	}
}

void
waitdisk(void)
{
	// 等待 disk 准备完成
	while ((inb(0x1F7) & 0xC0) != 0x40)
		;
}

// 读取扇区
void
readsect(void *dst, uint32_t offset)
{
	// 等磁盘设备可以工作
	waitdisk();

	outb(0x1F2, 1);		// 扇区数目 1 
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
	outb(0x1F6, (offset >> 24) | 0xE0);
	outb(0x1F7, 0x20);	// 0x20 指令，代表读取扇区

	// 等磁盘设备可以工作
	waitdisk();

	// 读取一个扇区
	insl(0x1F0, dst, SECTSIZE/4);
}

