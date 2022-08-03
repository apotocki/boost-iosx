# Boost C++ for iOS and Mac OS X (Intel & Apple Silicon M1) & Catalyst - arm64 / x86_64

Supported version: 1.79.0 (use the appropriate tag to select the version)

This repo provides a universal script for building static Boost C++ libraries for use in iOS and Mac OS X & Catalyst applications.
The latest supported Boost version is taken from: https://boostorg.jfrog.io/artifactory/main/release/1.79.0/source/boost_1_79_0.tar.bz2

## Building libraries
atomic, chrono, container, context, contract, coroutine, date_time, exception, fiber, filesystem, graph, iostreams, json, locale, log, math, nowide, program_options, random, regex, serialization, stacktrace, system, test, thread, timer, type_erasure, wave

## Not building libraries
graph_parallel, mpi, python

## Prerequisites
  1) Xcode must be installed because xcodebuild is used to create xcframeworks
  2) ```xcode-select -p``` must point to Xcode app developer directory (by default e.g. /Applications/Xcode.app/Contents/Developer). If it points to CommandLineTools directory you should execute:
  ```sudo xcode-select --reset``` or ```sudo xcode-select -s /Applications/Xcode.app/Contents/Developer```
  3) You should not have your own user-config.jam file in your home directory!

## Building notes
1) Libraries 'locale' and 'regex' are being built with ICU backend. ICU build scripts are being taken from https://github.com/apotocki/icu4c-iosx and run with the help of 'pod' utility.
2) 'test' library is building for iOS with BOOST_TEST_NO_MAIN flag.

## How to build?
 - Manually
```
    # clone the repo
    git clone -b 1.79.0 https://github.com/apotocki/boost-iosx
    
    # build libraries
    cd boost-iosx
    scripts/build.sh

    # have fun, the result artifacts will be located in 'frameworks' folder.
    # Then you can add desirable xcframewors in your XCode project. The process is described, e.g., at https://www.simpleswiftguide.com/how-to-add-xcframework-to-xcode-project/
```    
 - Use cocoapods. Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'boost-iosx', '~> 1.79.0'
    # or optionally more precisely e.g.:
    # pod 'boost-iosx', :git => 'https://github.com/apotocki/boost-iosx', :tag => '1.79.0.3'
``` 
If you want to use particular boost libraries, specify them as in the following example for log and program_options libraries:
``` 
    pod 'boost-iosx/log', '~> 1.79.0'
    pod 'boost-iosx/program_options', '~> 1.79.0'
    # note: Some libraries have dependencies on other Boost libraries. In that case, you should explicitly add all their dependencies to your Podfile.
```
Then install new dependencies:
```
   pod install --verbose
```    

## As an advertisement…
Boost libraries built by this project were used in my iOS application on App Store:

[<table align="center" border=0 cellspacing=0 cellpadding=0><tr><td><img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70"/></td><td><a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br>HEX File Viewer & Editor</td><tr></table>]()

This app is designed for viewing and editing files at byte or character level.
  
You can support my open-source development by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

Feedbacks are also welcome!
