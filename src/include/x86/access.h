#pragma once
#include "../stdint.h"
#include "../formating.h"
#error do not include this file!
SETUP extern uint64_t readLongLoader(loader_ptr ptr);
SETUP extern uint64_t readLongKernel(kernel_ptr ptr);
SETUP extern uint64_t readLongUser(user_ptr ptr);

SETUP extern uint32_t readIntLoader(loader_ptr ptr);
SETUP extern uint32_t readIntKernel(kernel_ptr ptr);
SETUP extern uint32_t readIntUser(user_ptr ptr);

SETUP extern uint16_t readShortLoader(loader_ptr ptr);
SETUP extern uint16_t readShortKernel(kernel_ptr ptr);
SETUP extern uint16_t readShortUser(user_ptr ptr);

SETUP extern uint8_t readByteLoader(loader_ptr ptr);
SETUP extern uint8_t readByteKernel(kernel_ptr ptr);
SETUP extern uint8_t readByteUser(user_ptr ptr);

SETUP extern void writeKernel64(uint32_t dst,uint64_t source);