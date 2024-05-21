#pragma once

#define MEM2_MAX  (void*)0x0007FFFF
#define MEM2_MIN  (void*)0x00007E00
#define MEM3_MIN  (void*)0x00100000
#define MEM3_MAX  (void*)0x00EFFFFF


#define STACK_BEG (void*)0x0002A000


#define VBE_LFT_PAGE_SPACE (void*)0x668000
#define VBE_LFB   (void*)0x66A000
#define VBE_LFT_PAGE_END (void*)0x974520

#define PAGE_0x66A000_STORE_PML4      (void*)0x975000
#define PAGE_0x66A000_STORE_PDPT      (void*)0x976000
#define PAGE_0x66A000_STORE_PDT       (void*)0x977000 //1 pdp = 2097152 Byte ~ 2 MB VBE_LFB =~ 3.223552 MB or 1 PDT
#define PAGE_0x66A000_STORE_PT        (void*)0x979000
// alternate addresses to access the addresses

#define PAGE_0x66A000 (void*)0xFFFFFFFF00000000
#define PAGE_0x66A000_LEN 0x30A520
#define PAGE_PROPERTY(addr) PAGE_#addr (void*)#addr