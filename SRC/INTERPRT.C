
#define TAPE_SIZE 30000

unsigned char tape[TAPE_SIZE] = {0};

void interpret(char* code) {
    const char* pc = code;
    unsigned char* ptr = tape;
    
    while (*pc) {
        int jump = 1;

        switch (*pc) {
            case '>': ptr++; break;
            case '<': ptr--; break;
            case '+': (*ptr)++; break;
            case '-': (*ptr)--; break;
            case '.': {
                unsigned char chr = *ptr;

                asm {
                    mov dl, chr
                    mov ah, 2
                    int 0x21
                }
                break;
            }
            case ',': {
                unsigned char chr;
                
                asm {
                    mov ah, 1
                    int 0x21
                    mov chr, al
                }
                *ptr = chr;
                break;
            }
            case '[': {
                if (!*ptr) {
                    int depth = 1;

                    while (depth > 0 && *++pc) {
                        if (*pc == '[') 
                            depth++;
                        else if (*pc == ']') 
                            depth--;
                    }
                    jump = 0; // already incremented pc
                }
                break;
            }
            case ']': {
                if (*ptr) {
                    int depth = 1;

                    while (depth > 0 && --pc >= code) {
                        if (*pc == ']') 
                            depth++;
                        else if (*pc == '[') 
                            depth--;
                    }
                    jump = 0; // already decremented pc
                }
                break;
            }
        }
        if (jump) {
            pc++;
        }
    }
}