# Boost C++ for iOS and Mac OS X - arm64 / x86_64

Supported version: 1.75.0

This repo provides a universal script for building static Boost C++ libraries for use in iOS and Mac OS X applications.
The actual Boost version is taken from https://dl.bintray.com/boostorg/release/1.75.0/source/boost_1_75_0.tar.bz2

## Building libraries
atomic, chrono, container, context, contract, coroutine, date_time, exception, fiber, filesystem, graph, iostreams, json, locale, log, math, nowide, program_options, random, regex, serialization, stacktrace, system, test, thread, timer, type_erasure, wave

## Not building libraries
graph_parallel, mpi, python

## Building notes
1) Libraries 'locale' and 'regex' are being built with ICU backend. ICU build scripts are being taken from https://github.com/apotocki/icu4c-iosx and run with the help of 'pod' utility.
2) 'test' library is building for iOS with BOOST_TEST_NO_MAIN flag.

## How to build?
 - Manually
```
    # clone the repo
    git clone -b 1.75.0 https://github.com/apotocki/boost-iosx
    
    # build libraries
    cd boost-iosx
    scripts/build.sh

    # have fun, the result artifacts will be located in 'frameworks' folder.
    # Then you can add desirable xcframewors in your XCode project. The process is described, e.g., at https://www.simpleswiftguide.com/how-to-add-xcframework-to-xcode-project/
```    
 - Use cocoapods. Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'boost-iosx'
    # or optionally more precisely
    # pod 'boost-iosx', :git => 'https://github.com/apotocki/boost-iosx', :branch => '1.75.0', :submodules => 'true'
``` 
If you want to use particular boost libraries, specify them as in the following example for log and program_options libraries:
``` 
    pod 'boost-iosx/log'
    pod 'boost-iosx/program_options'
    # note: Some libraries have dependencies on other Boost libraries. In that case, you should explicitly add all their dependencies to your Podfile.
```
Then install new dependencies:
```
   pod install --verbose
```    
