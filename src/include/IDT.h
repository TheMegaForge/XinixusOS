#pragma once
#include <formating.h>
#include <stdint.h>
#include <stdbool.h>
typedef struct e_idt{
   uint16_t addr_low;        // offset bits 0..15
   uint16_t selector;        // a code segment selector in GDT or LDT
   uint8_t  ist;             // bits 0..2 holds Interrupt Stack Table offset, rest of bits zero.
   uint8_t  type_attributes; // gate type, dpl, and p fields
   uint16_t addr_middle;      // offset bits 16..31
   uint32_t addr_top;        // offset bits 32..63
   uint32_t zero;            // reserved
}__attribute__((packed)) IDT_entry;
typedef struct {
    uint16_t limit;
    IDT_entry* data;
}__attribute__((packed)) IDT_Descriptor;
typedef enum {
    ICT_INT  = 0b1110,
    ICT_TRAP = 0b1111,
}IDT_callType;
SETUP extern  void IDT_lidt(IDT_Descriptor* descriptor);
SETUP void IDT_load();
SETUP void IDT_makeEntry(struct e_idt* entry,void* addr,uint16_t selector,IDT_callType ctype,bool present,uint8_t privilege);