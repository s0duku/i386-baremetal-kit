/* See COPYRIGHT for copyright information. */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/monitor.h>
#include <kern/console.h>

void baremetal_main();

void
test_backtrace(int x)
{
	cprintf("entering test_backtrace %d\n", x);
	if (x > 0)
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
}

void
i386_init(void)
{
	extern char edata[], end[];

	// 在做其他事之前，先完成 ELF 的加载过程，清除 BSS 节
	memset(edata, 0, end - edata);

	// 初始化 Console 口
	// 在调用初始化之前，不能cprintf
	cons_init();
	cprintf("\n");
	baremetal_main();


	// 进入内核监控器
	while (1)
		monitor(NULL);
}


/*
 * panicstr 包含第一次调用 panic 的参数，用来作为标志指示内核已经调用 panic 了
 */
const char *panicstr;

/*
 * panic 遇到无法处理的错误调用，打印错误信息，进入内核监控器
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;

	// 一定要确保机器处于合理状态
	asm volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);

dead:
	/* 返回内核监控器 */
	while (1)
		monitor(NULL);
}

/* 类似 panic */
void
_warn(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);
}
