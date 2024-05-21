#pragma once
/*
    United Operation Software Information
*/
#include "memory.h"
#include <extensions/simd.h>
#include <pixelation.h>
#include <acpi.h>
typedef struct _UOSI{
    PageController uoi_paged;
    MemoryController uoi_memory;
    SIMDState SIMDselected;
    uint8_t   SIMDsize;
    struct _RSDP* rsdp;
}UOSI;
SETUP struct _UOSI* getUOSI();
