require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-ipsec-ikev2-pro"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  react-native-ipsec-ikev2-pro
                   DESC
  s.homepage     = "https://github.com/darknessproduction/react-native-ipsec-ikev2-pro"
  s.license      = "MIT"
  s.authors      = { "sinajavaheri" => "ilya@sarzhevsky.com" }
  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/darknessproduction/react-native-ipsec-ikev2-pro", :tag => "#{s.version}" }
  s.source_files = "ios/**/*.{h,c,m,swift}"
  s.requires_arc = true
  s.dependency "React"
end
