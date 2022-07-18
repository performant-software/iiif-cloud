# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

Rails.application.routes.default_url_options[:protocol] = 'https' if Rails.application.config.force_ssl
Rails.application.routes.default_url_options[:host] = ENV['HOSTNAME']
