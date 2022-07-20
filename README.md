
# i386 BareMetal Kit

i386 baremetal program development kit based on MIT JOS

* by default kernel will be load at physical address 0x400000
* there is only linear address at runtime，did not enable the page
* debug with qemu-system-i386
* user program entrypoint: void baremetal_main();
* user module put under 'user' directory，manually add into 'Makefrag' file
* use 'make' to build kernel.img (kernel with MBR) 