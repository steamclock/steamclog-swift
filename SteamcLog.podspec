#
# Be sure to run `pod lib lint SteamcLog.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SteamcLog'
  s.version          = '0.3.0'
  s.summary          = 'A short description of SteamcLog.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/steamclock/SteamcLog'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'brendan@steamclock.com' => 'brendan@steamclock.com' }
  s.source           = { :git => 'https://github.com/steamclog/SteamcLog.git', :tag => s.version.to_s }
  s.source_files     = 'SteamcLog/Classes/**/*'
  s.ios.deployment_target = '11.0'
  
  s.dependency 'XCGLogger', '~> 7.0.1'
  s.dependency 'Sentry', '~> 5'

  s.subspec 'Netable' do |ss|
    ss.source_files = 'Netable/*', 'SteamcLog/Classes/**/*'
    ss.dependency 'Netable'
  end
end
