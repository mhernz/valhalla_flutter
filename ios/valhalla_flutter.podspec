#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint valhalla_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'valhalla_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.platform = :ios, '13.0'

s.prepare_command = <<-CMD
    set -e
    export VCPKG_DEFAULT_TRIPLET=arm64-ios
    export VCPKG_HOST_TRIPLET=x64-osx
    rm -f build/build.log
    cmake -S ../src -B build/iphone \
          -DCMAKE_SYSTEM_NAME=iOS \
          -DCMAKE_OSX_ARCHITECTURES=arm64 \
          -DVCPKG_TARGET_ARCHITECTURE=arm64 \
          -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
          -DVCPKG_TARGET_TRIPLET=arm64-ios \
          -DABSL_OPTION_USE_STD_STRING_VIEW=0 \
          -DCMAKE_INSTALL_PREFIX=install-iphone | tee build/build.log
    cmake --build build/iphone --config Release | tee -a build/build.log

    export VCPKG_DEFAULT_TRIPLET=x64-ios
    cmake -S ../src -B build/sim \
          -DCMAKE_SYSTEM_NAME=iOS \
          -DCMAKE_OSX_ARCHITECTURES=x86_64 \
          -DVCPKG_TARGET_ARCHITECTURE=x64 \
          -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
          -DVCPKG_TARGET_TRIPLET=x64-ios \
          -DABSL_OPTION_USE_STD_STRING_VIEW=0 \
          -DCMAKE_INSTALL_PREFIX=install-sim | tee -a build/build.log
    cmake --build build/sim --config Release | tee -a build/build.log

    mkdir -p lib/
    rm -rf lib/valhalla_flutter.xcframework
    xcodebuild -create-xcframework \
        -framework build/sim/valhalla_flutter.framework \
        -framework build/iphone/valhalla_flutter.framework \
        -output lib/valhalla_flutter.xcframework
  CMD

  # Specify where to find the built libraries
  s.vendored_frameworks = 'lib/valhalla_flutter.xcframework'
  s.preserve_paths = 'lib/valhalla_flutter.xcframework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
