#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
BOOST_VER=1.80.0
################## SETUP END
DEVSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
SIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer

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
	curl -L https://boostorg.jfrog.io/artifactory/main/release/$BOOST_VER/source/$BOOST_NAME.tar.bz2 -o $BOOST_NAME.tar.bz2
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
    pod repo update
	pod install --verbose
	pod update --verbose
	popd
	mkdir $SCRIPT_DIR/Pods/icu4c-iosx/product/lib
fi
ICU_PATH=$SCRIPT_DIR/Pods/icu4c-iosx/product
############### ICU

pushd boost

echo patching boost...


#if [ ! -f boost/json/impl/array.ipp.orig ]; then
#	cp -f boost/json/impl/array.ipp boost/json/impl/array.ipp.orig
#else
#	cp -f boost/json/impl/array.ipp.orig boost/json/impl/array.ipp
#fi
#if [ ! -f libs/json/test/array.cpp.orig ]; then
#	cp -f libs/json/test/array.cpp libs/json/test/array.cpp.orig
#else
#	cp -f libs/json/test/array.cpp.orig libs/json/test/array.cpp
#fi
#patch -p0 <$SCRIPT_DIR/0001-json-array-erase-relocate.patch

if [ ! -f tools/build/src/tools/features/instruction-set-feature.jam.orig ]; then
	cp -f tools/build/src/tools/features/instruction-set-feature.jam tools/build/src/tools/features/instruction-set-feature.jam.orig
else
	cp -f tools/build/src/tools/features/instruction-set-feature.jam.orig tools/build/src/tools/features/instruction-set-feature.jam
fi
patch tools/build/src/tools/features/instruction-set-feature.jam $SCRIPT_DIR/instruction-set-feature.jam.patch



#LIBS_TO_BUILD="--with-regex"
LIBS_TO_BUILD="--with-atomic --with-chrono --with-container --with-context --with-contract --with-coroutine --with-date_time --with-exception --with-fiber --with-filesystem --with-graph --with-iostreams --with-json --with-locale --with-log --with-math --with-nowide --with-program_options --with-random --with-regex --with-serialization --with-stacktrace --with-system --with-test --with-thread --with-timer --with-type_erasure --with-wave"

B2_BUILD_OPTIONS="-j$THREAD_COUNT -sICU_PATH=\"$ICU_PATH\" address-model=64 release link=static runtime-link=shared define=BOOST_SPIRIT_THREADSAFE cxxflags=\"-std=c++20\""


if true; then
if [ -d bin.v2 ]; then
	rm -rf bin.v2
fi
if [ -d stage ]; then
	rm -rf stage
fi
fi

if true; then
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
cp $ICU_PATH/frameworks/icudata.xcframework/macos-*$HOST_ARC*/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/macos-*$HOST_ARC*/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/macos-*$HOST_ARC*/libicuuc.a $ICU_PATH/lib/
./b2 -j8 --stagedir=stage/macosx toolset=darwin architecture=$BOOST_ARC $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
fi

# <binary-format>mach-o <threading>multi <abi>sysv
build_catalyst_libs()
{
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
cat >> tools/build/src/user-config.jam <<EOF
using darwin : catalyst : clang++ -arch $1 --target=$2-apple-ios13.4-macabi -isysroot $MACSYSROOT/SDKs/MacOSX.sdk -I$MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include/ -isystem $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include -iframework $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/System/Library/Frameworks
: <striper> <root>$MACSYSROOT
: <architecture>$3 
;
EOF
cp $ICU_PATH/frameworks/icudata.xcframework/ios-*-maccatalyst/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/ios-*-maccatalyst/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/ios-*-maccatalyst/libicuuc.a $ICU_PATH/lib/
./b2 --stagedir=stage/catalyst-$1 abi=$4 toolset=darwin-catalyst architecture=$3 $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

if true; then
	if [ -d stage/catalyst/lib ]; then
		rm -rf stage/catalyst/lib
	fi
	mkdir -p stage/catalyst/lib
	build_catalyst_libs arm64 arm arm aapcs
	build_catalyst_libs x86_64 x86_64 x86 sysv
fi

if true; then
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
cat >> tools/build/src/user-config.jam <<EOF
using darwin : ios : clang++ -arch arm64 -fembed-bitcode -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=13.4
: <striper> <root>$DEVSYSROOT 
: <architecture>arm <target-os>iphone 
;
EOF
cp $ICU_PATH/frameworks/icudata.xcframework/ios-arm64/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/ios-arm64/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/ios-arm64/libicuuc.a $ICU_PATH/lib/
./b2 --stagedir=stage/ios toolset=darwin-ios instruction-set=arm64 architecture=arm binary-format=mach-o abi=aapcs target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
fi

build_sim_libs()
{
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
cat >> tools/build/src/user-config.jam <<EOF
using darwin : iossim : clang++ -arch $1 -fembed-bitcode-marker -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -mios-simulator-version-min=13.4
: <striper> <root>$SIMSYSROOT 
: <architecture>$2 <target-os>iphone 
;
EOF
cp $ICU_PATH/frameworks/icudata.xcframework/ios-*-simulator/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/ios-*-simulator/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/ios-*-simulator/libicuuc.a $ICU_PATH/lib/
./b2 --stagedir=stage/iossim-$1 toolset=darwin-iossim abi=$3 architecture=$2 target-os=iphone define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

if true; then
	if [ -d stage/iossim/lib ]; then
		rm -rf stage/iossim/lib
	fi
	mkdir -p stage/iossim/lib
	build_sim_libs arm64 arm aapcs
	build_sim_libs x86_64 x86 sysv
fi

echo installing boost...
if [ -d "$BUILD_DIR/frameworks" ]; then
    rm -rf "$BUILD_DIR/frameworks"
fi

mkdir "$BUILD_DIR/frameworks"



build_xcframework()
{
	lipo -create stage/catalyst-arm64/lib/lib$1.a stage/catalyst-x86_64/lib/lib$1.a -output stage/catalyst/lib/lib$1.a
	lipo -create stage/iossim-arm64/lib/lib$1.a stage/iossim-x86_64/lib/lib$1.a -output stage/iossim/lib/lib$1.a

	xcodebuild -create-xcframework -library stage/macosx/lib/lib$1.a -library stage/catalyst/lib/lib$1.a -library stage/ios/lib/lib$1.a -library stage/iossim/lib/lib$1.a -output "$BUILD_DIR/frameworks/$1.xcframework"
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
cp -R boost "$BUILD_DIR/frameworks/Headers/"
#mv boost "$BUILD_DIR/frameworks/Headers/"
touch "$BUILD_DIR/frameworks.built"
fi

#rm -rf "$BUILD_DIR/boost"

popd

fi
