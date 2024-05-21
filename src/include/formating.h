#pragma once
#define attribute(x) __attribute__(x)
#define section(x) __attribute__((section(x)))
#define SETUP section(".setup")
#define SETUP_INIT section(".setupi")
#define SETUP_DATA section(".setupd")
#define SETUP_CONST section(".setupc")
#define SETUP_BSS section(".setupu")