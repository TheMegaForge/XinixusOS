%include "x64i.inc"
section .setup
[bits 64]
;rax = multiplier
;rcx = multiplier2
;r11 += product

page_mask equ (0xFFFFFFFF ^ 111111111111b)

global SIMD_init
;rdi = maxState
;rsi = size
SIMD_init:
    std_open
    xor r11,r11
    xor rcx,rcx
    mov cx,[0x990]
    mov cx,[rcx]   ;loading flags
    push rcx
    and cx,1
    cmp cx,1
    je .hMMX
    jmp .nMMX
    .hMMX:
        mov [rdi],dword 1
        mov [rsi],byte 8
    .nMMX:
    pop rcx
    push rcx
    and cx,0000000001111110b
    mov r11w,cx
    shr cx,1
    mov r10w,cx
    sub r11,r10
    cmp r10,0
    je .gAVX
    jmp .aAVX
    .gAVX:
        pop rcx
        jmp .hAVX
    .aAVX:
        inc r10d
        mov [rdi],r10d
        mov [rsi],byte 16
    pop rcx
    .hAVX:
        and cx,128+256
        cmp cx,0
        je .EXIT
        cmp cx,128 ;avx
        je .sAVX
        jmp .nsAVX
        .sAVX:
            mov [rdi],dword 128
            mov [rsi],byte 32
        .nsAVX:
        cmp cx,256 ;avx2
        jne .EXIT
        mov [rdi],dword 256
        mov [rsi],byte 32
    .EXIT:
    std_close
global shift_into_order
;edx = privilege
;esi = present
;edi = callType
shift_into_order:
    xor rax,rax
    and edx,3
    and esi,1
    and edi,1111b

    or eax,edi
    shl esi,7
    or eax,esi

    shl edx,5
    or eax,edx
    ret
global IDT_lidt
IDT_lidt:
    lidt [rdi]
    ret
global calc_mempos_idt
struc idt_e
    .addr_l   resw 1
    .selector resw 1
    .ist      resb 1
    .attr     resb 1
    .addr_m   resw 1
    .addr_h   resd 1
    .zero     resd 1
endstruc 
calc_mempos_idt:
    push rdx
    mov rax,0x0007FFFF
    push rax
    mov rax,idt_e_size
    mov rdx,256
    mul rdx
    mov rdx,rax
    pop rax
    sub rax,rdx
    pop rdx
    ret
global init_pageMem
[extern krnlController]
init_pageMem:
    mov [krnlController],rdi
    mov [rdi+_pager.base],word 0x1000
    mov rax,6
    mov [rdi+_pager.mapped],rax
    mov [rdi+_pager.pml4I],word 0
    mov [rdi+_pager.pdtI],word 3
    mov [rdi+_pager.pdpdI],word 0
    ret
global get_new_page_address
;rdi = base
;rsi = pm4lindex
;rdx = pdptIndex
get_new_page_address:
    std_open
    mov r9,0xfffff000
    mov rax,rsi
    mov r11,8
    push rdx
    mul r11
    pop rdx
    add rdi,rax
    mov rdi,[rdi] 
    and rdi,r9 ;*((uint16_t*)((pager->base & mask)+(pager->pml4Index*8)));

    mov rax,rdx
    push rdx
    mul r11
    pop rdx
    add rdi,rax
    mov rdi,[rdi]
    and rdi,r9
    mov rax,rdi
    push rax
    mov rax,rcx
    push rdx
    mul r11
    pop rdx
    mov rcx,rax
    pop rax
    add rax,rcx
    std_close
global assign_new_page
assign_new_page:
    push r14
    call get_new_page_address
    mov r14,r8
    or r14,r9
    mov [rax],r14
    pop r14
    ret
global display
;rdi = pager
;rsi = address
;rdx = pages 
;rcx = limit
[extern Page2Mb]
page:
    push r8
    push r9
    push r10
    cmp rdx,rcx
    jle .ppages  ;
    push rdx
    mov rdx,3    ;PRESENT & WRITE
    jmp .lenter
    .lloop:
        dec rcx
    .lenter:
        push rdi
        push rsi
        push rcx
        push rdx
        call Page2Mb
        pop rdx
        pop rcx
        pop rsi
        pop rdi
        add rsi,0x1000
    cmp rcx,0
    jg .lloop
    pop rdx
    mov rax,1
    jmp .END 
    .ppages:
        mov rcx,rdx
        mov rdx,3
        .ploop:
            push rcx
            push rdi
            push rsi
            push rdx
            call Page2Mb
            pop rdx
            pop rsi
            pop rdi
            pop rcx
            add rsi,0x1000
            loop .ploop
    .END:
    pop r10
    pop r9
    pop r8
    ret
