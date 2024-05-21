#include <acpi.h>
#include <stdint.h>
#include <memory.h>
#include <memdefs.h>
SETUP_DATA user_ptr tables[];
SETUP void init_rsdp(struct _RSDP** rsdp){
    find_apci(rsdp);
    if(*rsdp != (struct _RSDP*)0xFFFF){
        RSDP* rs = *rsdp;
        uint8_t* validationPtr = (uint8_t*)*rsdp;
        uint16_t value = 0;
        if(rs->revision == 0 ){
            for(int i = 0;i<20;i++){
                value+=*(validationPtr+i);
            }
            if(value & 0xFF != 0){
                *rsdp = (struct _RSDP*)0xDEAD;
            }
        }else if(rs->revision == 1){
            for(int i = 0;i<24;i++){
                value+=*(validationPtr+i);
            }
            if(value & 0xFF != 0){
                *rsdp = (struct _RSDP*)0xDEAD;
            }
        }else{
            *rsdp = (struct _RSDP*)0xDEAD;
        }
    }else{
        return;
    }
    if(*rsdp != (struct _RSDP*)0xDEAD){
    }
}