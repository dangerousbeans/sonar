# -*- encoding: utf-8 -*-

version = '0.2.0'
Gem::Specification.new do |s|

  s.name = 'sonar'
  s.version = version
  s.authors = ['Walter Smith']
  s.email = ['waltee.smith@gmail.com']
  s.homepage = 'https://github.com/waltee/sonar'
  s.summary = 'sonar-%s' % version
  s.description = 'API for Testing Rack Applications via Mock HTTP'

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'rack', '~> 1.5'

  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'specular', '~> 0.2.2'
  s.add_development_dependency 'bundler'

  s.require_paths = ['lib']
  s.files = Dir['**/{*,.[a-z]*}'].reject {|e| e =~ /\.(gem|lock)\Z/}
  s.licenses = ['MIT']
end
