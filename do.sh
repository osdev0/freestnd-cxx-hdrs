#! /bin/sh

set -ex

for target_arch in i686 x86_64 aarch64 loongarch64 riscv64 m68k; do
    TARGET="${target_arch}-elf" ./make_toolchain.sh

    mkdir -p ${target_arch}
    rm -rf ${target_arch}/include
    mv toolchain/include/c++/* ${target_arch}/include
    cp -rp ${target_arch}/include/${target_arch}-elf/* ${target_arch}/include/
    rm -rf ${target_arch}/include/${target_arch}-elf
    for f in patches/*; do
        ( cd ${target_arch} && patch -p0 <../$f )
    done
done