;rdi = pager
;rsi = baddr
;rdx = pages
global setup_paging
setup_paging:
    std_open
    mov rcx,0x53
    call page
    sub rdx,0x53
    cmp rax,0
    je .EXIT
    mov rsi,0x00100000 
    mov rcx,0x500
    call page
    .EXIT:
    std_close
global pager__write__

global storeIfNull2Deref
;rsi = value
;rdi = ptr
storeIfNull2Deref:
    mov rax,[rdi]
    mov rax,[rax]
    cmp rax,0
    je .store
    mov rax,0
    jmp .end
    .store:
        mov rax,[rdi]
        mov [rax],rsi
        mov rax,1
    .end:
    ret
;rdi = base
;rsi = ptable
;rdx = flags
;rcx = physical
pager__write__:
    std_open
    mov r9,0xfffff000
    mov rdi,[rdi] ;base = *base
    xor rax,rax
    push rdx
    mov rax,8
    mul rsi
    pop rdx
    and rdi,r9
    add rdi,rax
    or rcx,rdx ;physical|=flags
    mov [rdi],rcx
    std_close
global find_apci
cmpStr:
    xor rax,rax
    cmp [rdi],byte 'R'
    je .o1
    jmp .no1
    .o1:
        or rax,1
    .no1:
    cmp [rdi+1],byte'S'
    je .o2
    jmp .no2
    .o2:
        or rax,2
    .no2:
    cmp [rdi+2],byte'D'
    je .o4
    jmp .no4
    .o4:
        or rax,4
    .no4:
    cmp [rdi+3],byte' '
    je .o8
    jmp .no8
    .o8:
        or rax,8
    .no8:
    cmp [rdi+4],byte'P'
    je .o16
    jmp .no16
    .o16:
        or rax,16
    .no16:
    cmp [rdi+5],byte'T'
    je .o32
    jmp .no32
    .o32:
        or rax,32
    .no32:
    cmp [rdi+6],byte'R'
    je .o64
    jmp .no64
    .o64:
        or rax,64
    .no64:
    cmp [rdi+7],byte' '
    je .o128
    jmp .no128
    .o128:
        or rax,128
    .no128:
    cmp rax,128+64+32+16+8+4+2+1
    je .found
    jmp .nfound
    .found:
        mov rax,1
        jmp .end
    .nfound:
        xor rax,rax
    .end:
    ret
find_apci:
    push rcx
    push rdx
    push r14
    xor r14,r14
    xor rcx,rcx
    xor rdx,rdx

    mov rcx,0x40E
    mov rdx,1000
._loop:
    push rdi
    mov rdi,rcx
    push rdx
    push rcx
    push r14
    call cmpStr
    pop r14
    pop rcx
    pop rdx
    pop rdi
    cmp rax,1
    je .Success
    cmp rdx,0
    je .Step
    jmp .nStep
    .Step:
        cmp r14,1
        je .Error
        jmp .Next
    .nStep:

    dec rdx
    inc rcx
    jmp ._loop
    .Success:
        mov [rdi],rcx
        mov rax,0
        jmp .End
    .Error:
        mov r14,0xFFFF
        mov [rdi],r14
        jmp .End
    .Next:
        mov r14,1
        mov rcx,0x000E0000
        mov rdx,0x000FFFFF - 0x000E0000
        jmp ._loop
    .End:
    pop r14
    pop rdx
    pop rcx
    ret
global w__div
w__div:
    push rdx
    mov rax,rdi
    div rsi
    pop rdx
    ret
struc vbe_bar
    .x            resw 1
    .y            resw 1
    .w            resw 1
    .h            resw 1
    .progress     resd 1
    .progressSize resw 1
