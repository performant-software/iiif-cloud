source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.1'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.0.2', '>= 7.0.2.3'

# Use Postgres as the database for Active Record
gem 'pg'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Pagination
gem 'pagy', '~> 5.10'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# Resource API
gem 'resource_api', git: 'https://github.com/performant-software/resource-api.git', tag: 'v0.4.3'

# Use Json Web Token (JWT) for token based authentication
gem 'jwt'

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Active storage service
gem 'aws-sdk-s3'

# Image processing
gem 'mini_magick', '~> 4.11'

# EXIF data
gem 'exif', '~> 2.2.3'

# HTTP requests
gem 'httparty', '~> 0.17.3'

# User defined fields
gem 'user_defined_fields', git: 'https://github.com/performant-software/user-defined-fields.git', tag: 'v0.1.5'

# Data migrations
gem 'data_migrate', '~> 8.1.1'

# Background jobs
gem 'sidekiq', '~> 6.5.7', group: :production

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]

  # Environment variable management
  gem 'dotenv-rails'
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

