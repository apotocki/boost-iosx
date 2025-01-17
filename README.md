# Boost C++ for iOS, watchOS, tvOS, visionOS, macOS, Catalyst, Simulators - Intel(x86_64) / Apple Silicon(arm64)

Supported version: 1.84.0 (use the appropriate tag to select the version)

This repo provides a universal script for building static Boost C++ libraries for use in iOS, watchOS, tvOS, visionOS, and macOS & Catalyst applications.

Since the Boost distribution URLs are often broken and change, the script tries to download it from the links specified in the LOCATIONS file in the master branch. Only after the SHA256 hash of the downloaded archive is verified, the libraries are unpacked and compiled.

## Building libraries
atomic, chrono, cobalt (requires apple clang-15.0.0 or later), container, context, contract, coroutine, date_time, exception, fiber, filesystem, graph, iostreams, json, locale, log, math, nowide, program_options, random, regex, serialization, stacktrace, system, test, thread, timer, type_erasure, url, wave

## Not building libraries
graph_parallel, mpi, python

## Prerequisites
  1) Xcode must be installed because xcodebuild is used to create xcframeworks
  2) ```xcode-select -p``` must point to Xcode app developer directory (by default e.g. /Applications/Xcode.app/Contents/Developer). If it points to CommandLineTools directory you should execute:
  ```sudo xcode-select --reset``` or ```sudo xcode-select -s /Applications/Xcode.app/Contents/Developer```
  3) You should not have your own user-config.jam file in your home directory!
  4) Building for tvOS, watchOS, visionOS and their simulators requires the appropriate SDKs to be installed in the folder /Applications/Xcode.app/Contents/Developer/Platforms

## Building notes
1) The 'locale' and 'regex' libraries are built using the ICU backend. There are two ways to get it. The first (default) is when the ICU libraries are automatically built before Boost is built using the build script from https://github.com/apotocki/icu4c-iosx . The second is by specifying the ICU4C_RELEASE_LINK environment variable where prebuit binaries can be downloaded from.
2) The 'test' library is built for iOS and visionOS with the BOOST_TEST_NO_MAIN flag.
3) The 'test' library is built for watchOS and tvOS with the BOOST_TEST_NO_MAIN and BOOST_TEST_DISABLE_ALT_STACK flags.

# Build Manually
```
    # clone the repo
    git clone -b 1.84.0 https://github.com/apotocki/boost-iosx
    
    # build libraries
    cd boost-iosx
    scripts/build.sh
    
    # However, if you wish, you can skip building the ICU libraries during the boost build and use pre-built binaries from my ICU repository:
    # ICU4C_RELEASE_LINK=https://github.com/apotocki/icu4c-iosx/releases/download/76.1.4 scripts/build.sh
    
    # have fun, the result artifacts will be located in 'frameworks' folder.
    # Then you can add desirable xcframeworks in your XCode project. The process is described, e.g., at https://www.simpleswiftguide.com/how-to-add-xcframework-to-xcode-project/
```
# Selecting Platforms and Architectures
build.sh without arguments builds xcframeworks for iOS, macOS, Catalyst and also for watchOS, tvOS, visionOS if their SDKs are installed on the system. It also builds xcframeworks for their simulators with the architecture (arm64 or x86_64) depending on the current host.
If you are interested in a specific set of platforms and architectures, you can specify them explicitly using the -p argument, for example:
```
scripts/build.sh -p=ios,iossim-x86_64
# builts xcframeworks only for iOS and iOS Simulator with x86_64 architecture
```
Here is a list of all possible values for '-p' option:
```
macosx,macosx-arm64,macosx-x86_64,macosx-both,ios,iossim,iossim-arm64,iossim-x86_64,iossim-both,catalyst,catalyst-arm64,catalyst-x86_64,catalyst-both,xros,xrossim,xrossim-arm64,xrossim-x86_64,xrossim-both,tvos,tvossim,tvossim-both,tvossim-arm64,tvossim-x86_64,watchos,watchossim,watchossim-both,watchossim-arm64,watchossim-x86_64
```
Suffix '-both' means that xcframeworks will be built for both arm64 and x86_64 architectures.
The platform names for macosx and simulators without an architecture suffix (e.g. macosx, iossim, tvossim) mean that xcframeworks are only built for the current host architecture.

## Selecting Libraries
If you want to build specific boost libraries, specify them with the -l option:
```
scripts/build.sh -l=log,program_options
# Note: Some libraries depend on other Boost libraries. In this case, you should explicitly add them all in the -l option.
```
## Rebuild ICU option
To rebuild the ICU library, which is used when building some Boost libraries (locale and regex), use the --rebuildicu option.
```
scripts/build.sh -p=ios,iossim-x86_64 --rebuildicu
```
## Rebuild option
To rebuild the libraries without using the results of previous builds, use the --rebuild option
```
scripts/build.sh -p=ios,iossim-x86_64 --rebuild

```

# Build Using Cocoapods.
Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'boost-iosx', '~> 1.84.0'
    # or optionally more precisely e.g.:
    # pod 'boost-iosx', :git => 'https://github.com/apotocki/boost-iosx', :tag => '1.84.0.7'
```
If you want to use specific boost libraries, specify them as in the following example for log and program_options libraries:
``` 
    pod 'boost-iosx/log', '~> 1.84.0'
    pod 'boost-iosx/program_options', '~> 1.84.0'
    # Note: Some libraries depend on other Boost libraries. In this case, you should explicitly add all their dependencies to your Podfile.
```
Then install new dependencies:
```
   pod install --verbose
```

## As an advertisement...
The Boost libraries built by this project are used in my iOS application on the App Store:

[<table align="center" border=0 cellspacing=0 cellpadding=0><tr><td><img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70"/></td><td><a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br>HEX File Viewer & Editor</td><tr></table>]()

This application is designed to view and edit files at the byte or character level; calculate different hashes, encode/decode, and compress/decompress desired byte regions.
  
You can support my open-source development by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

Feedback is welcome!
