#pragma once
#include <stdint.h>
typedef enum {
    SIMD_MMX    = 1,
    SIMD_SSE    = 2,
    SIMD_SSE2   = 4,
    SIMD_SSE3   = 8,
    SIMD_SSE4_1 = 16,
    SIMD_SSE4_2 = 32,
    SIMD_SSSE3  = 64,
    SIMD_AVX    = 128,
    SIMD_AVX2   = 256
}SIMDState;
typedef void(*simd_func)(void* dst,void* src,int size);
void copyBytes(void* dst,void* src,int size);
void addBytes(void* dst,void* src,int size);
void subBytes(void* dst,void* src,int size);
SETUP  void SIMD_init(SIMDState* maxState,uint8_t* size);