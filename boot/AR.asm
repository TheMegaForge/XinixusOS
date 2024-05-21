[bits 16]
[org 0x7e00]
setup:
    pop si
    mov ax,[0x998]
    push si
    mov si,AR_msg
    call ax
    pop si
    mov [retAddr],si
    push 0
    mov [sysInfo],sp
    
    call collectSIMD
    call collectSIMDFeatures
    call collectFeatures
    call collectMemory
    call activateAVX
    xor edi,edi

    mov ax,0xb101
    clc
    int 0x1A
    jc .nPCI

    cmp ah,0
    je .hPCI

    jmp .nPCI
    .hPCI:
        mov di,[sysInfo]
        and al,1
        cmp al,1 ;configuration space 1
        je .hConf1
        .hConf1:
            or [di],word 16384
        .nConf1:
    .nPCI:
    push sp
    call loadVESAInformation
    call loadEDID
    add sp,VesaInfoBlockSize
    call activateAVX
    call loadGDT
    call setupPaging
    mov si,[retAddr]
    push si
    ret
PageTableEntry equ 0x1000

retAddr: dw 0
;ebx = addr & flags
;edi = source
loadEDID:
    push ax
    push bx
    push cx
    push dx
    mov [0x700],dword 1
    mov ax,0x4F15
    mov bl,1
    xor cx,cx
    xor dx,dx

    mov di,0x700
    int 0x10
    cmp al,0x4F
    jne .ERROR
    cmp al,1
    je .ERROR
    jmp .END
    .ERROR:
        mov [0x700],dword 0xFFFFFFFF
    .END:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
setPageDirTable:
    push ecx
    mov ecx,512
    .SetEntry:
        mov dword [edi],ebx
        add ebx,0x1000
        add edi,8
        loop .SetEntry
    pop ecx
    ret
setupPaging:
    mov edi,PageTableEntry
    mov cr3,edi
    mov [PageTableEntry],dword 0x2003
    add edi,0x1000
    mov dword [0x2000],0x3003
    add edi,0x1000
    mov dword [0x3000],0x4003
    mov dword [edi+8],0x5003
    mov dword [edi+16],0x6003
    add edi,0x1000
    mov ebx,3

    call setPageDirTable
    mov ebx,0x200003
    call setPageDirTable

    mov ebx,0x400003
    call setPageDirTable

    mov eax,cr4
    or eax,1<<5
    mov cr4,eax
    mov ecx,0xC0000080
    rdmsr
    or eax,1<<8
    wrmsr
    mov eax,cr0
    or eax,1<<31|1
    mov cr0,eax
    ret
activateAVX:
    push di
    push cx
    mov di,[sysInfo]
    mov cx,[di]
    push cx

    and cx,2
    cmp cx,2
    jne .dAVX
    mov cx,[di]
    and cx,512
    cmp cx,512
    jne .dAVX
    xor ecx,ecx
    xgetbv
    or eax,7
    xsetbv
    jmp .exit
.dAVX:
    mov cx,[di]
    and cx,1111111001111111b ;deactivates avx & avx 2
    mov [di],cx
.exit:
    pop cx
    pop cx
    pop di
    ret
collectFeatures:
    push eax
    push edx
    push ecx
    push ebx
    push edi
    mov di,[sysInfo]
    mov eax,1
    cpuid

    test ecx,0b01000000000000000000000000000000
    jnz .hRDRAND
    jmp .nRDRAND
    .hRDRAND:
        or [di],word 2048
    .nRDRAND:

    test edx,1
    jnz .hFPU
    jmp .nFPU
    .hFPU:
        or [di],word 4096
    .nFPU:
    test edx,1<<11
    jnz .hSYSCALL
    jmp .nSYSCALL
    .hSYSCALL:
        or [di],word 8192
    .nSYSCALL:

    pop edi
    pop ebx
    pop ecx
    pop edx
    pop eax
    ret
collectSIMDFeatures:
    push eax
    push edx
    push ecx
    push ebx
    push edi
    mov di,[sysInfo]
    mov eax,1
    cpuid

    test ecx,1<<26
    jnz .hXSAVE
    jmp .nXSAVE
    .hXSAVE:
        mov eax,cr4
        or eax,1<<18
        mov cr4,eax
        or [di],word 512
    .nXSAVE:

    test ecx,1<<11
    jnz .hXOP
    jmp .nXOP
    .hXOP:
        or [di],word 1024
    .nXOP:
    
    pop edi
    pop ebx
    pop ecx
    pop edx
    pop eax
    ret
