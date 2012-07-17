source :gemcutter
gem 'padrino'

gem 'addressable'

gem 'backports'
gem 'dalli'
gem 'em-http-request', '~> 1.0'
gem 'em-synchrony',    '~> 1.0'
gem 'metriks'
gem 'metriks-middleware'
gem 'pygments.rb'
gem 'redcarpet', '~> 2.1'
gem 'rack-cache'
gem 'simpleidn'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'thin'
gem 'yajl-ruby'

# Version 0.5.3 errors on heroku: https://github.com/tmm1/pygments.rb/issues/10
# Version 0.6.x and pygments.rb don't play nicely. pygments.rb keeps trying to
# start RubyPython with a different python executable which throws a warning
# (very slow warning, I might add). I don't trust it in production.
gem 'rubypython', '0.5.1'

# New rule: No locking to a specifc version without a note.
gem 'activesupport', '3.1.3'
gem 'ffi', '1.0.9'

gem 'airbrake'
gem 'newrelic_rpm'

gem 'jammit-s3', :git => 'https://github.com/kmamykin/jammit-s3.git'

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'vcr', '~> 1.11'
  gem 'webmock'
  gem 'wrong'
end

group :development do
  gem 'compass'
  gem 'foreman'
  gem 'rocco'
end
