#pragma once
#include "formating.h"
#include "stdint.h"
#include <memdefs.h>
typedef struct _PageCntrl{
    uint64_t    mappedMBs;
    loader_ptr  base;
    uint16_t    pml4Index; 
    uint16_t    pdptIndex; 
    uint16_t    pdtIndex;
}PageController;
typedef enum {
    MRT_USABLE           = 1,
    MRT_RESERVED         = 2,
    MRT_ACPI_RECLAIMABLE = 3,
    MRT_NVS              = 4,
    MRT_BAD_MEMORY       = 5
}MemoryType;
typedef struct m_range{
    uint64_t base;
    uint64_t length;
    MemoryType type;
}__attribute__((packed)) MemoryRegion;
typedef struct _memCntrl{
    uint64_t available;
    uint8_t  usedSegments;
    MemoryRegion segments[20];
    uint64_t    system;
    uint64_t    user;
}MemoryController;
#define PFLAG_PRESENT 1
#define PFLAG_WRITE   2
#define PFLAG_USER    4
#define PFLAG_XD      (1 << 62)
#define KB(x)   (x*1000)
#define MB(x)   (KB(x)*1000)
SETUP void init_memInfo(MemoryController* controller);
SETUP extern void init_pageMem(PageController* pager);
SETUP void* unfoldMapped(PageController* pager);
SETUP void* VirtualPage4K(user_ptr* store,user_ptr virtual,user_ptr physical,uint64_t flags);
//SETUP extern void  translateVirtual(user_ptr virtual,uint64_t* pd,uint64_t* pt);
SETUP void Page2Mb(PageController* pager,user_ptr store,uint64_t flags);