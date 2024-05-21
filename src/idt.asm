section .setup
%include "x64i.inc"
%macro std__icall 1
    push rsp
    push rax
    push rdi
    push rsi
    push rdx
    mov rdi,rsp
    call %1
    add rsp,40
%endmacro
[bits 64]
global division_error
global overflow_error
global opcode_error
division_error:
    iretq
overflow_error:
    iretq
opcode_error:
    cli
    hlt
global general_error
general_error:
    iretq
global page_error
page_error:
    pop rax
    iretq
global sysexc_handler
[extern sys_formats]
[extern sys_exceptions]
[extern c_sysexc]
[extern c_sysfrmt]
sysexc_handler:
    cmp ax,[sys_exceptions]
    jl .WORK
    jg .ERROR
    .WORK:
        std__icall c_sysexc
        jmp .nERROR
    .nWORK:

    .ERROR:
        int 4;causes overflow
        add rsp,8
        xor rax,rax
    .nERROR:
    iretq
global sysfrmt_handler
sysfrmt_handler:
    cmp ax,[sys_formats]
    jle .WORK
    jg .ERROR
    .WORK:
        std__icall c_sysfrmt
        jmp .nERROR
    .nWORK:

    .ERROR:
        int 4;causes overflow
        add rsp,8
        xor rax,rax
    .nERROR:
    iretq
global int_pc
int_pc:
    mov ax,0
    int 101
    ret