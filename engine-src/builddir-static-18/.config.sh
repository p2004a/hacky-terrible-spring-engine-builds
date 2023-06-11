export PKG_CONFIG_LIBDIR="$(pwd)/../spring-static-libs/lib/pkgconfig"
export PKG_CONFIG="pkg-config --define-prefix --static"
cmake \
	-DCMAKE_TOOLCHAIN_FILE="../toolchain/gcc-11_x86_64-pc-linux-gnu.cmake" \
	-DCMAKE_SYSTEM_PREFIX_PATH="$(pwd)/../spring-static-libs" \
	-DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
	-DCMAKE_BUILD_TYPE=RELWITHDEBINFO \
	-DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O3 -g1 -DNDEBUG -fdiagnostics-color=always -fno-omit-frame-pointer" \
	-DCMAKE_C_FLAGS_RELWITHDEBINFO="-O3 -g1 -DNDEBUG -fdiagnostics-color=always -fno-omit-frame-pointer" \
	-DTRACY_ENABLE=ON \
	-DTRACY_ON_DEMAND=ON \
	-DAI_TYPES=NATIVE \
	-DWITH_MAPCOMPILER=OFF \
	-DINSTALL_PORTABLE=ON \
	-DBINDIR:PATH=./ \
	-DLIBDIR:PATH=./ \
	-DDATADIR:PATH=./ \
	-DCMAKE_INSTALL_PREFIX:PATH="$(dirname $(realpath "$0"))/install" \
	-DPREFER_STATIC_LIBS:BOOL=1 \
	-DCMAKE_USE_RELATIVE_PATHS:BOOL=1 \
	-G Ninja \
	..
