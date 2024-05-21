#include <pixelation.h>
#include <memory.h>
SETUP_DATA uint32_t* framebuffer;
SETUP_DATA uint32_t* ppaddr;
SETUP_DATA uint8_t  charHeight;
SETUP_DATA uint8_t  charWidth;
SETUP_DATA uint32_t width;
SETUP_DATA uint32_t height;
SETUP_DATA uint8_t  pitch;
SETUP_DATA uint8_t  vbeScaler;
SETUP extern void display(uint64_t d);
SETUP void init_pixalation(){
    struct vbeModeInfo* info = (struct vbeModeInfo*)0x600;
    framebuffer              = (uint32_t*)info->framebuffer;
    width                    = info->width;
    height                   = info->height;
    pitch                    = info->pitch;
    display(pitch);
    pitch+=1*(pitch == 0);
    charHeight = 0;
    charWidth  = 0;
    ppaddr = VBE_LFB;
    display(info->memory_model);
}

SETUP void setVBEScalar(uint8_t scaler){
    vbeScaler = scaler;
}
SETUP uint32_t getVBEHeight(){
    return height;
}
SETUP uint32_t getVBEWidth(){
    return width;
}
SETUP uint32_t* getFramebuffer(){
    return framebuffer;
}
SETUP void put_pixel(int x,int y,uint32_t color){
    int offset = (y * pitch) * width;
    ppaddr[offset + x] = color;
}

SETUP void clsVBE(uint32_t color){
    for(int i = 0;i<height;i++){
        for(int j = 0;j<width;j++){
            put_pixel(j,i,color);
        }
    }
}
SETUP void vbeDrawLine(uint8_t width,uint32_t color,uint16_t beginX,uint16_t beginY,uint16_t length){
    for(int i = 0;i<length;i++){
        for(int j = 0;j<width;j++){
            put_pixel(beginX+i,beginY+j,color);
        }
    }
}
SETUP void vbeDrawHorizontalLine(uint8_t width,uint32_t color,uint16_t beginX,uint16_t beginY,uint16_t length){
    for(int i = 0;i<length;i++){
        for(int j = 0;j<width;j++){
            put_pixel(beginX+j,beginY-i,color);
        }
    }
}
SETUP void vbeDrawRect(uint16_t length,uint16_t height,uint32_t color,uint16_t x,uint16_t y){
    for(int i = 0;i<length;i++){
        for(int j = 0;j<height;j++){
            put_pixel(x+i,y+j,color);
        }
    }
}
SETUP extern uint8_t bar_getScaler(vbeBar* bar);
SETUP extern uint8_t bar_replaceProgress(vbeBar* bar,uint8_t newProgress);
SETUP extern void setup_bar(vbeBar* bar,uint16_t x,uint16_t y,uint16_t length,uint16_t height);
SETUP void vbeInitBlockyProgressBar(vbeBar* bar,uint16_t x,uint16_t y,uint16_t length,uint16_t height){
    setup_bar(bar,x,y,length,height);
    if(length == 0 || height == 0){
        bar->progress|=(1<<22);
        return;
    }
    vbeDrawLine(vbeScaler,0,x,y-vbeScaler,length);
    vbeDrawLine(vbeScaler,0,x,y+(height-vbeScaler),length);
    vbeDrawHorizontalLine(vbeScaler,0,x,y+(height-vbeScaler),height);
    vbeDrawHorizontalLine(vbeScaler,0,x+length,y+(height-vbeScaler)+(vbeScaler-1),height+vbeScaler);
}

SETUP uint8_t vbeBlockyBarProgressBarAdvance(uint32_t color,vbeBar* bar){
    if(bar->progress & (1<<31) == 0)return 0;
    uint8_t scaler = bar_getScaler(bar);
    vbeDrawRect(bar->advancementSize,bar->h-scaler,color,bar->x+((bar->progress & 0b1111)*bar->advancementSize)+scaler,bar->y);
    bar->progress++;
    bar_replaceProgress(bar,(bar->progress & 0b1111) % 10);
    return bar->progress & 0b1111;
}