source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.5"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 1.4"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Rails 8.0's ActiveSupport::JSON calls JSON.generate(.., quirks_mode: true),
# a keyword json 3.0 removed. Ruby 3.4 ships json 3.x, so hold it on 2.x.
gem "json", "< 3.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Hyperstack — React components in Ruby
# All gems pinned to fork branch to get Rails 8 / Ruby 3.4 fixes
gem "rails-hyperstack", github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/rails-hyperstack/*.gemspec"
gem "hyper-component",  github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-component/*.gemspec"
gem "hyper-state",      github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-state/*.gemspec"
gem "hyperstack-config", github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyperstack-config/*.gemspec"
gem "hyper-store",      github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-store/*.gemspec"
# rails-hyperstack also pulls in hyper-model, hyper-router, hyper-operation;
# pin them explicitly to the same fork so we get all Rails 8 fixes
gem "hyper-model",     github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-model/*.gemspec"
gem "hyper-router",    github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-router/*.gemspec"
gem "hyper-operation", github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-operation/*.gemspec"
gem "react-rails", ">= 2.4.0", "< 3.0"
# react-rails 2.7.1 calls ConnectionPool.new(options_hash), but
# connection_pool 3.0 made #initialize keyword-only -> ArgumentError at boot.
gem "connection_pool", "< 3.0"
# NOT opal-rails: 2.x hard-caps rails < 7.3, and 3.x replaced the Sprockets
# integration with an app/opal -> app/assets/builds build step, which is not
# what Hyperstack's `//= require hyperstack-loader` needs.
gem "opal-sprockets"
# Bundler kept an inherited prerelease (1.8.4.rc1) locked; hold the stable
# release that livetrack runs on Rails 8.
gem "opal", "1.8.3"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "rubocop", ">= 1.12", require: false

  gem "rspec-rails"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end


group :development do
  gem "foreman"
  gem "dotenv-rails"
end
