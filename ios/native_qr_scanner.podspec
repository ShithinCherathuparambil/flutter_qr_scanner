#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_qr_scanner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_qr_scanner'
  s.version          = '0.0.1'
  s.summary          = 'A fast, cross-platform Flutter plugin for native QR and barcode scanning.'
  s.description      = <<-DESC
A fast, cross-platform Flutter plugin for QR and barcode scanning with auto-zoom on Android via Google Play Services and AVFoundation on iOS.
                       DESC
  s.homepage         = 'https://github.com/ShithinCherathuparambil/flutter_qr_scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Shithin Cherathuparambil' => 'shithincp@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_qr_scanner/Sources/flutter_qr_scanner/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

