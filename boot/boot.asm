[org 0x7c00]
[bits 16]
start:
    mov [hd],cl ; drive
    mov ax,0
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov sp,0x7c00
    mov bp,sp
    mov ss,ax
    push ax
    jmp 0x0:main
puts:
    push si
    push ax
    .loop:
        lodsb
        or al,al
        jz .done
        mov ah,0x0e
        int 0x10
        jmp .loop
    .done:
        pop ax
        pop si
        ret
hasCpuId:
    pushfd
    pop eax
    mov ecx,eax
    xor eax,1<<21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax,ecx
    jz noCPUID
    ret
noCPUID:
    mov si,bootError
    call puts 
    hlt
hasLongMode:
    mov eax,0x80000001
    cpuid
    test edx,1<<29
    jz noLongMode
    ret
noLongMode:
    mov si,bootError
    call puts 
    hlt
readDiskBasic:
    pop si
    pop bx
    push dx
    push cx
    push ax
    push ebp
    mov ebp,esp
    sub esp,2 ;init stack
    mov [ebp-2],word 3
    .Rloop:
        mov dh,0
        mov dl,[hd]
        or dl,1<<7
        mov ch,0
        mov ah,2
        int 0x13
        dec word [ebp-2]
        cmp [ebp-2],word 0
        je .Error
        jc .Retry
        jmp .REnd
    .Retry:
        xor ah,ah
        jmp .Rloop
    .Error:
        mov si,bootError
        call puts
        mov ah,0x0
        int 0x16
        jmp 0xFFFF:0
    .REnd:   
    add esp,2 ;clear stack
    mov esp,ebp
    pop ebp
    pop ax
    pop cx
    pop dx
    push si
    ret
EnableA20:
    call A20WaitInput
    mov al, KbdControllerDisableKeyboard
    out KbdControllerCommandPort, al

    ; read control output port
    call A20WaitInput
    mov al, KbdControllerReadCtrlOutputPort
    out KbdControllerCommandPort, al

    call A20WaitOutput
    in al, KbdControllerDataPort
    push eax

    ; write control output port
    call A20WaitInput
    mov al, KbdControllerWriteCtrlOutputPort
    out KbdControllerCommandPort, al
    
    call A20WaitInput
    pop eax
    or al, 2                                    ; bit 2 = A20 bit
    out KbdControllerDataPort, al

    ; enable keyboard
    call A20WaitInput
    mov al, KbdControllerEnableKeyboard
    out KbdControllerCommandPort, al

    call A20WaitInput
    ret
A20WaitInput:
    ; wait until status bit 2 (input buffer) is 0
    ; by reading from command port, we read status byte
    in al, KbdControllerCommandPort
    test al, 2
    jnz A20WaitInput
    ret
A20WaitOutput:
    ; wait until status bit 1 (output buffer) is 1 so it can be read
    in al, KbdControllerCommandPort
    test al, 1
    jz A20WaitOutput
    ret
hasAPIC:
    mov eax,1
    cpuid
    test edx,(1<<9)
    jz .Error
    jmp .nError
    .Error:
        mov si,no_apic
        call puts
        cli 
        hlt
    .nError:
    ret
main:
    mov [0x998],word puts
    mov si,BootMSG
    call puts
    call hasCpuId
    call hasLongMode
    call hasAPIC
    call EnableA20
    ;has Long mode
    mov al,32
    mov cl,5
    push 0x8400
    call readDiskBasic ;c-code
    mov al,3
    mov cl,2
    push 0x7e00
    call readDiskBasic ;AR
    call 0x7e00        ; loads gdt and collects system information
    jmp 0x8:reload_segments
[bits 64]
reload_segments:
    xor eax,eax
    mov ax,16
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov rsp,0x283FE+0xFA0
    mov rbp,rsp
    jmp 0x8400
[bits 16]
KbdControllerDataPort               equ 0x60
KbdControllerCommandPort            equ 0x64
KbdControllerDisableKeyboard        equ 0xAD
KbdControllerEnableKeyboard         equ 0xAE
KbdControllerReadCtrlOutputPort     equ 0xD0
KbdControllerWriteCtrlOutputPort    equ 0xD1
hd: db 0
BootMSG: db "Entered Booting",0x0A,0x0D,0
bootError: db "OS Can not start",0x0A,0x0D,0
no_apic: db "No APIC present.Booting Halted."0xA,0xD,0
times 510-($-$$) db 0
dw 0xAA55