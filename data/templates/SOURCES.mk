##
## Instructions (object files):
##

## (1) Set root source files to `src_targets' as follows:
##       `NAME.bare.[cS]'   : ELF file (Baremetal)
##       `NAME.newlib.[cS]' : ELF file (linked to libc; newlib intended)
src_targets :=
#src_targets += sample.bare.S
#src_targets += sample.newlib.c
#src_targets +=

## (2) Add common library source files to `src_liball'.
#src_liball += lib-sample.c

## (3) Add replacement CRT library objects to `src_libcrt'.
##     Note that all objects are linked to `NAME.newlib.elf'.
#src_libcrt += crt-stub.c
