#!/bin/bash
set -e
################## SETUP BEGIN
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
BOOST_VER=1.76.0
################## SETUP END
DEVSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
SIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
BOOST_NAME=boost_${BOOST_VER//./_}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -f "$BUILD_DIR/frameworks.built" ]; then

if [[ $HOST_ARC == arm* ]]; then
	BOOST_ARC=arm
elif [[ $HOST_ARC == x86* ]]; then
	BOOST_ARC=x86
else
	BOOST_ARC=unknown
fi

if [ ! -f $BOOST_NAME.tar.bz2 ]; then
	curl -L https://dl.bintray.com/boostorg/release/$BOOST_VER/source/$BOOST_NAME.tar.bz2 -o $BOOST_NAME.tar.bz2
fi
if [ ! -d boost ]; then
	echo "extracting $BOOST_NAME.tar.bz2 ..."
	tar -xf $BOOST_NAME.tar.bz2
	mv $BOOST_NAME boost
fi

if [ ! -f boost/b2 ]; then
	pushd boost
	./bootstrap.sh
	popd
fi

############### ICU
if [ ! -d $SCRIPT_DIR/Pods/icu4c-iosx/product ]; then
	pushd $SCRIPT_DIR
	pod install --verbose
	popd
	mkdir $SCRIPT_DIR/Pods/icu4c-iosx/product/lib
fi
ICU_PATH=$SCRIPT_DIR/Pods/icu4c-iosx/product
############### ICU

pushd boost

echo patching boost...

if [ ! -f tools/build/src/tools/gcc.jam.orig ]; then
	cp -f tools/build/src/tools/gcc.jam tools/build/src/tools/gcc.jam.orig
else
	cp -f tools/build/src/tools/gcc.jam.orig tools/build/src/tools/gcc.jam
fi
patch tools/build/src/tools/gcc.jam $SCRIPT_DIR/gcc.jam.patch

if [ ! -f tools/build/src/tools/features/instruction-set-feature.jam.orig ]; then
	cp -f tools/build/src/tools/features/instruction-set-feature.jam tools/build/src/tools/features/instruction-set-feature.jam.orig
else
	cp -f tools/build/src/tools/features/instruction-set-feature.jam.orig tools/build/src/tools/features/instruction-set-feature.jam
fi
patch tools/build/src/tools/features/instruction-set-feature.jam $SCRIPT_DIR/instruction-set-feature.jam.patch

if false; then
if [ ! -f tools/build/src/build/configure.jam.orig ]; then
	cp -f tools/build/src/build/configure.jam tools/build/src/build/configure.jam.orig
else
	cp -f tools/build/src/build/configure.jam.orig tools/build/src/build/configure.jam
fi
patch tools/build/src/build/configure.jam $SCRIPT_DIR/configure.jam.patch
fi

LIBS_TO_BUILD="--with-locale"
LIBS_TO_BUILD="--with-atomic --with-chrono --with-container --with-context --with-contract --with-coroutine --with-date_time --with-exception --with-fiber --with-filesystem --with-graph --with-iostreams --with-json --with-locale --with-log --with-math --with-nowide --with-program_options --with-random --with-regex --with-serialization --with-stacktrace --with-system --with-test --with-thread --with-timer --with-type_erasure --with-wave"

B2_BUILD_OPTIONS="release link=static runtime-link=shared define=BOOST_SPIRIT_THREADSAFE"

if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
cat >> tools/build/src/user-config.jam <<EOF
using darwin : ios : clang++ -arch arm64 -fembed-bitcode-marker -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk
: <striper> <root>$DEVSYSROOT 
: <architecture>arm <target-os>iphone 
;
using darwin : iossim : clang++ -arch $HOST_ARC -fembed-bitcode-marker -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk
: <striper> <root>$SIMSYSROOT 
: <architecture>$BOOST_ARC <target-os>iphone 
;
using darwin : : 
: 
: <target-os>darwin 
;
EOF

if true; then
if [ -d bin.v2 ]; then
	rm -rf bin.v2
fi
if [ -d stage ]; then
	rm -rf stage
fi
fi

if true; then
cp $ICU_PATH/frameworks/icudata.xcframework/macos-$HOST_ARC/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/macos-$HOST_ARC/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/macos-$HOST_ARC/libicuuc.a $ICU_PATH/lib/
./b2 -j8 --stagedir=stage/macosx cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" target-os=darwin address-model=64 architecture=$BOOST_ARC $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
fi

if true; then
cp $ICU_PATH/frameworks/icudata.xcframework/ios-arm64/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/ios-arm64/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/ios-arm64/libicuuc.a $ICU_PATH/lib/
./b2 -j8 --stagedir=stage/ios cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" toolset=darwin-ios address-model=64 instruction-set=arm64 architecture=arm binary-format=mach-o abi=aapcs target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
fi

if true; then
cp $ICU_PATH/frameworks/icudata.xcframework/ios-$HOST_ARC-simulator/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/ios-$HOST_ARC-simulator/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/ios-$HOST_ARC-simulator/libicuuc.a $ICU_PATH/lib/
./b2 -j8 --stagedir=stage/iossim cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" toolset=darwin-iossim address-model=64 architecture=$BOOST_ARC target-os=iphone define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
fi

echo installing boost...
if [ -d "$BUILD_DIR/frameworks" ]; then
    rm -rf "$BUILD_DIR/frameworks"
fi

mkdir "$BUILD_DIR/frameworks"


build_xcframework()
{
	xcodebuild -create-xcframework -library stage/macosx/lib/lib$1.a -library stage/ios/lib/lib$1.a -library stage/iossim/lib/lib$1.a -output "$BUILD_DIR/frameworks/$1.xcframework"
}

if true; then
build_xcframework boost_atomic
build_xcframework boost_chrono
build_xcframework boost_container
build_xcframework boost_context
build_xcframework boost_contract
build_xcframework boost_coroutine
build_xcframework boost_date_time
build_xcframework boost_exception
build_xcframework boost_fiber
build_xcframework boost_filesystem
build_xcframework boost_graph
build_xcframework boost_iostreams
build_xcframework boost_json
build_xcframework boost_locale
build_xcframework boost_log
build_xcframework boost_log_setup
build_xcframework boost_math_c99
build_xcframework boost_math_c99l
build_xcframework boost_math_c99f
build_xcframework boost_math_tr1
build_xcframework boost_math_tr1l
build_xcframework boost_math_tr1f
build_xcframework boost_nowide
build_xcframework boost_program_options
build_xcframework boost_random
build_xcframework boost_regex
build_xcframework boost_serialization
build_xcframework boost_wserialization
#build_xcframework boost_stacktrace_addr2line
build_xcframework boost_stacktrace_basic
build_xcframework boost_stacktrace_noop
build_xcframework boost_system
build_xcframework boost_prg_exec_monitor
build_xcframework boost_test_exec_monitor
build_xcframework boost_unit_test_framework
build_xcframework boost_thread
build_xcframework boost_timer
build_xcframework boost_type_erasure
build_xcframework boost_wave

mkdir "$BUILD_DIR/frameworks/Headers"
#cp -R boost "$BUILD_DIR/frameworks/Headers/"
mv boost "$BUILD_DIR/frameworks/Headers/"
touch "$BUILD_DIR/frameworks.built"
fi

rm -rf "$BUILD_DIR/boost"

popd

fi