    .option norvc
    .globl  __start
    .globl  __end
    .globl  __trap
    .section .entry.real, "ax", %progbits
    .extern __stack_top
    .extern __global_pointer$


__start:
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop
    la      sp, __trap
    csrw    mtvec, sp
#ifdef ADDR_STACK
    li      sp, ADDR_STACK
#else
    la      sp, __stack_top
#endif
    jal     _start


__end:
#ifdef USE_IDLE_LOOP
    wfi
#endif
    j       __end


__trap:
#ifdef USE_IDLE_LOOP
    wfi
#endif
    j       __trap
