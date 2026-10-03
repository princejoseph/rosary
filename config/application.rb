require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Compile Opal (.rb / .rb.erb) through Sprockets, which is what resolves
# Hyperstack's `//= require hyperstack-loader` chain. Deliberately not
# opal-rails: 2.x pins rails < 7.3, and 3.x replaced the Sprockets integration.
require "opal/sprockets"

module Rosary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Opal's load paths (its stdlib plus the directories hyperstack-config
    # registers) have to be visible to Sprockets too.
    config.assets.paths += Opal.paths

    # opal-rails 3 is still a runtime dependency of rails-hyperstack, and its
    # railtie makes `opal:build` a prerequisite of `assets:precompile`, which
    # raises MissingEntrypointError unless app/opal exists. No entrypoints
    # makes it a no-op; app/opal is kept as an empty directory.
    config.opal.entrypoints = {}

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
