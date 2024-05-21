all : compile c_compile trunc
CC = $(TARGET)-gcc
CC_FLAGS = -nostdlib -c -ffreestanding -mno-red-zone -m64 -I src/include/ -Os -std=c17
TARGET = $(TOOL_CHAIN)/bin/x86_64-elf
TOOL_CHAIN = /usr/local/x86_64elfgcc
LD = $(TARGET)-ld
compile:
	nasm -f bin -I boot/ boot/boot.asm -o build/loader/boot.o
	nasm -f bin -I boot/ boot/AR.asm -o build/loader/AR.o
	nasm -f elf64 -I src/ src/x64.asm -o build/stage1/x64.o
	nasm -f elf64 -I src/ src/idt.asm -o build/stage1/idt_asm.o
c_compile:
	$(CC) $(CC_FLAGS) src/setup.c -o build/stage1/setup.o
	$(CC) $(CC_FLAGS) src/memory.c -o build/stage1/memory.o
	$(CC) $(CC_FLAGS) src/stdio.c -o build/stage1/stdio.o
	$(CC) $(CC_FLAGS) src/idt.c -o build/stage1/idt.o
	$(CC) $(CC_FLAGS) src/HAL.c -o build/stage1/HAL.o
	$(CC) $(CC_FLAGS) src/idt_impl.c -o build/stage1/idt_impl.o
	$(CC) $(CC_FLAGS) src/pixelation.c -o build/stage1/pixelation.o
	$(CC) $(CC_FLAGS) src/sysInit.c -o build/stage1/sysInit.o
	$(CC) $(CC_FLAGS) src/string.c -o build/stage1/string.o
	$(CC) $(CC_FLAGS) src/acpi.c -o build/stage1/acpi.o
	$(LD) -T src/stage1.ld --print-map > help/setup.map
trunc:
	cat build/loader/boot.o build/loader/AR.o > build/loader/loader.bin
	dd  if=build/loader/loader.bin of=dsk.img bs=512 seek=0 conv=notrunc
	dd  if=build/stage1/src.bin of=dsk.img bs=512 seek=4 conv=notrunc