collectSIMD:
    push eax
    push edx
    push ecx
    push ebx
    push edi
    mov di,[sysInfo]
    mov [0x990],di
    mov eax,1
    cpuid
    test edx,1<<23
    jnz .hMMX
    jmp .nMMX
    .hMMX:
        or [di],word 1
    .nMMX:
    test edx,1<<25
    jnz .hSSE
    jmp .nSSE
    .hSSE:
        push eax
        mov eax,cr0
        and ax,0xFFF8
        or ax,0x2
        mov cr0,eax
        mov eax,cr4
        or ax,3 << 9
        mov cr4,eax
        pop eax
        or [di],word 2
    .nSSE:

    test edx,1<<26
    jnz .hSSE2
    jmp .nSSE2
    .hSSE2:
        or [di],word 4
    .nSSE2:

    test ecx,1
    jnz .hSSE3
    jmp .nSSE3
    .hSSE3:
        or [di],word 8
    .nSSE3:

    test ecx,1<<19
    jnz .hSSE4_1
    jmp .nSSE4_1
    .hSSE4_1:
        or [di],word 16
    .nSSE4_1:
    
    test ecx,1<<20
    jnz .hSSE4_2
    jmp .nSSE4_2
    .hSSE4_2:
        or [di],word 32
    .nSSE4_2:

    test ecx,1<<9
    jnz .hSSSE
    jmp .nSSSE
    .hSSSE:
        or [di],word 64
    .nSSSE:
    
    test ecx,1<<28
    jnz .hAVX
    jmp .nAVX
    .hAVX:
        or [di],word 128
    .nAVX:

    mov eax,0x00000007
    xor ebx,ebx
    cpuid
    test ebx,1<<5
    jnz .hAVX2
    jmp .nAVX2
    .hAVX2:
        or [di],word 256
    .nAVX2:
    pop edi
    pop ebx
    pop ecx
    pop edx
    pop eax
    ret
collectMemory:
    pusha
    mov ebx,0
    xor esi,esi
    xor edx,edx
    xor ecx,ecx
    xor ebx,ebx
    xor eax,eax
    mov [0x996],word 0
.LOOP:
    mov eax,0x0000E820
    mov edx,0x534D4150
    mov ecx,24
    mov di,0x700
    add di,128
    add di,si
    int 0x15
    jc  .ERROR
    cmp ebx,0
    je .EXIT
    xor di,di
    add si,24
    inc word [0x996]
    jmp .LOOP
    .ERROR:
        mov si,MEM_ERROR_MSG
        mov di,[0x998]
        call di
        cli
        hlt
    .EXIT:
    popa
    ret
sysInfo: dw 0
loadGDT:
    push eax
    push ebx
    push ecx
    cli
    mov eax,cr0
    or eax,1
    mov cr0,eax
    mov ecx,GDT_END
    sub ecx,gdt_start
    dec ecx
    mov [GDT_DESC],cx
    mov ebx,gdt_start
    mov [GDT_DESC+2],ebx
    lgdt [GDT_DESC]
    pop ecx
    pop ebx
    pop eax
    ret
MEM_ERROR_MSG: db "Bios Memory function not supported.OS can not start!",0x0A,0x0D,0
struc VesaInfoBlock				    ;VesaInfoBlock_size = 512 bytes
	.Signature		        resb 4  ;must be 'VESA'
	.Version		        resw 1
	.OEMNamePtr		        resd 1
	.Capabilities		    resd 1
	.VideoModesOffset	    resw 1
	.VideoModesSegment	    resw 1
	.CountOf64KBlocks	    resw 1 ; <- Memory
	.OEMSoftwareRevision	resw 1
	.OEMVendorNamePtr	    resd 1
	.OEMProductNamePtr	    resd 1
	.OEMProductRevisionPtr	resd 1
	.Reserved		        resb 222
	.OEMData		        resb 256 
