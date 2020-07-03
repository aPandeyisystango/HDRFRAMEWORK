
Pod::Spec.new do |s|
  s.name             = 'HDRFramework'
  s.version          = '0.0.1'
  s.summary          = 'A custom camera framework'

  s.description      = 'A custom camera framework where you take HDR & Wide Angle images.'

  s.homepage         = 'https://github.com/apandeyisystango/HDRFramework'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'apandeyisystango' => 'apandey@isystango.com' }
  s.source           = { :git => 'https://github.com/apandeyisystango/HDRFramework.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'HDRFramework/**/*'
  s.swift_version    = "5.0"
  s.platform         = :ios, "11.0"
end

