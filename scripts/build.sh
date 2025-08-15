#!/bin/bash
set -euo pipefail
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
BOOST_VER=1.89.0
EXPECTED_HASH="85a33fa22621b4f314f8e85e1a5e2a9363d22e4f4992925d4bb3bc631b5a0c7a"
MACOSX_VERSION_ARM=12.3
MACOSX_VERSION_X86_64=10.13
IOS_VERSION=13.4
IOS_SIM_VERSION=13.4
CATALYST_VERSION=13.4
TVOS_VERSION=13.0
TVOS_SIM_VERSION=13.0
WATCHOS_VERSION=11.0
WATCHOS_SIM_VERSION=11.0
################## SETUP END
LOCATIONS_FILE_URL="https://github.com/apotocki/boost-iosx/raw/refs/heads/master/LOCATIONS"
IOSSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
IOSSIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer
XROSSYSROOT=$XCODE_ROOT/Platforms/XROS.platform/Developer
XROSSIMSYSROOT=$XCODE_ROOT/Platforms/XRSimulator.platform/Developer
TVOSSYSROOT=$XCODE_ROOT/Platforms/AppleTVOS.platform/Developer
TVOSSIMSYSROOT=$XCODE_ROOT/Platforms/AppleTVSimulator.platform/Developer
WATCHOSSYSROOT=$XCODE_ROOT/Platforms/WatchOS.platform/Developer
WATCHOSSIMSYSROOT=$XCODE_ROOT/Platforms/WatchSimulator.platform/Developer

LIBS_TO_BUILD_ALL="atomic,chrono,container,context,contract,coroutine,date_time,exception,fiber,filesystem,graph,iostreams,json,locale,log,math,nowide,program_options,random,regex,serialization,stacktrace,test,thread,timer,type_erasure,wave,url,cobalt,charconv"

BUILD_PLATFORMS_ALL="macosx,macosx-arm64,macosx-x86_64,macosx-both,ios,iossim,iossim-arm64,iossim-x86_64,iossim-both,catalyst,catalyst-arm64,catalyst-x86_64,catalyst-both,xros,xrossim,xrossim-arm64,xrossim-x86_64,xrossim-both,tvos,tvossim,tvossim-both,tvossim-arm64,tvossim-x86_64,watchos,watchossim,watchossim-both,watchossim-arm64,watchossim-x86_64"