endstruc
struc VesaModeInfoBlock				    ;	VesaModeInfoBlock_size = 256 bytes
	.ModeAttributes		    resw 1
	.FirstWindowAttributes	resb 1
	.SecondWindowAttributes	resb 1
	.WindowGranularity	    resw 1		;	in KB
	.WindowSize		        resw 1		;	in KB
	.FirstWindowSegment	    resw 1		;	0 if not supported
	.SecondWindowSegment	resw 1		;	0 if not supported
	.WindowFunctionPtr	    resd 1
	.BytesPerScanLine	    resw 1
 
	;	Added in Revision 1.2
	.Width			        resw 1		;	in pixels(graphics)/columns(text)
	.Height			        resw 1		;	in pixels(graphics)/columns(text)
	.CharWidth		        resb 1		;	in pixels
	.CharHeight		        resb 1		;	in pixels
	.PlanesCount		    resb 1
	.BitsPerPixel		    resb 1
	.BanksCount		        resb 1
	.MemoryModel		    resb 1		;	http://www.ctyme.com/intr/rb-0274.htm#Table82
	.BankSize		        resb 1		;	in KB
	.ImagePagesCount	    resb 1		;	count - 1
	.Reserved1		        resb 1		;	equals 0 in Revision 1.0-2.0, 1 in 3.0
 
	.RedMaskSize		    resb 1
	.RedFieldPosition	    resb 1
	.GreenMaskSize		    resb 1
	.GreenFieldPosition	    resb 1
	.BlueMaskSize		    resb 1
	.BlueFieldPosition	    resb 1
	.ReservedMaskSize	    resb 1
	.ReservedMaskPosition	resb 1
	.DirectColorModeInfo	resb 1
 
	;	Added in Revision 2.0
	.LFBAddress		        resd 1
	.OffscreenMemoryOffset	resd 1
	.OffscreenMemorySize	resw 1		;	in KB
	.Reserved2		        resb 206	;	available in Revision 3.0, but useless for now
endstruc
VesaInfoBlockSize equ VesaInfoBlock_size
VesaModeInfoBlockSize equ VesaModeInfoBlock_size
loadVESAInformation:
    pop si
    mov [0x502],si
    xor edi,edi
    pop di ;stack
    sub di,VesaInfoBlockSize
    mov eax,0x4F00
    int 0x10
    mov bx,0
    mov ds,bx
    mov es,bx
    mov bp,0x7c00
    cmp al,0x4F
    jne .nVBE
    cmp ah,1
    je .nVBE
    .hVBE:
        mov dx,[di+VesaInfoBlock.Version]
        cmp dx,word 0x200 
        je .sVBE2
        jmp .nVBE2
        .sVBE2:
            or [0x500],word 2
            jmp .End
        .nVBE2:
            cmp dx,word 0x300
            je .sVBE3
            jmp .nVBE3
        .sVBE3:
            or [0x500],word 4
        .nVBE3:
        .End:
        jmp .Exit
    .nVBE:
        mov [0x500],word 0xF000 ;either no support or vbe 1.0
        mov [0x506],word 0xFFFF
        jmp .Close
    .Exit:
    call findFittingMode
    mov [0x506],di
    call activateVBE
    .Close:
    mov si,[0x502]
    push si
    ret
activateVBE:
    push ax
    push cx
    push bx
    mov bx,[0x508]
    cmp bx,0xFFFF
    je .Error
    or bx,(1<<14)
    mov cx,[0x500]
    cmp cx,3
    je .Error
    mov ax,0x4F02
    int 0x10
    cmp al,0x4F
    jne .Error
    cmp ah,1
    je .Error
    jmp .Exit
    .Error:
        or [0x500],word 16
    .Exit:
    pop bx
    pop cx
    pop ax
    ret
checkMode:
    push esi
    push ebx
    push ecx
    xor esi,esi
    xor ebx,ebx
    mov eax,0x4F01
    mov di,0x600
    int 0x10
    xor ecx,ecx
    cmp al,0x4F
    jne .nSupport
    jmp .hSupport ;Error
    .nSupport:
        mov al,2
        pop ecx
        pop ebx
        pop esi
        ret
    .hSupport:
    cmp ah,0
    jne .nSupport ;Error
    mov dx,[di+VesaModeInfoBlock.ModeAttributes]
    and dx,0000000010011001b ;right attributs
    cmp dx,0000000010011001b
    jne .nUse

    mov dl,[di+VesaModeInfoBlock.BitsPerPixel]
    cmp dl,32
    jne .nUse
    mov dx,[di+VesaModeInfoBlock.Width]
    cmp dx,1024
    jne .nUse
    mov dx,[di+VesaModeInfoBlock.Height]
    cmp dx,768
    jne .nUse
    mov dx,[di+VesaModeInfoBlock.BytesPerScanLine]
    cmp dx,0
    je .nUse
    jmp .Use
    .nUse:
        xor al,al
        jmp .Close
    .Use:
        mov al,1
    .Close:
    pop ecx
    pop ebx
    pop esi
    ret
