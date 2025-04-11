Pod::Spec.new do |s|
    s.name         = "boost-iosx"
    s.version      = "1.88.0.1"
    s.summary      = "Boost C++ libraries for macOS, iOS, watchOS, tvOS, and visionOS, including builds for Mac Catalyst, iOS Simulator, watchOS Simulator, tvOS Simulator, and visionOS Simulator."
    s.homepage     = "https://github.com/apotocki/boost-iosx"
    s.license      = "Boost Software License"
    s.author       = { "Alexander Pototskiy" => "alex.a.potocki@gmail.com" }
    s.social_media_url = "https://www.linkedin.com/in/alexander-pototskiy"
    s.ios.deployment_target = "13.4"
    s.osx.deployment_target = "11.0"
    s.tvos.deployment_target = "13.0"
    s.watchos.deployment_target = "11.0"
    s.visionos.deployment_target = "1.0"
    s.ios.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.osx.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.tvos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.watchos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.visionos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.ios.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.osx.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.tvos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.watchos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.visionos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.static_framework = true
    s.prepare_command = "sh scripts/build.sh"
    s.source       = { :git => "https://github.com/apotocki/boost-iosx.git", :tag => "#{s.version}" }

    s.header_mappings_dir = "frameworks/Headers"
    #s.public_header_files = "frameworks/Headers/**/*.{h,hpp,ipp}"

    s.default_subspec = "all"

    s.subspec 'all' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_atomic.xcframework", "frameworks/boost_charconv.xcframework", "frameworks/boost_chrono.xcframework", "frameworks/boost_cobalt.xcframework", "frameworks/boost_container.xcframework", "frameworks/boost_context.xcframework", "frameworks/boost_contract.xcframework", "frameworks/boost_coroutine.xcframework", "frameworks/boost_date_time.xcframework", "frameworks/boost_exception.xcframework", "frameworks/boost_fiber.xcframework", "frameworks/boost_filesystem.xcframework", "frameworks/boost_graph.xcframework", "frameworks/boost_iostreams.xcframework", "frameworks/boost_json.xcframework", "frameworks/boost_locale.xcframework", "frameworks/boost_log.xcframework", "frameworks/boost_log_setup.xcframework", "frameworks/boost_nowide.xcframework", "frameworks/boost_program_options.xcframework", "frameworks/boost_random.xcframework", "frameworks/boost_regex.xcframework", "frameworks/boost_serialization.xcframework", "frameworks/boost_stacktrace_basic.xcframework", "frameworks/boost_prg_exec_monitor.xcframework", "frameworks/boost_test_exec_monitor.xcframework", "frameworks/boost_unit_test_framework.xcframework", "frameworks/boost_thread.xcframework", "frameworks/boost_timer.xcframework", "frameworks/boost_type_erasure.xcframework", "frameworks/boost_system.xcframework", "frameworks/boost_url.xcframework", "frameworks/boost_wave.xcframework"
    end

    s.subspec 'atomic' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_atomic.xcframework"
    end
    s.subspec 'charconv' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_charconv.xcframework"
    end
    s.subspec 'chrono' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_chrono.xcframework"
    end
    s.subspec 'cobalt' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_cobalt.xcframework"
    end
    s.subspec 'container' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_container.xcframework"
    end
    s.subspec 'context' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_context.xcframework"
    end
    s.subspec 'contract' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_contract.xcframework"
    end
    s.subspec 'coroutine' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_coroutine.xcframework"
    end
    s.subspec 'date_time' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_date_time.xcframework"
    end
    s.subspec 'exception' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_exception.xcframework"
    end
    s.subspec 'fiber' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_fiber.xcframework", "frameworks/boost_context.xcframework"
    end
    s.subspec 'filesystem' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_filesystem.xcframework"
    end
    s.subspec 'graph' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_graph.xcframework"
    end
    s.subspec 'iostreams' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_iostreams.xcframework"
    end
    s.subspec 'json' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_json.xcframework"
    end
    s.subspec 'locale' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_locale.xcframework"
    end
    s.subspec 'log' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_log.xcframework", "frameworks/boost_log_setup.xcframework"
    end
    s.subspec 'math_c99' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_math_c99.xcframework"
    end
    s.subspec 'math_c99l' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_math_c99l.xcframework"
    end
    s.subspec 'math_c99f' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_math_c99f.xcframework"
    end
    s.subspec 'math_tr1' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_math_tr1.xcframework"
    end
    s.subspec 'math_tr1l' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_math_tr1l.xcframework"
    end
    s.subspec 'math_tr1f' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_math_tr1f.xcframework"
    end
    s.subspec 'nowide' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_nowide.xcframework"
    end
    s.subspec 'program_options' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_program_options.xcframework"
    end
    s.subspec 'random' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_random.xcframework"
    end
    s.subspec 'regex' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_regex.xcframework"
    end
    s.subspec 'serialization' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_serialization.xcframework"
    end
    s.subspec 'wserialization' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_wserialization.xcframework"
    end
    s.subspec 'stacktrace_basic' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_stacktrace_basic.xcframework"
    end
    s.subspec 'stacktrace_noop' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_stacktrace_noop.xcframework"
    end
    s.subspec 'test' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_prg_exec_monitor.xcframework", "frameworks/boost_test_exec_monitor.xcframework", "frameworks/boost_unit_test_framework.xcframework"
    end
    s.subspec 'thread' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_thread.xcframework"
    end
    s.subspec 'timer' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_timer.xcframework"
    end
    s.subspec 'type_erasure' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_type_erasure.xcframework"
    end
    s.subspec 'url' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_url.xcframework"
    end
    s.subspec 'wave' do |ss|
        ss.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
        ss.vendored_frameworks = "frameworks/boost_wave.xcframework"
    end
    #s.preserve_paths = "frameworks/**/*"
    #s.dependency "icu4c-iosx"
end

