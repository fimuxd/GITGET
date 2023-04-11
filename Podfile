# Uncomment the next line to define a global platform for your project
# platform :ios, '14.0'

target 'GITGET' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for GITGET
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'Then'
  pod 'SnapKit'
  pod 'SwiftSoup'
  pod 'SwiftDate'
  pod 'PanModal'

  target 'CONTRIBUTIONSExtension' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!

    # Pods for CONTRIBUTIONSExtension
    pod 'Kingfisher', '~> 6.1.0'

  end

  target 'GITGETTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
               end
          end
   end
end
