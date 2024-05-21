#pragma once
#include <formating.h>
#include <stdint.h>
struct vbeModeInfo {
	uint16_t attributes;		// deprecated, only bit 7 should be of interest to you, and it indicates the mode supports a linear frame buffer.
	uint8_t window_a;			// deprecated
	uint8_t window_b;			// deprecated
	uint16_t granularity;		// deprecated; used while calculating bank numbers
	uint16_t window_size;
	uint16_t segment_a;
	uint16_t segment_b;
	uint32_t win_func_ptr;		// deprecated; used to switch banks from protected mode without returning to real mode
	uint16_t pitch;			// number of bytes per horizontal line
	uint16_t width;			// width in pixels
	uint16_t height;			// height in pixels
	uint8_t w_char;			// unused...
	uint8_t y_char;			// ...
	uint8_t planes;
	uint8_t bpp;			// bits per pixel in this mode
	uint8_t banks;			// deprecated; total number of banks in this mode
	uint8_t memory_model;
	uint8_t bank_size;		// deprecated; size of a bank, almost always 64 KB but may be 16 KB...
	uint8_t image_pages;
	uint8_t reserved0;
 
	uint8_t red_mask;
	uint8_t red_position;
	uint8_t green_mask;
	uint8_t green_position;
	uint8_t blue_mask;
	uint8_t blue_position;
	uint8_t reserved_mask;
	uint8_t reserved_position;
	uint8_t direct_color_attributes;
 
	uint32_t framebuffer;		// physical address of the linear frame buffer; write here to draw to the screen
	uint32_t off_screen_mem_off;
	uint16_t off_screen_mem_size;	// size of memory in the framebuffer but not being displayed on the screen
	uint8_t  reserved1[206];
} __attribute__ ((packed));
#define RGB(r,g,b) (uint32_t)(((b) | (g << 8) | (r << 16)))
typedef struct{
	uint32_t foreground;
	uint32_t background;
}PixelFormat;
typedef struct{
	uint16_t x,y;
	uint16_t w,h;
	uint32_t  progress;
	uint16_t advancementSize;
}vbeBar;
SETUP void setVBEScalar(uint8_t scaler);
SETUP uint32_t getVBEHeight();
SETUP uint32_t getVBEWidth();
SETUP void init_pixalation();
SETUP uint32_t* getFramebuffer();
SETUP void put_pixel(int x,int y,uint32_t color);
SETUP void put_char(int x,int y,PixelFormat* format);
SETUP void clsVBE(uint32_t color);
SETUP void vbeDrawLine(uint8_t width,uint32_t color,uint16_t beginX,uint16_t beginY,uint16_t length);
SETUP void vbeDrawRect(uint16_t length,uint16_t height,uint32_t color,uint16_t x,uint16_t y);
SETUP void vbeDrawHorizontalLine(uint8_t width,uint32_t color,uint16_t beginX,uint16_t beginY,uint16_t length);
SETUP void vbeInitBlockyProgressBar(vbeBar* bar,uint16_t x,uint16_t y,uint16_t length,uint16_t height);
SETUP uint8_t vbeBlockyBarProgressBarAdvance(uint32_t color,vbeBar* bar);