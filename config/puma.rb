threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }
threads threads_count, threads_count

port ENV.fetch('PORT') { 3000 }
environment ENV.fetch('RACK_ENV') { 'development' }

# Не используем workers на Windows
unless Gem.win_platform?
  workers ENV.fetch('WEB_CONCURRENCY') { 2 }
  preload_app!
end

on_worker_boot do
  # Worker specific setup
end

# Allow puma to be restarted by `rails restart`