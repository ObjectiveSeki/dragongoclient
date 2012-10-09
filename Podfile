platform :ios, :deployment_target => "5.1"
xcodeproj 'DGSPhone.xcodeproj'

pod 'ASIHTTPRequest'
pod 'GDataXML-HTML'
pod 'JSONKit'
pod 'ODRefreshControl'
pod 'InnerBand'

target :logic_tests, :exclusive => true do
  link_with 'LogicTests'
  pod 'GDataXML-HTML'
  pod 'JSONKit'
end
