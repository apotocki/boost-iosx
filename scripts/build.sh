#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
XCODE_ROOT=$( xcode-select -print-path )
BOOST_VER=1.87.0
EXPECTED_HASH="af57be25cb4c4f4b413ed692fe378affb4352ea50fbe294a11ef548f4d527d89"
#MACOSX_VERSION_ARM=12.3
#MACOSX_VERSION_X86_64=10.13
IOS_VERSION=13.4
IOS_SIM_VERSION=13.4
CATALYST_VERSION=13.4
################## SETUP END
LOCATIONS_FILE_URL="https://raw.githubusercontent.com/apotocki/boost-iosx/master/LOCATIONS"
IOSSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
IOSSIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer
XROSSYSROOT=$XCODE_ROOT/Platforms/XROS.platform/Developer
XROSSIMSYSROOT=$XCODE_ROOT/Platforms/XRSimulator.platform/Developer

BOOST_NAME=boost_${BOOST_VER//./_}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

MACOSX_VERSION_X86_64_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_X86_64}" ] && MACOSX_VERSION_X86_64_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_X86_64"
MACOSX_VERSION_ARM_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_ARM}" ] && MACOSX_VERSION_ARM_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_ARM"

if [ $(clang++ --version | head -1 | sed -E 's/([a-zA-Z ]+)([0-9]+).*/\2/') -gt 14 ]; then
	CLANG15=true
fi

if [ ! -f "$BUILD_DIR/frameworks.built" ]; then

BOOST_ARCHIVE_FILE=$BOOST_NAME.tar.bz2

if [ -f $BOOST_ARCHIVE_FILE ]; then
	FILE_HASH=$(shasum -a 256 "$BOOST_ARCHIVE_FILE" | awk '{ print $1 }')
	if [ ! "$FILE_HASH" == "$EXPECTED_HASH" ]; then
    	echo "Wrong archive hash, trying to reload the archive"
        rm "$BOOST_ARCHIVE_FILE"
    fi
fi

if [ ! -f $BOOST_ARCHIVE_FILE ]; then
	TEMP_LOCATIONS_FILE=$(mktemp)
	curl -s -o "$TEMP_LOCATIONS_FILE" "$LOCATIONS_FILE_URL"
	if [ $? -ne 0 ]; then
	    echo "Failed to download the LOCATIONS file."
	    exit 1
	fi
	while IFS= read -r linktemplate; do
		linktemplate=${linktemplate/DOTVERSION/"$BOOST_VER"}
		link=${linktemplate/FILENAME/"$BOOST_ARCHIVE_FILE"}
		echo "downloading from $link ..."

	    curl -o "$BOOST_ARCHIVE_FILE" "$link"

	    # Check if the download was successful
	    if [ $? -eq 0 ]; then
	        FILE_HASH=$(shasum -a 256 "$BOOST_ARCHIVE_FILE" | awk '{ print $1 }')
	        if [ "$FILE_HASH" == "$EXPECTED_HASH" ]; then
	        	[ -d boost ] && rm -rf boost
	            break
	        else
	        	echo "Wrong archive hash $FILE_HASH, expected $EXPECTED_HASH. Trying next link to reload the archive."
	        	rm $BOOST_ARCHIVE_FILE
	        fi
	    fi
	done < "$TEMP_LOCATIONS_FILE"
	rm "$TEMP_LOCATIONS_FILE"
fi

