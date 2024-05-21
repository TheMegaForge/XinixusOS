%macro std_open 0
    push r11
    push r10
    push r9
    push rcx
%endmacro
%macro std_close 0
    pop rcx
    pop r9
    pop r10
    pop r11
    ret
%endmacro
struc _pager
    .mapped resq 1
    .base   resw 1
    .pml4I  resw 1
    .pdpdI  resw 1
    .pdtI   resw 1
endstruc