#! /bin/sh

set -ex

srcdir="$(dirname "$0")"
test -z "$srcdir" && srcdir=.
srcdir="$(cd "${srcdir}" && pwd -P)"

cd "$srcdir"

if [ -z "$TARGET" ]; then
    set +x
    echo "TARGET not specified"
    exit 1
fi

if [ -z "$BINUTILSVERSION" ]; then
    BINUTILSVERSION=2.46.0
fi

if [ -z "$GCCVERSION" ]; then
    GCCVERSION=16.1.0
fi

if command -v gmake; then
    export MAKE=gmake
else
    export MAKE=make
fi

if command -v gtar; then
    export TAR=gtar
else
    export TAR=tar
fi

if [ -z "$CFLAGS" ]; then
    export CFLAGS="-O2 -pipe"
fi

unset CC
unset CXX

if [ "$(uname)" = "OpenBSD" ]; then
    # OpenBSD has an awfully ancient GCC which fails to build our toolchain.
    # Force clang/clang++.
    export CC="clang"
    export CXX="clang++"
fi

mkdir -p toolchain && cd toolchain
PREFIX="$(pwd -P)"

export MAKEFLAGS="-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || psrinfo -tc 2>/dev/null || echo 1)"

export PATH="$PREFIX/bin:$PATH"

if [ ! -f binutils-$BINUTILSVERSION.tar.xz ]; then
    curl -Lo binutils-$BINUTILSVERSION.tar.xz https://ftpmirror.gnu.org/gnu/binutils/binutils-$BINUTILSVERSION.tar.xz
    b2sum binutils-$BINUTILSVERSION.tar.xz | grep -q 9f4fd8897d237eb5003bdf439537dfc5f8c681e9ff939fb06bb8235ed298031ea4cc91611edb640ffc432199d5791289d003fe0d07acce80327dc40595a5eb9e
fi
if [ ! -f gcc-$GCCVERSION.tar.xz ]; then
    curl -Lo gcc-$GCCVERSION.tar.xz https://ftpmirror.gnu.org/gnu/gcc/gcc-$GCCVERSION/gcc-$GCCVERSION.tar.xz
    b2sum gcc-$GCCVERSION.tar.xz | grep -q ceb07866b6b17eb4c69a6b51241b275bc5ec506603a7c1a4c1e2585091a09fc647be945beeff76700bffd9018bda81b072d84f909fd7998baa0cfe3f0eb550b4
fi

rm -rf build
mkdir build
cd build

$TAR -xf ../binutils-$BINUTILSVERSION.tar.xz
$TAR -xf ../gcc-$GCCVERSION.tar.xz

cd binutils-$BINUTILSVERSION
# Apply patches, if any
for patch in "${srcdir}"/toolchain-patches/binutils/*; do
    [ "${patch}" = "${srcdir}/toolchain-patches/binutils/*" ] && break
    patch -p1 < "${patch}"
    find . -name '*.orig' -delete
done
cd ..
mkdir build-binutils
cd build-binutils
../binutils-$BINUTILSVERSION/configure CFLAGS="$CFLAGS" CXXFLAGS="$CFLAGS" --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
$MAKE
$MAKE install
cd ..

cd gcc-$GCCVERSION
# Apply patches, if any
for patch in "${srcdir}"/toolchain-patches/gcc/*; do
    [ "${patch}" = "${srcdir}/toolchain-patches/gcc/*" ] && break
    patch -p1 < "${patch}"
    find . -name '*.orig' -delete
done
sed 's|http://gcc.gnu|https://gcc.gnu|g' < contrib/download_prerequisites > dp.sed
mv dp.sed contrib/download_prerequisites
chmod +x contrib/download_prerequisites
./contrib/download_prerequisites
cd ..
mkdir build-gcc
cd build-gcc
../gcc-$GCCVERSION/configure CFLAGS="$CFLAGS" CXXFLAGS="$CFLAGS" --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
$MAKE all-gcc
$MAKE all-target-libgcc
$MAKE install-gcc
$MAKE install-target-libgcc
cd ..

mkdir build-libstdcxx
cd build-libstdcxx
ac_cv_func_getexecname=no ac_cv_func_fcntl=no ../gcc-$GCCVERSION/libstdc++-v3/configure --host=$TARGET --prefix="$PREFIX" --disable-nls --disable-tls --disable-multilib --disable-hosted-libstdcxx --disable-libstdcxx-verbose --disable-libstdcxx-threads --disable-libstdcxx-filesystem-ts --disable-libstdcxx-backtrace --without-headers
$MAKE install-data
cd ..