BOOST_NAME=boost_${BOOST_VER//./_}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[[ $(clang++ --version | head -1 | sed -E 's/([a-zA-Z ]+)([0-9]+).*/\2/') -gt 14 ]] && CLANG15=true

LIBS_TO_BUILD=$LIBS_TO_BUILD_ALL
[[ ! $CLANG15 ]] && LIBS_TO_BUILD="${LIBS_TO_BUILD/,cobalt/}"

BUILD_PLATFORMS="macosx,ios,iossim,catalyst"
[[ -d $XROSSYSROOT/SDKs/XROS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xros"
[[ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xrossim"
[[ -d $TVOSSYSROOT/SDKs/AppleTVOS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvos"
[[ -d $TVOSSIMSYSROOT/SDKs/AppleTVSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvossim"
[[ -d $WATCHOSSYSROOT/SDKs/WatchOS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchos"
[[ -d $WATCHOSSIMSYSROOT/SDKs/WatchSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchossim-both"

REBUILD=false

# Function to determine architecture
boost_arc() {
    case $1 in
        arm*) echo "arm" ;;
        x86*) echo "x86" ;;
        *) echo "unknown" ;;
    esac
}

# Function to determine ABI
boost_abi() {
    case $1 in
        arm64) echo "aapcs" ;;
        x86_64) echo "sysv" ;;
        *) echo "unknown" ;;
    esac
}

is_subset() {
    local mainset=($(< $1))
    shift
    local subset=("$@")
    
    for element in "${subset[@]}"; do
        if [[ ! " ${mainset[@]} " =~ " ${element} " ]]; then
            echo "false"
            return
        fi
    done
    echo "true"
}

# Parse command line arguments
for i in "$@"; do
  case $i in
    -l=*|--libs=*)
      LIBS_TO_BUILD="${i#*=}"
      shift
      ;;
    -p=*|--platforms=*)
      BUILD_PLATFORMS="${i#*=},"
      shift
      ;;
    --rebuild)
      REBUILD=true
      [[ -f "$BUILD_DIR/frameworks.built.platforms" ]] && rm "$BUILD_DIR/frameworks.built.platforms"
      [[ -f "$BUILD_DIR/frameworks.built.libs" ]] && rm "$BUILD_DIR/frameworks.built.libs"
      shift
      ;;
    --rebuildicu)
      [[ -d $SCRIPT_DIR/Pods/icu4c-iosx ]] && rm -rf $SCRIPT_DIR/Pods/icu4c-iosx
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

LIBS_TO_BUILD=${LIBS_TO_BUILD//,/ }

#sort the library list
LIBS_TO_BUILD_ARRAY=($LIBS_TO_BUILD)
IFS=$'\n' LIBS_TO_BUILD_SORTED_ARRAY=($(sort <<<"${LIBS_TO_BUILD_ARRAY[*]}")); unset IFS
LIBS_TO_BUILD_SORTED="${LIBS_TO_BUILD_SORTED_ARRAY[@]}"
#LIBS_HASH=$( echo -n $LIBS_TO_BUILD_SORTED | shasum -a 256 | awk '{ print $1 }' )

for i in $LIBS_TO_BUILD; do :;
if [[ ! ",$LIBS_TO_BUILD_ALL," == *",$i,"* ]]; then
	echo "Unknown library '$i'"
	exit 1
fi
done

[[ $BUILD_PLATFORMS == *macosx-both* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//macosx-both/},macosx-arm64,macosx-x86_64"
[[ $BUILD_PLATFORMS == *iossim-both* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//iossim-both/},iossim-arm64,iossim-x86_64"
[[ $BUILD_PLATFORMS == *catalyst-both* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//catalyst-both/},catalyst-arm64,catalyst-x86_64"
[[ $BUILD_PLATFORMS == *xrossim-both* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//xrossim-both/},xrossim-arm64,xrossim-x86_64"
[[ $BUILD_PLATFORMS == *tvossim-both* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//tvossim-both/},tvossim-arm64,tvossim-x86_64"
[[ $BUILD_PLATFORMS == *watchossim-both* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//watchossim-both/},watchossim-arm64,watchossim-x86_64"
BUILD_PLATFORMS="$BUILD_PLATFORMS,"
[[ $BUILD_PLATFORMS == *"macosx,"* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//macosx,/,},macosx-$HOST_ARC"
[[ $BUILD_PLATFORMS == *"iossim,"* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//iossim,/,},iossim-$HOST_ARC"
[[ $BUILD_PLATFORMS == *"catalyst,"* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//catalyst,/,},catalyst-$HOST_ARC"
[[ $BUILD_PLATFORMS == *"xrossim,"* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//xrossim,/,},xrossim-$HOST_ARC"
[[ $BUILD_PLATFORMS == *"tvossim,"* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//tvossim,/,},tvossim-$HOST_ARC"
[[ $BUILD_PLATFORMS == *"watchossim,"* ]] && BUILD_PLATFORMS="${BUILD_PLATFORMS//watchossim,/,},watchossim-$HOST_ARC"

if [[ $BUILD_PLATFORMS == *"xros,"* ]] && [[ ! -d $XROSSYSROOT/SDKs/XROS.sdk ]]; then
    echo "The xros is specified as the build platform, but XROS.sdk is not found (the path $XROSSYSROOT/SDKs/XROS.sdk)."
    exit 1
fi

if [[ $BUILD_PLATFORMS == *"xrossim"* ]] && [[ ! -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]]; then
    echo "The xrossim is specified as the build platform, but XRSimulator.sdk is not found (the path $XROSSIMSYSROOT/SDKs/XRSimulator.sdk)."
    exit 1
fi

if [[ $BUILD_PLATFORMS == *"tvos,"* ]] && [[ ! -d $TVOSSYSROOT/SDKs/AppleTVOS.sdk ]]; then
    echo "The tvos is specified as the build platform, but AppleTVOS.sdk is not found (the path $TVOSSYSROOT/SDKs/AppleTVOS.sdk)."
    exit 1
fi

if [[ $BUILD_PLATFORMS == *"tvossim"* ]] && [[ ! -d $TVOSSIMSYSROOT/SDKs/AppleTVSimulator.sdk ]]; then
    echo "The tvossim is specified as the build platform, but AppleTVSimulator.sdk is not found (the path $TVOSSIMSYSROOT/SDKs/AppleTVSimulator.sdk)."
    exit 1
fi

if [[ $BUILD_PLATFORMS == *"watchos,"* ]] && [[ ! -d $WATCHOSSYSROOT/SDKs/WatchOS.sdk ]]; then
    echo "The tvos is specified as the build platform, but WatchOS.sdk is not found (the path $WATCHOSSYSROOT/SDKs/WatchOS.sdk)."
    exit 1
fi

if [[ $BUILD_PLATFORMS == *"watchossim"* ]] && [[ ! -d $WATCHOSSIMSYSROOT/SDKs/WatchSimulator.sdk ]]; then
    echo "The tvos is specified as the build platform, but WatchSimulator.sdk is not found (the path $WATCHOSSIMSYSROOT/SDKs/WatchSimulator.sdk)."
    exit 1
fi

BUILD_PLATFORMS_SPACED=" ${BUILD_PLATFORMS//,/ } "
BUILD_PLATFORMS_ARRAY=($BUILD_PLATFORMS_SPACED)

for i in $BUILD_PLATFORMS_SPACED; do :;
if [[ ! ",$BUILD_PLATFORMS_ALL," == *",$i,"* ]]; then
	echo "Unknown platform '$i'"
	exit 1
fi
done

[[ -f "$BUILD_DIR/frameworks.built.platforms" ]] && [[ -f "$BUILD_DIR/frameworks.built.libs" ]] && [[ $(< $BUILD_DIR/frameworks.built.platforms) == $BUILD_PLATFORMS ]] && [[ $(< $BUILD_DIR/frameworks.built.libs) == $LIBS_TO_BUILD ]] && exit 0

[[ -f "$BUILD_DIR/frameworks.built.platforms" ]] && rm "$BUILD_DIR/frameworks.built.platforms"
[[ -f "$BUILD_DIR/frameworks.built.libs" ]] && rm "$BUILD_DIR/frameworks.built.libs"


BOOST_ARCHIVE_FILE=$BOOST_NAME.tar.bz2

if [[ -f $BOOST_ARCHIVE_FILE ]]; then
	FILE_HASH=$(shasum -a 256 "$BOOST_ARCHIVE_FILE" | awk '{ print $1 }')
	if [[ ! "$FILE_HASH" == "$EXPECTED_HASH" ]]; then
    	echo "Wrong archive hash, trying to reload the archive"
        rm "$BOOST_ARCHIVE_FILE"
    fi
fi

if [[ ! -f $BOOST_ARCHIVE_FILE ]]; then
	TEMP_LOCATIONS_FILE=$(mktemp)
	curl -s -o "$TEMP_LOCATIONS_FILE" -L "$LOCATIONS_FILE_URL"
	if [[ $? -ne 0 ]]; then
	    echo "Failed to download the LOCATIONS file."
	    exit 1
	fi
	while IFS= read -r linktemplate; do
		linktemplate=${linktemplate/DOTVERSION/"$BOOST_VER"}
		link=${linktemplate/FILENAME/"$BOOST_ARCHIVE_FILE"}
		echo "downloading from \"$link\" ..."

	    curl -o "$BOOST_ARCHIVE_FILE" -L "$link"

	    # Check if the download was successful
	    if [ $? -eq 0 ]; then
	        FILE_HASH=$(shasum -a 256 "$BOOST_ARCHIVE_FILE" | awk '{ print $1 }')
	        if [[ "$FILE_HASH" == "$EXPECTED_HASH" ]]; then
	        	[[ -d boost ]] && rm -rf boost
	            break
	        else
	        	echo "Wrong archive hash $FILE_HASH, expected $EXPECTED_HASH. Trying next link to reload the archive."
                echo "File content: "
                head -c 1024 $BOOST_ARCHIVE_FILE
                echo ""
	        	rm $BOOST_ARCHIVE_FILE
	        fi
	    fi
	done < "$TEMP_LOCATIONS_FILE"
	rm "$TEMP_LOCATIONS_FILE"
fi

if [[ ! -f $BOOST_ARCHIVE_FILE ]]; then
	echo "Failed to download the Boost."
    exit 1
fi

if [[ ! -d boost ]]; then
	echo "extracting $BOOST_ARCHIVE_FILE ..."
	tar -xf $BOOST_ARCHIVE_FILE
	mv $BOOST_NAME boost
fi

if [[ ! -f boost/b2 ]]; then
	pushd boost
	./bootstrap.sh
	popd
fi

############### ICU
if true; then
#export ICU4C_RELEASE_LINK=https://github.com/apotocki/icu4c-iosx/releases/download/76.1.4
if [[ ! -f $SCRIPT_DIR/Pods/icu4c-iosx/build.success ]] || [[ $(is_subset $SCRIPT_DIR/Pods/icu4c-iosx/build.success "${BUILD_PLATFORMS_ARRAY[@]}") == "false" ]]; then
    if [[ ! -z "${ICU4C_RELEASE_LINK:-}" ]]; then
		[[ -d $SCRIPT_DIR/Pods/icu4c-iosx ]] && rm -rf $SCRIPT_DIR/Pods/icu4c-iosx
		mkdir -p $SCRIPT_DIR/Pods/icu4c-iosx/product
		pushd $SCRIPT_DIR/Pods/icu4c-iosx/product
        curl -L ${ICU4C_RELEASE_LINK}/include.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/include.zip
		curl -L ${ICU4C_RELEASE_LINK}/icudata.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icudata.xcframework.zip
		curl -L ${ICU4C_RELEASE_LINK}/icui18n.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icui18n.xcframework.zip
        #curl -L ${ICU4C_RELEASE_LINK}/icuio.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icuio.xcframework.zip
        curl -L ${ICU4C_RELEASE_LINK}/icuuc.xcframework.zip -o $SCRIPT_DIR/Pods/icu4c-iosx/product/icuuc.xcframework.zip
		unzip -q include.zip
		unzip -q icudata.xcframework.zip
		unzip -q icui18n.xcframework.zip
        #unzip -q icuio.xcframework.zip
        unzip -q icuuc.xcframework.zip
		mkdir frameworks
		mv icudata.xcframework frameworks/
		mv icui18n.xcframework frameworks/
        #mv icuio.xcframework frameworks/
        mv icuuc.xcframework frameworks/
        popd
        printf "${BUILD_PLATFORMS_ALL//,/ }" > build.success
    else
        if [[ ! -f $SCRIPT_DIR/Pods/icu4c-iosx/everbuilt.success ]]; then
            [[ -d $SCRIPT_DIR/Pods/icu4c-iosx ]] && rm -rf $SCRIPT_DIR/Pods/icu4c-iosx
            [[ ! -d $SCRIPT_DIR/Pods ]] && mkdir $SCRIPT_DIR/Pods
            pushd $SCRIPT_DIR/Pods
            git clone https://github.com/apotocki/icu4c-iosx
        else
            pushd $SCRIPT_DIR/Pods/icu4c-iosx
            git pull
        fi
        popd
        
        pushd $SCRIPT_DIR/Pods/icu4c-iosx
        scripts/build.sh -p=$BUILD_PLATFORMS
        touch everbuilt.success
        printf "${BUILD_PLATFORMS//,/ }" > build.success
        popd
        
        #pushd $SCRIPT_DIR
        #pod repo update
        #pod install --verbose
        ##pod update --verbose
        #popd
    fi
    mkdir -p $SCRIPT_DIR/Pods/icu4c-iosx/product/lib
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


B2_BUILD_OPTIONS="-j$THREAD_COUNT address-model=64 release link=static runtime-link=shared define=BOOST_SPIRIT_THREADSAFE cxxflags=\"-std=c++20\""

[[ ! -z "${ICU_PATH:-}" ]] && B2_BUILD_OPTIONS="$B2_BUILD_OPTIONS -sICU_PATH=\"$ICU_PATH\""

for i in $LIBS_TO_BUILD; do :;
  B2_BUILD_OPTIONS="$B2_BUILD_OPTIONS --with-$i"
done

[[ -d bin.v2 ]] && rm -rf bin.v2


#(paltform=$1 architecture=$2 additional_flags=$3 root=$4 depfilter=$5 additional_config=$6 additional_b2flags=$7)
build_generic_libs()
{
if [[ $REBUILD == true ]] || [[ ! -f $1-$2-build.success ]] || [[ $(is_subset $1-$2-build.success "${LIBS_TO_BUILD_ARRAY[@]}") == "false" ]]; then

    [[ -f $1-$2-build.success ]] && rm $1-$2-build.success
    
    [[ -f tools/build/src/user-config.jam ]] && rm -f tools/build/src/user-config.jam
    
    cat >> tools/build/src/user-config.jam <<EOF
using darwin : $1 : clang++ -arch $2 $3
: <striper> <root>$4
: <architecture>$(boost_arc $2) ${6:-}
;
EOF
    if [[ ! -z "${ICU_PATH:-}" ]]; then
        cp $ICU_PATH/frameworks/icudata.xcframework/$5/libicudata.a $ICU_PATH/lib/
        cp $ICU_PATH/frameworks/icui18n.xcframework/$5/libicui18n.a $ICU_PATH/lib/
        cp $ICU_PATH/frameworks/icuuc.xcframework/$5/libicuuc.a $ICU_PATH/lib/
    fi
    ./b2 -j8 --stagedir=stage/$1-$2 toolset=darwin-$1 architecture=$(boost_arc $2) abi=$(boost_abi $2) ${7:-} $B2_BUILD_OPTIONS
    rm -rf bin.v2
    printf "$LIBS_TO_BUILD_SORTED" > $1-$2-build.success
fi
}

build_macos_libs()
{
    build_generic_libs macosx $1 "$2 -isysroot $MACSYSROOT/SDKs/MacOSX.sdk" $MACSYSROOT "macos-*"
}

build_catalyst_libs()
{
    build_generic_libs catalyst $1 "--target=$1-apple-ios$CATALYST_VERSION-macabi -isysroot $MACSYSROOT/SDKs/MacOSX.sdk -I$MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include/ -isystem $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include -iframework $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/System/Library/Frameworks" $MACSYSROOT "ios-*-maccatalyst"
}

build_ios_libs()
{
    build_generic_libs ios arm64 "-fembed-bitcode -isysroot $IOSSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=$IOS_VERSION" $IOSSYSROOT "ios-arm64" "<target-os>iphone" "instruction-set=arm64 binary-format=mach-o target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN"
}

build_xros_libs()
{
    build_generic_libs xros arm64 "-fembed-bitcode -isysroot $XROSSYSROOT/SDKs/XROS.sdk" $XROSSYSROOT "xros-arm64" "<target-os>iphone" "instruction-set=arm64 binary-format=mach-o target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN"
}

build_tvos_libs()
{
    build_generic_libs tvos arm64 "-fembed-bitcode -isysroot $TVOSSYSROOT/SDKs/AppleTVOS.sdk" $TVOSSYSROOT "tvos-arm64" "<target-os>iphone" "instruction-set=arm64 binary-format=mach-o target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN define=BOOST_TEST_DISABLE_ALT_STACK"
}

build_watchos_libs()
{
    build_generic_libs watchos arm64 "-fembed-bitcode -isysroot $WATCHOSSYSROOT/SDKs/WatchOS.sdk" $WATCHOSSYSROOT "watchos-arm64" "<target-os>iphone" "instruction-set=arm64 binary-format=mach-o target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN define=BOOST_TEST_DISABLE_ALT_STACK"
}

build_sim_libs()
{
    build_generic_libs iossim $1 "-mios-simulator-version-min=$IOS_SIM_VERSION -isysroot $IOSSIMSYSROOT/SDKs/iPhoneSimulator.sdk" $IOSSIMSYSROOT "ios-*-simulator" "<target-os>iphone" "target-os=iphone define=BOOST_TEST_NO_MAIN"
}

build_xrossim_libs()
{
    build_generic_libs xrossim $1 "-isysroot $XROSSIMSYSROOT/SDKs/XRSimulator.sdk" $XROSSIMSYSROOT "xros-*-simulator" "<target-os>iphone" "target-os=iphone define=BOOST_TEST_NO_MAIN"
}

build_tvossim_libs()
{
    build_generic_libs tvossim $1 " --target=$1-apple-tvos$TVOS_SIM_VERSION-simulator -isysroot $TVOSSIMSYSROOT/SDKs/AppleTVSimulator.sdk" $TVOSSIMSYSROOT "tvos-*-simulator" "<target-os>iphone" "target-os=iphone define=BOOST_TEST_NO_MAIN define=BOOST_TEST_DISABLE_ALT_STACK"
}

build_watchossim_libs()
{
    build_generic_libs watchossim $1 "--target=$1-apple-watchos$WATCHOS_SIM_VERSION-simulator -isysroot $WATCHOSSIMSYSROOT/SDKs/WatchSimulator.sdk" $WATCHOSSIMSYSROOT "watchos-*-simulator" "<target-os>iphone" "target-os=iphone define=BOOST_TEST_NO_MAIN define=BOOST_TEST_DISABLE_ALT_STACK"
}

[[ -d stage/macosx/lib ]] && rm -rf stage/macosx/lib
[[ "$BUILD_PLATFORMS_SPACED" == *"macosx-arm64"* ]] && build_macos_libs arm64 -mmacosx-version-min=$MACOSX_VERSION_ARM
[[ "$BUILD_PLATFORMS_SPACED" == *"macosx-x86_64"* ]] && build_macos_libs x86_64 -mmacosx-version-min=$MACOSX_VERSION_X86_64
[[ "$BUILD_PLATFORMS_SPACED" == *"macosx"* ]] && mkdir -p stage/macosx/lib

[ -d stage/catalyst/lib ] && rm -rf stage/catalyst/lib
[[ "$BUILD_PLATFORMS_SPACED" == *"catalyst-arm64"* ]] && build_catalyst_libs arm64
[[ "$BUILD_PLATFORMS_SPACED" == *"catalyst-x86_64"* ]] && build_catalyst_libs x86_64
[[ "$BUILD_PLATFORMS_SPACED" == *"catalyst"* ]] && mkdir -p stage/catalyst/lib

[ -d stage/iossim/lib ] && rm -rf stage/iossim/lib
[[ "$BUILD_PLATFORMS_SPACED" == *"iossim-arm64"* ]] && build_sim_libs arm64
[[ "$BUILD_PLATFORMS_SPACED" == *"iossim-x86_64"* ]] && build_sim_libs x86_64
[[ "$BUILD_PLATFORMS_SPACED" == *"iossim"* ]] && mkdir -p stage/iossim/lib

[ -d stage/xrossim/lib ] && rm -rf stage/xrossim/lib
[[ "$BUILD_PLATFORMS_SPACED" == *"xrossim-arm64"* ]] && build_xrossim_libs arm64
[[ "$BUILD_PLATFORMS_SPACED" == *"xrossim-x86_64"* ]] && build_xrossim_libs x86_64
[[ "$BUILD_PLATFORMS_SPACED" == *"xrossim"* ]] && mkdir -p stage/xrossim/lib

[ -d stage/tvossim/lib ] && rm -rf stage/tvossim/lib
[[ "$BUILD_PLATFORMS_SPACED" == *"tvossim-arm64"* ]] && build_tvossim_libs arm64
[[ "$BUILD_PLATFORMS_SPACED" == *"tvossim-x86_64"* ]] && build_tvossim_libs x86_64
[[ "$BUILD_PLATFORMS_SPACED" == *"tvossim"* ]] && mkdir -p stage/tvossim/lib

[ -d stage/watchossim/lib ] && rm -rf stage/watchossim/lib
[[ "$BUILD_PLATFORMS_SPACED" == *"watchossim-arm64"* ]] && build_watchossim_libs arm64
[[ "$BUILD_PLATFORMS_SPACED" == *"watchossim-x86_64"* ]] && build_watchossim_libs x86_64
[[ "$BUILD_PLATFORMS_SPACED" == *"watchossim"* ]] && mkdir -p stage/watchossim/lib

[[ "$BUILD_PLATFORMS_SPACED" == *"ios "* ]] && build_ios_libs
[[ "$BUILD_PLATFORMS_SPACED" == *"xros "* ]] && build_xros_libs
[[ "$BUILD_PLATFORMS_SPACED" == *"tvos "* ]] && build_tvos_libs
[[ "$BUILD_PLATFORMS_SPACED" == *"watchos "* ]] && build_watchos_libs

echo installing boost...
[[ -d "$BUILD_DIR/frameworks" ]] && rm -rf "$BUILD_DIR/frameworks"
mkdir "$BUILD_DIR/frameworks"

build_lib()
{
	if [[ "$BUILD_PLATFORMS_SPACED" == *"$2-arm64"* ]]; then
		if [[ "$BUILD_PLATFORMS_SPACED" == *"$2-x86_64"* ]]; then
			lipo -create stage/$2-arm64/lib/lib$1.a stage/$2-x86_64/lib/lib$1.a -output stage/$2/lib/lib$1.a
			LIBARGS="$LIBARGS -library stage/$2/lib/lib$1.a"
		else
			LIBARGS="$LIBARGS -library stage/$2-arm64/lib/lib$1.a"
		fi
	else
		[[ "$BUILD_PLATFORMS_SPACED" == *"$2-x86_64"* ]] && LIBARGS="$LIBARGS -library stage/$2-x86_64/lib/lib$1.a"
	fi
}

build_xcframework()
{
	LIBARGS=
	[[ "$BUILD_PLATFORMS_SPACED" == *macosx* ]] && build_lib $1 macosx
	[[ "$BUILD_PLATFORMS_SPACED" == *catalyst* ]] && build_lib $1 catalyst
	[[ "$BUILD_PLATFORMS_SPACED" == *iossim* ]] && build_lib $1 iossim
	[[ "$BUILD_PLATFORMS_SPACED" == *xrossim* ]] && build_lib $1 xrossim
    [[ "$BUILD_PLATFORMS_SPACED" == *tvossim* ]] && build_lib $1 tvossim
    [[ "$BUILD_PLATFORMS_SPACED" == *watchossim* ]] && build_lib $1 watchossim
	[[ "$BUILD_PLATFORMS_SPACED" == *"ios "* ]] && LIBARGS="$LIBARGS -library stage/ios-arm64/lib/lib$1.a"
	[[ "$BUILD_PLATFORMS_SPACED" == *"xros "* ]] && LIBARGS="$LIBARGS -library stage/xros-arm64/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS_SPACED" == *"tvos "* ]] && LIBARGS="$LIBARGS -library stage/tvos-arm64/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS_SPACED" == *"watchos "* ]] && LIBARGS="$LIBARGS -library stage/watchos-arm64/lib/lib$1.a"
    xcodebuild -create-xcframework $LIBARGS -output "$BUILD_DIR/frameworks/$1.xcframework"
}

if true; then
for i in $LIBS_TO_BUILD; do :;
	if [ $i == "math" ]; then
		build_xcframework boost_math_c99
		build_xcframework boost_math_c99l
		build_xcframework boost_math_c99f
		build_xcframework boost_math_tr1
		build_xcframework boost_math_tr1l
		build_xcframework boost_math_tr1f
	elif [ $i == "log" ]; then
		build_xcframework boost_log
		build_xcframework boost_log_setup
	elif [ $i == "stacktrace" ]; then
		build_xcframework boost_stacktrace_basic
		build_xcframework boost_stacktrace_noop
		#build_xcframework boost_stacktrace_addr2line
	elif [ $i == "serialization" ]; then
		build_xcframework boost_serialization
		build_xcframework boost_wserialization
	elif [ $i == "test" ]; then
		build_xcframework boost_prg_exec_monitor
		build_xcframework boost_test_exec_monitor
		build_xcframework boost_unit_test_framework
	else
	    build_xcframework "boost_$i"
	fi
done


mkdir "$BUILD_DIR/frameworks/Headers"
cp -R boost "$BUILD_DIR/frameworks/Headers/"
#mv boost "$BUILD_DIR/frameworks/Headers/"
#touch "$BUILD_DIR/frameworks.built"
fi

printf "$BUILD_PLATFORMS" > $BUILD_DIR/frameworks.built.platforms
printf "$LIBS_TO_BUILD" > $BUILD_DIR/frameworks.built.libs

#rm -rf "$BUILD_DIR/boost"

popd
