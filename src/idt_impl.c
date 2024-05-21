#include <IDT.h>
#include <formating.h>
#include <stdint.h>
#include <pixelation.h>
typedef struct _ITable{//address of the stack.Stack grows downwards
    uint64_t rdx;
    uint64_t rsi;
    uint64_t rdi;
    uint64_t type;
    uint64_t stack;
}__attribute__((packed)) ITable;
SETUP extern int c_sysexc(struct _ITable* table){
    return 1;
}
SETUP extern int c_sysfrmt(struct _ITable* table){
    if(table->type == 0){
        //pixel format
        //put_char(0,0,(PixelFormat*)table->rdi);
    }
    return 1;
}