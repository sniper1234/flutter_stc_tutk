#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_stc_tutk'
  s.version          = '0.0.1'
  s.summary          = 'The Flutter iOS SDK library for STC scenes app based on Tutk.'
  s.description      = <<-DESC
The Flutter iOS SDK library for STC scenes app based on Tutk. It is only used for STC devices connection.
                       DESC
  s.homepage         = 'https://github.com/sniper1234/flutter_stc_tutk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Scenes Tek' => 'lawrence.sun@scenestek.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '9.0'
  s.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'CoreVideo', 'CoreMedia', 'VideoToolbox', 'CoreGraphics'
  s.vendored_libraries = 'STCTutkSDK/Lib/libIOTCAPIs_ALL.a'
end

