#ifndef ADDR_STACK
#ifndef STACK_SIZE
#error STACK_SIZE must be defined if static stack is defined.
#endif
        .globl  __stack
        .globl  __stack_top
        .section .bss, "aw", @nobits
        .type   __stack, @object
        .size   __stack, STACK_SIZE
        .align  4
__stack:
        .zero   STACK_SIZE
__stack_top:
#endif
