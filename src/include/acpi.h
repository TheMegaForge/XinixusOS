#pragma once
#include <stdint.h>
#include <formating.h>
typedef struct{

}RSDT;
typedef struct _RSDP{
    char    signature[8];
    uint8_t checksum;
    char    OEMID[8];
    uint8_t revision;
    RSDT*   rsdt;
}__attribute__((packed)) RSDP;
SETUP extern void find_apci(struct _RSDP** rsdp);
SETUP  void init_rsdp(struct _RSDP** rsdp);