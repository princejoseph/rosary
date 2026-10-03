# Japamala — Daily Rosary Guide

**Live at [japamala.fly.dev](https://japamala.fly.dev)**

A bilingual (Malayalam / English) rosary guide that walks you through the rosary
one bead at a time, or prays the whole rosary aloud for you in **auto mode**.
It is designed for phones and can be installed to the home
screen like a native app.

## Features

- **Today's mysteries picked for you**: Joyful (Mon, Sat), Sorrowful (Tue, Fri),
  Glorious (Wed, Sun) and Luminous (Thu). You can pick a different set from the menu.
- **Bead-by-bead guidance**: the full text of every prayer (Apostles' Creed, Our
  Father, Hail Mary, Glory Be, Fatima Prayer, Hail Holy Queen), with a
  description of each mystery as it is announced.
- **Progress navigation**: a bead strip for the current decade plus section dots.
  Tap any bead or section to jump to it, with a confirmation first.
- **Malayalam ↔ English toggle**: Malayalam is the default.
- **Audio prayers**: each prayer has pre-recorded audio in both languages
  (Google Cloud TTS), with the words highlighted as they are spoken.
- **Personalization**: Classic or Minimal layout and five accent colours
  (amber, rose, blue, teal, purple).
- **Dark mode**: a pure-black AMOLED theme. It is a hidden feature: tap the
  step counter in the header three times quickly to switch it on or off.
- **Resumes where you left off**: your position and settings are saved in the
  browser (localStorage). There are no accounts and nothing is sent to a server.
- **Installable PWA**: an install button on Android Chrome, and an "Add to Home
  Screen" hint on iOS Safari.

### 🔁 Auto mode: pray the full rosary hands-free

> [!TIP]
> Tap the **repeat button (🔁)** in the bottom bar and Japamala prays the whole
> rosary for you, from start to finish:
>
> - Each prayer is read aloud in Malayalam or English, with the words highlighted
>   as they are spoken.
> - It moves to the next bead by itself and announces each mystery as it comes.
> - It goes through all five decades to the closing prayers, then stops.
>
> You can start it from any bead, so you can pick up partway through. Tap 🔁 again, pause,
> next or back at any time to stop it and go back to praying at your own pace.
> It works well for praying along while walking or driving, praying as a family,
> or for anyone who would rather listen than read.

## Tech stack

- Rails 7.2 + [Hyperstack](https://github.com/hyperstack-org/hyperstack): the
  whole UI is written in Ruby components and compiled to JavaScript by Opal
- Sprockets only (no webpack or importmap). Pure frontend, with `Hyperstack.transport = :none`
- Hosted on Fly.io (app `japamala`). GitHub Actions runs lint and specs, then
  deploys on push

Main code:

| Path | What it is |
|------|------------|
| `app/hyperstack/components/rosary_app.rb` | The main UI component |
| `app/hyperstack/components/rosary_data.rb` | Prayer texts, mysteries, day-of-week schedule |
| `app/hyperstack/components/rosary_audio.rb` | Audio playback and word highlighting |
| `public/audio/{en,ml}/` | Pre-generated prayer audio |

## Running locally

```bash
git clone git@github.com:princejoseph/rosary.git
cd rosary
bundle install
bin/rails db:create
bundle exec foreman start -p 3000
```

Visit `http://localhost:3000`. The first request takes about 10 seconds while Opal
compiles; later requests load from the cache.

> Use `bin/rails server` instead if you don't need the hotloader.

Run the specs with `bundle exec rspec`.

## Building your own Hyperstack app

The step-by-step guide to setting up a Rails 7.2 + Hyperstack app from scratch
(Gemfile pins, generator quirks, transport modes, gotchas) is in
**[HYPERSTACK.md](HYPERSTACK.md)**.
