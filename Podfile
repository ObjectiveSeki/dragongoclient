platform :ios, :deployment_target => "4.0"
xcodeproj 'DGSPhone.xcodeproj'

pod 'ASIHTTPRequest'
pod 'GDataXML-HTML'
pod 'JSONKit'
pod 'HockeyKit'

target :logic_tests, :exclusive => true do
  link_with 'LogicTests'
  pod 'GDataXML-HTML'
end
