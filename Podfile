platform :ios, '15.0'
project 'DGSPhone.xcodeproj'


target 'DGS' do
  pod 'GDataXML-HTML', '~> 1.0.0'
  pod 'MKNetworkKit'
  pod 'boost-framework', :podspec => 'boost-framework.podspec'
  pod 'fuego-framework', :podspec => 'fuego-framework.podspec'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end

post_integrate do |installer|
  system('python3', 'scripts/prepare-legacy-pods.py') || raise('Legacy dependency preparation failed')
end