if [ ! -f $BOOST_ARCHIVE_FILE ]; then
	echo "Failed to download the Boost."
    exit 1
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
if true; then
#export ICU4C_RELEASE_LINK=https://github.com/apotocki/icu4c-iosx/releases/download/74.2.8
if [ ! -d $SCRIPT_DIR/Pods/icu4c-iosx/product ]; then
    if [ ! -z "${ICU4C_RELEASE_LINK}" ]; then
		if [ -d $SCRIPT_DIR/Pods/icu4c-iosx ]; then
			rm -rf $SCRIPT_DIR/Pods/icu4c-iosx
		fi
        mkdir -p $SCRIPT_DIR/Pods/icu4c-iosx/product
		pushd $SCRIPT_DIR/Pods/icu4c-iosx/product
        curl -L ${ICU4C_RELEASE_LINK}/include.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/include.zip
		curl -L ${ICU4C_RELEASE_LINK}/icudata.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icudata.xcframework.zip
		curl -L ${ICU4C_RELEASE_LINK}/icui18n.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icui18n.xcframework.zip
        curl -L ${ICU4C_RELEASE_LINK}/icuio.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icuio.xcframework.zip
        curl -L ${ICU4C_RELEASE_LINK}/icuuc.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icuuc.xcframework.zip
		unzip -q include.zip
		unzip -q icudata.xcframework.zip
		unzip -q icui18n.xcframework.zip
        unzip -q icuio.xcframework.zip
        unzip -q icuuc.xcframework.zip
		mkdir frameworks
		mv icudata.xcframework frameworks/
		mv icui18n.xcframework frameworks/
        mv icuio.xcframework frameworks/
        mv icuuc.xcframework frameworks/
        popd
    else
        pushd $SCRIPT_DIR
        pod repo update
        pod install --verbose
        #pod update --verbose
        popd
    fi
    mkdir $SCRIPT_DIR/Pods/icu4c-iosx/product/lib
fi
ICU_PATH=$SCRIPT_DIR/Pods/icu4c-iosx/product
fi
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

if [[ ! -f tools/build/src/tools/features/instruction-set-feature.jam.orig ]]; then
	cp -f tools/build/src/tools/features/instruction-set-feature.jam tools/build/src/tools/features/instruction-set-feature.jam.orig
else
	cp -f tools/build/src/tools/features/instruction-set-feature.jam.orig tools/build/src/tools/features/instruction-set-feature.jam
fi
patch tools/build/src/tools/features/instruction-set-feature.jam $SCRIPT_DIR/instruction-set-feature.jam.patch


LIBS_TO_BUILD="--with-charconv --with-atomic --with-chrono --with-container --with-context --with-contract --with-coroutine --with-date_time --with-exception --with-fiber --with-filesystem --with-graph --with-iostreams --with-json --with-locale --with-log --with-math --with-nowide --with-program_options --with-random --with-regex --with-serialization --with-stacktrace --with-system --with-test --with-thread --with-timer --with-type_erasure --with-wave --with-url"

if [ $CLANG15 ]; then
	LIBS_TO_BUILD="$LIBS_TO_BUILD --with-cobalt"
fi

B2_BUILD_OPTIONS="-j$THREAD_COUNT address-model=64 release link=static runtime-link=shared define=BOOST_SPIRIT_THREADSAFE cxxflags=\"-std=c++20\""

if [ ! -z "${ICU_PATH}" ]; then
	B2_BUILD_OPTIONS="$B2_BUILD_OPTIONS -sICU_PATH=\"$ICU_PATH\""
fi

if true; then
    [ -d bin.v2 ] && rm -rf bin.v2
    [ -d stage ] &&	rm -rf stage
fi

function boost_arc()
{
    if [[ $1 == arm* ]]; then
		echo "arm"
	elif [[ $1 == x86* ]]; then
		echo "x86"
	else
		echo "unknown"
	fi
}

function boost_abi()
{
    if [[ $1 == arm64 ]]; then
		echo "aapcs"
	elif [[ $1 == x86_64 ]]; then
		echo "sysv"
	else
		echo "unknown"
	fi
}

