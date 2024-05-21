#include <formating.h>
#include <stdbool.h>
#include <memory.h>
#include <stddef.h>
#include <UOSI.h>
#include <stdio.h>
#include <HAL.h>
#include <stdbool.h>
#include <IDT.h>
#include <memdefs.h>
/**
 * @brief 
 *  pages x pages,where
 *  x can be limit or pages
 * @return returns true if the limit was accessed
 */
SETUP_DATA struct _UOSI sysDesc;
SETUP extern bool64 setup_paging(PageController* pager,void* baddr,uint64_t pages);
SETUP extern void sysInit();
SETUP extern void testPaging();
SETUP struct _UOSI* getUOSI(){
    return &sysDesc;
}
SETUP_INIT extern void setup(){
    if(*(uint16_t*)0x506 == 0xFFFF){
        char* buffer = (char*)0xb8000;
        *buffer = 'E';
        *(buffer+2) = 'R';
        *(buffer+4) = 'R';
        *(buffer+6) = 'O';
        *(buffer+8) = 'R';
        *(buffer+10) = '!';
        __asm__("cli;hlt");
    }
    init_memInfo(&sysDesc.uoi_memory);
    if(sysDesc.uoi_memory.available < 64){
        __asm__("cli;hlt");
    }
    SIMD_init(&sysDesc.SIMDselected,&sysDesc.SIMDsize);
    init_pageMem(&sysDesc.uoi_paged);
    int pages = sysDesc.uoi_memory.available/MB(2);
    void* paddr = STACK_BEG;
    setup_paging(&sysDesc.uoi_paged,paddr,pages);
    HAL_init();
    sysDesc.uoi_memory.available-=(KB(1022)+2018); 
    pages+=1*((sysDesc.uoi_memory.available % MB(2)) != 0);
    user_ptr framebufferPut[] = {VBE_LFT_PAGE_SPACE,VBE_LFT_PAGE_SPACE+0x1000,VBE_LFT_PAGE_SPACE+0x2000,VBE_LFT_PAGE_SPACE+0x3000};
    uint64_t fb = (uint64_t)getFramebuffer();
    uint64_t addr = VBE_LFB;
    for(int i = 0;i<787;i++){
        VirtualPage4K(&framebufferPut,addr,fb,PFLAG_PRESENT|PFLAG_WRITE);
        fb+=0x1000;
        addr+=0x1000;
    }
    sysDesc.uoi_memory.system = MB(100);
    sysDesc.uoi_memory.user   = sysDesc.uoi_memory.available-sysDesc.uoi_memory.system;
    sysInit();
    testPaging();
    while(true){}
}
SETUP extern void display(uint64_t show);