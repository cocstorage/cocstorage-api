source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3', '>= 6.0.3.2'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.4.4'
# Use Puma as the app server
gem 'puma'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.1'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'
end

group :development do
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'active_model_serializers', '~> 0.10.0'
gem 'devise'
gem 'devise-jwt', '~> 0.9.0'
gem 'kaminari'
gem 'nokogiri'
gem 'selenium-webdriver'
gem 'webdrivers'
gem 'olive_branch'
gem 'redis-namespace', '~> 1.6'
gem 'sidekiq'
gem 'aws-sdk-s3', require: false
gem 'sidekiq-limit_fetch'
gem 'newrelic_rpm'
gem "mini_magick"

# https://stackoverflow.com/questions/65479863/rails-6-1-ruby-3-0-0-tests-error-as-they-cannot-load-rexml
gem 'rexml'

# https://github.com/rails/rails/issues/41750
# https://rubygems.org/gems/mimemagic/versions
gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: 'af5a9b1c5b774e65fd84bd7ca4239a9f3eba2039', platforms: [:mingw, :mswin, :x64_mingw, :jruby]