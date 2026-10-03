# Starting a New Hyperstack Hobby Project

This guide documents the exact steps to create a new Rails 8.0 + Hyperstack app from scratch. Use it as a template for future projects.

### Prerequisites

- Ruby 3.4 (`ruby -v`)
- Rails 8.0 (`gem install rails -v '~> 8.0.5'`). 8.0 is the version tested with Hyperstack; 8.1 isn't.
- Node.js 18+ (`node -v`) — needed by Opal/Sprockets asset compilation
- SQLite3 (`sqlite3 --version`)

### 1. Create the Rails app

```bash
rails _8.0.5.1_ new my_app --database=sqlite3 --skip-test --skip-bundle --skip-asset-pipeline
cd my_app
```

> `--skip-bundle` lets you edit the Gemfile before the first `bundle install`.
>
> Rails 8 dropped `--asset-pipeline=sprockets` (it only generates Propshaft), but
> Hyperstack needs Sprockets to compile Ruby through Opal. So skip the asset
> pipeline here and add Sprockets by hand in the next step.

### 2. Add Hyperstack to Gemfile

Open `Gemfile` and add the following. All Hyperstack gems must be pinned to the
**same branch** of the same fork to avoid picking up stale versions from rubygems.org:

```ruby
# Hyperstack — React-style components in Ruby
gem "sprockets-rails"

# Pin ALL hyperstack gems to the same fork/branch (Rails 8 / Ruby 3.4 fixes)
gem "rails-hyperstack", github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/rails-hyperstack/*.gemspec"
gem "hyper-component",  github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-component/*.gemspec"
gem "hyper-state",      github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-state/*.gemspec"
gem "hyperstack-config",github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyperstack-config/*.gemspec"
gem "hyper-store",      github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-store/*.gemspec"
gem "hyper-model",      github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-model/*.gemspec"
gem "hyper-router",     github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-router/*.gemspec"
gem "hyper-operation",  github: "princejoseph/hyperstack", branch: "rails-8-compatibility", glob: "ruby/hyper-operation/*.gemspec"
gem "react-rails", ">= 2.4.0", "< 3.0"
gem "opal-sprockets"   # NOT opal-rails, see below

# Rails 8.0's to_json passes `quirks_mode:`, which json 3.0 removed (Ruby 3.4 ships json 3.x)
gem "json", "< 3.0"
# react-rails 2.7 calls ConnectionPool.new(hash); connection_pool 3.0 is keyword-only
gem "connection_pool", "< 3.0"
```

> **Why opal-sprockets?** opal-rails 2.x requires `rails < 7.3`, and 3.x replaced
> its Sprockets integration with a separate build step, so Hyperstack's
> `//= require hyperstack-loader` can't be found. opal-sprockets is the same
> Sprockets integration without the Rails dependency.

> **Why pin all 8 gems?** `rails-hyperstack` depends on `hyper-model`, `hyper-router`, and
> `hyper-operation`. If you don't specify them explicitly, Bundler resolves them from
> rubygems.org where the published `1.0.alpha1.8` still has unguarded Rails 7.2-breaking
> calls (e.g. `InternalMetadata.do_not_synchronize`). Pinning all of them to the fork
> ensures every gem gets the Rails 8 / Ruby 3.4 fixes.

Also remove `importmap-rails`, `turbo-rails`, and `stimulus-rails` from the Gemfile —
they conflict with Hyperstack's Sprockets-based JS pipeline.

```bash
bundle install
```

Then wire Opal into Sprockets in `config/application.rb`:

```ruby
Bundler.require(*Rails.groups)

require "opal/sprockets"   # after Bundler.require

module MyApp
  class Application < Rails::Application
    config.load_defaults 8.0
    # ...
    config.assets.paths += Opal.paths

    # opal-rails 3 still comes in as a dependency of rails-hyperstack and hooks
    # `opal:build` into `assets:precompile`. With no entrypoints that is a no-op.
    config.opal.entrypoints = {}
  end
end
```

Also create an empty `app/opal/` directory (`mkdir app/opal && touch app/opal/.keep`).
Without it `assets:precompile` fails with `MissingEntrypointError`. It only runs
during a production build, so you won't see this until you deploy.

### 3. Run the Hyperstack install generator

```bash
bundle exec rails hyperstack:install
```

The generator will:
- Create `config/initializers/hyperstack.rb`
- Create `app/javascript/packs/` (webpack entry points — safe to ignore if not using webpack)
- Add `foreman` to `Gemfile` and create a `Procfile`
- Attempt `yarn add react@16` — **this step will fail** if you have no `package.json`

The yarn failure is expected and harmless for a Sprockets-only app. All the important
pieces (the initializer) are in place. Run `bundle install` once more to pick up the
`foreman` gem that was injected:

```bash
bundle install
```

### 4. Configure the Hyperstack initializer

Edit `config/initializers/hyperstack.rb`. Set `Hyperstack.transport`:

