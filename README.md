RISC-V Baremetal Playground
============================

This is my playground to build RISC-V baremetal/newlib programs
with little build-related effort.


My Environment
---------------

*   [riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)  
    compiled with `--with-cmodel=medany`



Configure Your Target
----------------------

You must first create `.config` in the source directory.
You can create default configuration file by `make defconfig`.

Following variables are expected to be customized.

*   `CONFIG_TARGET_ISA`
*   `CONFIG_TARGET_ABI`
*   `CONFIG_ADDR_START`  
    Text entrypoint address
*   `CONFIG_ADDR_DATA`  (can be an address or `auto`)  
    Data start address (RAM)
*   `CONFIG_ADDR_STACK` (can be an address or `auto`)  
    Data stack address (RAM)
*   `CONFIG_STACK_SIZE`  
    Stack size in bytes (only valid if `CONFIG_ADDR_STACK` is `auto`)



Add Your Program
-----------------

### Baremetal

1.  Create either `[NAME].bare.c` or `[NAME].bare.S`
2.  Add the path to `src_targets` environment in `SOURCES.mk`.

### Newlib-based

1.  Create either `[NAME].newlib.c` or `[NAME].newlib.S`
2.  Add the path to `src_targets` environment in `SOURCES.mk`.



Add Shared Code
----------------

### Generic

Add relative path to the source file to `src_liball`
environment in `SOURCES.mk`.

### CRT function replacement

Use `src_libcrt` environment instead of `src_liball`.



Build
------

All you have to do is run `make`.

You can also generate `objdump` by `make dump`.



Credit
-------

Default linker script is based on GNU Binutils 2.37.

Make script is partially based on OpenSBI but heavily modified
for hobby use.

See the source code for details.
