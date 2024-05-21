OUTPUT_FORMAT("binary")
OUTPUT("build/stage1/src.bin")
INPUT(
    build/stage1/setup.o
    build/stage1/x64.o
    build/stage1/memory.o
    build/stage1/stdio.o
    build/stage1/HAL.o
    build/stage1/idt.o
    build/stage1/idt_asm.o
    build/stage1/idt_impl.o
    build/stage1/pixelation.o
    build/stage1/sysInit.o
    build/stage1/string.o
    build/stage1/acpi.o
)
SECTIONS{
    . = 0x8400;
    .setupi : {*(.setupi)}
    .setup  : {*(.setup)}
    .setupd : {*(.setupd)}
    .setupc : {*(.setupc)}
    .setupu : {*(.setupu)}
    .text  : {*(.text)}
    .data  : {*(.data)}
    .bss   : {*(.bss)}
};