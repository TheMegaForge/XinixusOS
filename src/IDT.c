#include <IDT.h>
#include <memdefs.h>
#include <idt_errors.h>
SETUP_DATA static IDT_Descriptor descriptor = {(sizeof(IDT_entry)*256)-1,MEM2_MAX-((sizeof(IDT_entry)*256))};
SETUP_CONST const uint16_t sys_formats = 1;
SETUP_CONST const uint16_t sys_exceptions = 0;
SETUP extern struct e_idt* calc_mempos_idt();
SETUP void IDT_load(){
    struct e_idt* entries = calc_mempos_idt();
    for(int i = 0;i<256;i++){
        IDT_makeEntry(&entries[i],0,8,ICT_TRAP,false,0);
    }
    IDT_makeEntry(&entries[0],division_error,8,ICT_TRAP,true,0);
    IDT_makeEntry(&entries[4],overflow_error,8,ICT_TRAP,true,0);
    IDT_makeEntry(&entries[6],opcode_error,8,ICT_TRAP,true,0);
    IDT_makeEntry(&entries[13],general_error,8,ICT_TRAP,true,0);
    IDT_makeEntry(&entries[14],page_error,8,ICT_TRAP,true,0);
    IDT_makeEntry(&entries[100],sysexc_handler,8,ICT_INT,true,2);
    IDT_makeEntry(&entries[101],sysfrmt_handler,8,ICT_INT,true,3);
    IDT_lidt(&descriptor);
}
SETUP extern uint8_t shift_into_order(IDT_callType ctype,bool present,uint8_t privilege);
SETUP void IDT_makeEntry(struct e_idt* entry,void* addr,uint16_t selector,IDT_callType ctype,bool present,uint8_t privilege){
    entry->selector        = selector;
    entry->addr_low        = (uint64_t)addr & 0xFFFF;
    entry->addr_middle     = (uint64_t)addr & 0xFFFF0000;
    entry->addr_top        = (uint64_t)addr & 0xFFFFFFFF00000000;
    entry->type_attributes = shift_into_order(ctype,present,privilege);
    entry->zero            = 0;
    entry->ist             = 0;
}