findFittingMode:
    mov [0x504],word 0
    mov [0x508],word 0xFFFF
    mov bx,[di+VesaInfoBlock.VideoModesOffset] 
    mov cx,[di+VesaInfoBlock.VideoModesSegment] 
    mov gs,cx
.__loop:
    mov cx,gs:[bx]
    cmp cx,0xFFFF
    je .Exit
    call checkMode
    cmp al,2
    je .Error
    cmp al,1
    je .Exit ; found
    add bx,2
    jmp .__loop
    .Error:
        or [0x504],word 1
    .Exit:
        mov [0x508],cx  ;used mode,info about mode is in buffer 0x600
    xor ax,ax
    mov gs,ax
    ret

gdt_start:
    null_descriptor:
        dd 0
        dd 0
    krnl_code_gdt:
        dw 0xFFFF;16 bit of limit
        dw 0
        db 0     ;24 bit of base

        db 10011010b
        ; 1001 1010
        ; 1001-|--> 
        ;      |   4th : present 
        ;      |   3&2 : privilege (0 = ring,2 = driver(maybe) ,3 = user)
        ;      |   1   : type (1 = code or  data)
        ;      1010 -> 
        ;         4th : code if 1
        ;         3th : Conforming (can lower privilege segments execute this code) if 1
        ;         2th : Readable   (when code descriptor,can read constants) if 1
        ;         1th : Accessed   (Managed by the cpu,set to 0 always) if 1
        db 10101111b 
        ;  1010 1111
        ;  1010-|->
        ;       |   4th : granularity (limit is multiplied by 0x1000) if 1        
        ;       |   3th : 32bit (should not be set if the OS is 64 bit) if 1
        ;       |   2th : long mode(indicated that this descriptor is 64 bit) if 1
        ;       |   0th : Reserved 
        ;       1111 -> 
        ;         other 4 bits of the limit (limit is 20 bits)
        db 0
    krnl_data_gdt:
        dw 0xFFFF
        dw 0
        db 0
        db 10010010b
        ;  1001 0010 
        ;  1001-|-> 
        ;       |   4th : present 
        ;       |   3&2 : privilege (0 = ring,2 = driver(maybe) ,3 = user)
        ;       |   1   : type (1 = code or  data)
        ;       0010 -> 
        ;           4th : data if 0
        ;           3th : direction (when 1 segment grows downwards) if 0 than grows upwards
        ;           2th : writable (when 1 than the segment can be read and can be written to) if 0 than read only
        ;           1th : Accessed   (Managed by the cpu,set to 0 always) if 1
        db 10101111b
        ;  1010 1111
        ;  1010-|->
        ;       |   4th : granularity (limit is multiplied by 0x1000) if 1        
        ;       |   3th : 32bit (should not be set if the OS is 64 bit) if 1
        ;       |   2th : long mode(indicated that this descriptor is 64 bit) if 1
        ;       |   0th : Reserved 
        ;       1111 -> 
        ;         other 4 bits of the limit (limit is 20 bits)
        db 0
    user_code_gdt:
        dw 0xFFFF
        dw 0
        db 0
        db 11111110b
        db 10101111b
        db 0
    user_data_gdt:
        dw 0xFFFF
        dw 0
        db 0 
        db 11110010b
        db 10101111b
        db 0
    drv_code_gdt:
        dw 0xFFFF
        dw 0
        db 0
        db 11011110b ;user space can execute this
        db 10101111b
        db 0
    drv_data_gdt:
        dw 0xFFFF
        dw 0
        db 0
        db 11010000b ;read only
        db 10101111b 
        db 0
GDT_END:
GDT_DESC:
    dw 55       ;size
    dd gdt_start
AR_msg: db "ARSN 1",0x0A,0x0D,0
times 1536-($-$$) db 0