build_macos_libs()
{
[ -f tools/build/src/user-config.jam ] && rm -f tools/build/src/user-config.jam

cat >> tools/build/src/user-config.jam <<EOF
using darwin : : clang++ -arch $1 $2 -isysroot $MACSYSROOT/SDKs/MacOSX.sdk
: <striper> <root>$MACSYSROOT
: <architecture>$(boost_arc $1)
;
EOF
if [ ! -z "${ICU_PATH}" ]; then
	cp $ICU_PATH/frameworks/icudata.xcframework/macos-*/libicudata.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icui18n.xcframework/macos-*/libicui18n.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icuuc.xcframework/macos-*/libicuuc.a $ICU_PATH/lib/
fi
./b2 -j8 --stagedir=stage/macosx-$1 toolset=darwin architecture=$(boost_arc $1) abi=$(boost_abi $1) $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

build_catalyst_libs()
{
[ -f tools/build/src/user-config.jam ] && rm -f tools/build/src/user-config.jam

cat >> tools/build/src/user-config.jam <<EOF
using darwin : catalyst : clang++ -arch $1 --target=$2 -isysroot $MACSYSROOT/SDKs/MacOSX.sdk -I$MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include/ -isystem $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include -iframework $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/System/Library/Frameworks
: <striper> <root>$MACSYSROOT
: <architecture>$(boost_arc $1)
;
EOF
if [ ! -z "${ICU_PATH}" ]; then
	cp $ICU_PATH/frameworks/icudata.xcframework/ios-*-maccatalyst/libicudata.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icui18n.xcframework/ios-*-maccatalyst/libicui18n.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icuuc.xcframework/ios-*-maccatalyst/libicuuc.a $ICU_PATH/lib/
fi
./b2 --stagedir=stage/catalyst-$1 toolset=darwin-catalyst architecture=$(boost_arc $1) abi=$(boost_abi $1) $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

build_ios_libs()
{
[ -f tools/build/src/user-config.jam ] && rm -f tools/build/src/user-config.jam

cat >> tools/build/src/user-config.jam <<EOF
using darwin : ios : clang++ -arch arm64 -fembed-bitcode -isysroot $IOSSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=$IOS_VERSION
: <striper> <root>$IOSSYSROOT 
: <architecture>arm <target-os>iphone 
;
EOF
if [ ! -z "${ICU_PATH}" ]; then
	cp $ICU_PATH/frameworks/icudata.xcframework/ios-arm64/libicudata.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icui18n.xcframework/ios-arm64/libicui18n.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icuuc.xcframework/ios-arm64/libicuuc.a $ICU_PATH/lib/
fi
./b2 --stagedir=stage/ios toolset=darwin-ios instruction-set=arm64 architecture=arm binary-format=mach-o abi=aapcs target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

build_xros_libs()
{
[ -f tools/build/src/user-config.jam ] && rm -f tools/build/src/user-config.jam

cat >> tools/build/src/user-config.jam <<EOF
using darwin : xros : clang++ -arch arm64 -fembed-bitcode -isysroot $XROSSYSROOT/SDKs/XROS.sdk
: <striper> <root>$XROSSYSROOT 
: <architecture>arm <target-os>iphone 
;
EOF
if [ ! -z "${ICU_PATH}" ]; then
	cp $ICU_PATH/frameworks/icudata.xcframework/xros-arm64/libicudata.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icui18n.xcframework/xros-arm64/libicui18n.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icuuc.xcframework/xros-arm64/libicuuc.a $ICU_PATH/lib/
fi
./b2 --stagedir=stage/xros toolset=darwin-xros instruction-set=arm64 architecture=arm binary-format=mach-o abi=aapcs target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

build_sim_libs()
{
[ -f tools/build/src/user-config.jam ] && rm -f tools/build/src/user-config.jam

cat >> tools/build/src/user-config.jam <<EOF
using darwin : iossim : clang++ -arch $1 -isysroot $IOSSIMSYSROOT/SDKs/iPhoneSimulator.sdk $2
: <striper> <root>$IOSSIMSYSROOT 
: <architecture>$(boost_arc $1) <target-os>iphone 
;
EOF
if [ ! -z "${ICU_PATH}" ]; then
	cp $ICU_PATH/frameworks/icudata.xcframework/ios-*-simulator/libicudata.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icui18n.xcframework/ios-*-simulator/libicui18n.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icuuc.xcframework/ios-*-simulator/libicuuc.a $ICU_PATH/lib/
fi
./b2 --stagedir=stage/iossim-$1 toolset=darwin-iossim architecture=$(boost_arc $1) abi=$(boost_abi $1) target-os=iphone define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

build_xrossim_libs()
{
[ -f tools/build/src/user-config.jam ] && rm -f tools/build/src/user-config.jam

cat >> tools/build/src/user-config.jam <<EOF
using darwin : xrossim : clang++ -arch $1 -isysroot $XROSSIMSYSROOT/SDKs/XRSimulator.sdk $2
: <striper> <root>$XROSSIMSYSROOT 
: <architecture>$(boost_arc $1) <target-os>iphone 
;
EOF
if [ ! -z "${ICU_PATH}" ]; then
	cp $ICU_PATH/frameworks/icudata.xcframework/xros-*-simulator/libicudata.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icui18n.xcframework/xros-*-simulator/libicui18n.a $ICU_PATH/lib/
	cp $ICU_PATH/frameworks/icuuc.xcframework/xros-*-simulator/libicuuc.a $ICU_PATH/lib/
fi
./b2 --stagedir=stage/xrossim-$1 toolset=darwin-xrossim architecture=$(boost_arc $1) abi=$(boost_abi $1) target-os=iphone define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
}

if true; then
	[ -d stage/macosx/lib ] && rm -rf stage/macosx/lib
	
	build_macos_libs x86_64 $MACOSX_VERSION_X86_64_BUILD_FLAGS
	build_macos_libs arm64 $MACOSX_VERSION_ARM_BUILD_FLAGS
	mkdir -p stage/macosx/lib
fi

if true; then
	[ -d stage/catalyst/lib ] && rm -rf stage/catalyst/lib
	
	build_catalyst_libs arm64 arm-apple-ios$CATALYST_VERSION-macabi
	build_catalyst_libs x86_64 x86_64-apple-ios$CATALYST_VERSION-macabi
	mkdir -p stage/catalyst/lib
fi

if true; then
	[ -d stage/iossim/lib ] && rm -rf stage/iossim/lib
	
	build_sim_libs arm64 -mios-simulator-version-min=$IOS_SIM_VERSION
	build_sim_libs x86_64 -mios-simulator-version-min=$IOS_SIM_VERSION
	mkdir -p stage/iossim/lib
fi

if [ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]; then
	[ -d stage/xrossim/lib ] && rm -rf stage/xrossim/lib
	
	build_xrossim_libs arm64
	build_xrossim_libs x86_64
	mkdir -p stage/xrossim/lib
fi

build_ios_libs
if [ -d $XROSSYSROOT ]; then
    build_xros_libs
fi

echo installing boost...
if [ -d "$BUILD_DIR/frameworks" ]; then
    rm -rf "$BUILD_DIR/frameworks"
fi

mkdir "$BUILD_DIR/frameworks"

build_xcframework()
{
	lipo -create stage/macosx-arm64/lib/lib$1.a stage/macosx-x86_64/lib/lib$1.a -output stage/macosx/lib/lib$1.a
	lipo -create stage/catalyst-arm64/lib/lib$1.a stage/catalyst-x86_64/lib/lib$1.a -output stage/catalyst/lib/lib$1.a
	lipo -create stage/iossim-arm64/lib/lib$1.a stage/iossim-x86_64/lib/lib$1.a -output stage/iossim/lib/lib$1.a
    LIBARGS="-library stage/macosx/lib/lib$1.a -library stage/catalyst/lib/lib$1.a -library stage/ios/lib/lib$1.a -library stage/iossim/lib/lib$1.a"
    
    if [ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]; then
        lipo -create stage/xrossim-arm64/lib/lib$1.a stage/xrossim-x86_64/lib/lib$1.a -output stage/xrossim/lib/lib$1.a
        LIBARGS="$LIBARGS -library stage/xrossim/lib/lib$1.a"
    fi
    if [ -d $XROSSYSROOT/SDKs/XROS.sdk ]; then
        LIBARGS="$LIBARGS -library stage/xros/lib/lib$1.a"
    fi
	xcodebuild -create-xcframework $LIBARGS -output "$BUILD_DIR/frameworks/$1.xcframework"
}

if true; then
build_xcframework boost_atomic
build_xcframework boost_charconv
build_xcframework boost_chrono
[ $CLANG15 ] && build_xcframework boost_cobalt
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
build_xcframework boost_url
build_xcframework boost_wave

mkdir "$BUILD_DIR/frameworks/Headers"
cp -R boost "$BUILD_DIR/frameworks/Headers/"
#mv boost "$BUILD_DIR/frameworks/Headers/"
touch "$BUILD_DIR/frameworks.built"
fi

#rm -rf "$BUILD_DIR/boost"

popd

fi
