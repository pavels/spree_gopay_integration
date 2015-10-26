# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gopay_integration'
  s.version     = '1.0.0'
  s.summary     = 'Gopay integration for spree'
  s.description = 'Gopay integration for spree'
  s.required_ruby_version = '>= 2.0.0'

  s.author    = 'Pavel Sorejs'
  s.homepage  = 'https://github.com/pavels/spree_gopay_integration'

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'configurations'
  
  s.add_development_dependency 'capybara', '~> 2.4'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.5'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 3.1'
  s.add_development_dependency 'sass-rails', '~> 5.0.0.beta1'
  s.add_development_dependency 'simplecov'
end