```ruby
Hyperstack.component_base_class = 'HyperComponent'

# :none         — pure frontend app, no real-time sync (simplest, no Redis needed)
# :action_cable — real-time HyperModel sync via ActionCable (add Redis for production)
Hyperstack.transport = :none
```

### 5. Create the JS asset entry point

Create `app/assets/javascripts/application.js`:

```javascript
//= require hyperstack-loader
```

Create `app/assets/config/manifest.js` (`--skip-asset-pipeline` doesn't generate it,
and without it boot fails with `Sprockets::Railtie::ManifestNeededError`):

```javascript
//= link_tree ../images
//= link_directory ../stylesheets .css
//= link_directory ../javascripts .js
```

### 6. Update the layout

Edit `app/views/layouts/application.html.erb`. Remove the default Turbo/importmap tags
and add the Sprockets JS include:

```erb
<%= stylesheet_link_tag "application" %>
<%= javascript_include_tag "application" %>
```

For Tailwind CSS via CDN (no build step — great for hobby apps):

```html
<script src="https://cdn.tailwindcss.com"></script>
```

### 7. Mount the Hyperstack engine

Edit `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Hyperstack::Engine => '/hyperstack'
  root "home#index"
end
```

### 8. Create the base component class

Create `app/hyperstack/components/hyper_component.rb`:

```ruby
class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
  param_accessor_style :accessors
end
```

### 9. Write your first component

Create `app/hyperstack/components/hello.rb`:

```ruby
class Hello < HyperComponent
  before_mount { @count = 0 }

  render do
    DIV(class: "p-4") do
      H1 { "Hello from Hyperstack!" }
      P  { "Clicked #{@count} times" }
      BUTTON(class: "px-4 py-2 bg-blue-500 text-white rounded") { "Click me" }
        .on(:click) { mutate @count += 1 }
    end
  end
end
```

In your view (`app/views/home/index.html.erb`):

```erb
<%= react_component '::Hello' %>
```

### 10. Run the app

The `hyperstack:install` generator creates a `Procfile` with two processes:

```
web:        bundle exec rails s -b 0.0.0.0
hot-loader: bundle exec hyperstack-hotloader -p 25222 -d app/hyperstack
```

Start both together with Foreman:

```bash
bundle exec foreman start -p 3000
```

The **hot-loader** watches `app/hyperstack/` and pushes component changes to the browser
instantly — no server restart, no page refresh needed while you develop.

If you only need a quick boot (no hot-reloading):

```bash
bundle exec rails server
```

Visit `http://localhost:3000`.

> **Note:** Opal compiles Ruby → JavaScript on the **first request** (~10 seconds).
> Subsequent requests are instant from the Sprockets cache.

---

## What the generator produces

```
config/
  initializers/
    hyperstack.rb          ← transport, component_base_class, prerendering

app/
  hyperstack/
    components/            ← Hyperstack components (compiled to JS client-side by Opal)
    models/                ← HyperModel shared models (run on both client and server)
  assets/
    javascripts/
      application.js       ← Sprockets manifest; must include hyperstack-loader
  javascript/
    packs/                 ← webpack entry points (only needed if using webpack)
```

---

## Transport modes

| Mode | Use case |
|------|----------|
| `:none` | Pure frontend app — no real-time sync, no ActionCable, no Redis. Simplest choice. |
| `:action_cable` | Real-time HyperModel sync across browsers via ActionCable. Add Redis for production. |

---

## Gotchas & Fixes

| Problem | Fix |
|---------|-----|
| `couldn't find file 'hyperstack-loader'` | Use `opal-sprockets` (not `opal-rails`), add `require "opal/sprockets"` and `config.assets.paths += Opal.paths` to `config/application.rb`. Note: `bin/rails app:update` overwrites `application.rb`, so re-check these lines after running it. |
| `unknown keyword: quirks_mode` | `gem "json", "< 3.0"` |
| `wrong number of arguments (given 1, expected 0)` at boot | `gem "connection_pool", "< 3.0"` |
| Page shows the layout but no components (with HyperModel) | `ApplicationRecord.primary_abstract_class` isn't implemented on the client. Use `self.abstract_class = true` when `RUBY_ENGINE == "opal"`. |
| `undefined method 'do_not_synchronize'` on boot | Pin ALL 8 Hyperstack gems to the fork branch — `rails-hyperstack` pulls in `hyper-model` etc. as transitive dependencies, which default to the unfixed rubygems.org version |
| `yarn failed to install react` during `hyperstack:install` | Expected and harmless for Sprockets-only apps. The initializer was created successfully; just re-run `bundle install`. |
| `importmap` / `turbo` JS conflicts | Remove `importmap-rails`, `turbo-rails`, `stimulus-rails` from Gemfile |
| First page load takes ~10 seconds | Opal compiling Ruby → JS for the first time. Subsequent loads are instant (Sprockets cache in `tmp/cache/`). |
| Component changes not showing | In development the hotloader auto-reloads — no server restart needed. If it stops working, run `bundle exec rails server` fresh. |
| `HyperComponent` not found | Make sure `app/hyperstack/components/hyper_component.rb` exists with the class definition. |
