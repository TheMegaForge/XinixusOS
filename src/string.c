#include <string.h>
#include <stdbool.h>
SETUP bool strncmp(char* str1,char* str2,uint8_t length){
    bool isCorrect = true;
    for(int i = 0;i<length;i++){
        isCorrect = isCorrect && (str1[i] == str2[i]);
    }
    return isCorrect;
}