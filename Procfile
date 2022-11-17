web: bundle exec puma -C config/puma.rb
release: bin/rake db:migrate:with_data
worker: bundle exec sidekiq -q default -c 1
