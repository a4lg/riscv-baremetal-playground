    .globl  _exit
    .extern __end
    .section .text, "ax", %progbits

_exit:
    j       __end
