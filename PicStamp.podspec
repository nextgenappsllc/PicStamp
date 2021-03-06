#
# Be sure to run `pod lib lint PicStamp.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PicStamp'
  s.version          = '0.1.0'
  s.summary          = 'Take, pick, label and stamp pictures'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This pod contains all the code to take, pick, label and stamp pictures. Including the views and controllers.
                       DESC

  s.homepage         = 'https://github.com/nextgenappsllc/PicStamp'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nextgenappsllc' => 'nextgenappsllc@gmail.com' }
  s.source           = { :git => 'https://github.com/nextgenappsllc/PicStamp.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'PicStamp/Classes/**/*'
  
  s.resource_bundles = {'PicStamp' => ['PicStamp/Assets/*.png']}

  # s.public_header_files = 'Pod/Classes/**/*.h'
    s.frameworks = 'UIKit', 'Photos'
    s.dependency 'Eureka', '~> 3.0'
    s.dependency 'SQLite.swift', '~> 0.11'
    s.dependency 'NGAEssentials', '~> 0.1'
    s.dependency 'NGAUI', '~> 0.1'
  # s.dependency 'NGAFramework', git: 'ssh://jose@localhost/Users/Jose/swift/pods/NGAFramework/'
end
