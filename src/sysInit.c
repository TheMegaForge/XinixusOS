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
    user_ptr list[] = {0x975000/*pml4*/,0x976000/*pdpt*/,0x977000/*pdt*/};
    VirtualPage4K(&list,0xFFFFFFFF00000000,0x66A000,PFLAG_PRESENT|PFLAG_WRITE);

    //for(int i = 0;i<787;i++){
    //    VirtualPage4K(&list,0xFFFFFFFF00000000+(i*0x1000),0x66A000+(i*0x1000),PFLAG_PRESENT|PFLAG_WRITE);
    //}
    setVBEScalar(1);
    vbeBlockyBarProgressBarAdvance(RGB(0,255,0),&bar);//shows that the system started
}