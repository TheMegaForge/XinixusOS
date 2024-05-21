#include <IDT.h>
#include <pixelation.h>
#include <acpi.h>
#include <UOSI.h>
SETUP void HAL_init(){
    IDT_load();
    init_pixalation();
    init_rsdp(&getUOSI()->rsdp);
}