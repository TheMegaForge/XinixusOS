#include <pixelation.h>
#include <memory.h>
SETUP extern void display(uint64_t setup);
SETUP void sysInit(){
    clsVBE(RGB(255,255,255));
    vbeBar bar;
    setVBEScalar(3);
    bar.progress = 0;
    vbeInitBlockyProgressBar(&bar,30,getVBEHeight()-50,getVBEWidth()-60,30);
    display(bar.advancementSize);
    user_ptr list[] = {PAGE_0x66A000_STORE_PML4,PAGE_0x66A000_STORE_PDPT,PAGE_0x66A000_STORE_PDT,PAGE_0x66A000_STORE_PT};
    uint64_t* ptr = PAGE_0x66A000_STORE_PT; 
    for(int i = 0;i<787;i++){
        VirtualPage4K(&list,PAGE_0x66A000+(i*0x1000),0x66A000+(i*0x1000),PFLAG_PRESENT|PFLAG_WRITE);
    }
    setVBEScalar(1);
    vbeBlockyBarProgressBarAdvance(RGB(0,255,0),&bar);//shows that the system started
}