endstruc
global setup_bar
;rdi = bar
;rsi = x
;rdx = y
;rcx = length
;r8 =  height
[extern vbeScaler]
setup_bar:
    push r10
    push r12
    xor r10,r10
    xor r12,r12
    mov r12d,[rdi+vbe_bar.progress]
    and r12d,(1<<31)
    cmp r12d,(1<<31)
    je .end
    mov r12b,[vbeScaler]
    shl r12,8
    or  r12d,(1<<31)
    mov [rdi+vbe_bar.x],si
    mov [rdi+vbe_bar.y],dx
    mov [rdi+vbe_bar.w],cx
    mov [rdi+vbe_bar.h],r8w
    mov [rdi+vbe_bar.progress],r12d
    push rdx
    xor rdx,rdx
    xor rax,rax
    mov ax,cx
    mov r10,10
    div r10
    pop rdx
    mov [rdi+vbe_bar.progressSize],ax
    .end:
    pop r12
    pop r10
    ret
global bar_getScaler
bar_getScaler:
    push r10
    xor r10,r10
    mov r10d,[rdi+vbe_bar.progress]
    and r10,0xFF00
    shr r10,8
    mov ax,r10w
    pop r10
    ret
global bar_replaceProgress
;rdi = bar
;rsi = new progress
bar_replaceProgress:
    push rcx
    mov eax,[rdi+vbe_bar.progress]
    mov rcx,rsi
    mov al,cl
    mov [rdi+vbe_bar.progress],eax
    pop rcx
    ret
;global unfoldVirtual
;;rdi = virtual
;;rsi = pml4
;;rdx = pdpt
;;rcx = pdt
;;r8  = pt
;unfoldVirtual:
;    push r9
;    push r10
;    push r11
;    mov r11,rdi ;virtual remaining
;
;    mov rax,r11
;    mov r10,0x8000000000
;    push rdx
;    xor rdx,rdx
;    div r10
;    pop rdx
;    mov [rsi],ax ;stores pml4
;
;    push rdx
;    mul r10
;    sub r11,rax ;remaining-=0x8000000000*pml4
;    pop rdx
;
;    mov rax,r11
;    mov r10,0x40000000
;    push rdx
;    xor rdx,rdx
;    div r10
;    pop rdx
;    mov [rdx],ax ;stores pdpt
;    
;    push rdx
;    mul r10
;    sub r11,rax ;remaining-=0x40000000*pdpt
;    pop rdx
;
;    mov rax,r11
;    mov r10,0x200000
;    push rdx
;    xor rdx,rdx
;    div r10
;    pop rdx
;    mov [rcx],ax ;stores pdt
;
;    push rdx
;    mul r10
;    sub r11,rax ;remaining-=0x200000*pdt
;    pop rdx
;
;    mov rax,r11
;    mov r10,0x1000
;    push rdx
;    xor rdx,rdx
;    div r10
;    pop rdx
;    mov [r8],ax ;stores pt
;
;    push rdx
;    mul r10
;    sub r11,rax ;remaining-=0x1000*pt
;    pop rdx
;
;    pop r11
;    pop r10
;    pop r9
;    ret

;SETUP void* maskInc(user_ptr addr,uint64_t __mask__,uint64_t increments)
;rdi = addr
;rsi = mask
;rdx = increments
global maskInc
maskInc:
    push rdi
    and rdi,rsi

    push rdx
    mov rax,8
    mul rdx
    pop rdx
    add rdi,rax
    mov rax,rdi
    pop rdi
    ret
struc page_deref
    .pml4 resq 1
    .pdpt resw 1
    .pdt  resw 1
    .pt   resw 1
endstruc 

;SETUP extern uint64_t* acm2(uint64_t* pml4,uint16_t pdpt);
;rdi = pml4
;si = pdpt
global acm2
acm2:
    push r9
    push r10
    push r11
    mov r9,0xFFFFF000

    mov rdi,[rdi]
    and rdi,r9   

    mov rdi,[rdi+rsi*8]
    and rdi,r9
    mov rax,rdi

    pop  r11
    pop  r10
    pop  r9
    ret
global testPaging
testPaging:
    mov rax,0xFFFFFFFF00000000
    mov rbx,[rax]
    mov rbx,[rax]
    ret
display:
    ret
large_regions: db "More than 20 Memory Regions.Can not access all Memory.",0,0x10