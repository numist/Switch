Pod::Spec.new do |s|
  s.cocoapods_version = '>= 1.8'
  s.name = 'ShortcutRecorder'
  s.version = '3.3.0'
  s.summary = 'The best control to record shortcuts on macOS'
  s.homepage = 'https://github.com/Kentzo/ShortcutRecorder'
  s.license = { :type => 'CC BY 4.0', :file => 'LICENSE.txt' }
  s.author = { 'Ilya Kulakov' => 'kulakov.ilya@gmail.com' }
  s.screenshot = 'https://user-images.githubusercontent.com/88809/67132003-e4b8b780-f1bb-11e9-984d-2c88fc8c2286.gif'

  s.source = { :git => 'https://github.com/Kentzo/ShortcutRecorder.git', :tag => s.version }

  s.platform = :osx
  s.osx.deployment_target = "10.11"
  s.frameworks = 'Carbon', 'Cocoa'

  s.source_files = 'Sources/ShortcutRecorder/**/*.{h,m}'
  s.public_header_files = 'Sources/ShortcutRecorder/include/ShortcutRecorder/*.h'
  s.resources = [
    'Sources/ShortcutRecorder/Resources/*.lproj',
    'Sources/ShortcutRecorder/Resources/Images.xcassets',
    'ATTRIBUTION.md',
    'LICENSE.txt'
  ]
  s.requires_arc = true
  s.compiler_flags = ['-fstack-protector', '-mssse3']
  s.info_plist = {
    'CFBundleIdentifier' => 'com.kulakov.ShortcutRecorder'
  }
  s.pod_target_xcconfig = {
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.kulakov.ShortcutRecorder'
  }

  s.test_spec 'Tests' do |t|
    t.osx.deployment_target = '10.14'
    t.source_files = 'Tests/ShortcutRecorderTests/*.swift'
    t.exclude_files = 'Tests/ShortcutRecorderTests/XCTestManifests.swift'
  end
end
