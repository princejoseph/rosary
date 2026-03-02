# Usage:
#   GOOGLE_TTS_API_KEY=your_key bundle exec rake rosary:generate_audio
#
# Prerequisites:
#   1. Enable the Cloud Text-to-Speech API in your Google Cloud project
#   2. Create an API key at console.cloud.google.com/apis/credentials
#
# Output: public/audio/{en,ml}/{key}.mp3 and .json (word timings)
# These files are committed to git and served as static assets on Fly.io.

require "net/http"
require "json"
require "base64"
require "fileutils"

namespace :rosary do
  desc "Generate audio files for all prayers and mysteries via Google Cloud TTS"
  task generate_audio: :environment do
    include RosaryData

    api_key = ENV.fetch("GOOGLE_TTS_API_KEY") do
      abort "ERROR: Set GOOGLE_TTS_API_KEY environment variable"
    end

    api_uri = URI("https://texttospeech.googleapis.com/v1beta1/text:synthesize?key=#{api_key}")

    voices = {
      en: { languageCode: "en-US", name: "en-US-Neural2-F" },
      ml: { languageCode: "ml-IN", name: "ml-IN-Wavenet-A" }
    }

    ordinals_en = %w[First Second Third Fourth Fifth]
    ordinals_ml = %w[ഒന്നാം രണ്ടാം മൂന്നാം നാലാം അഞ്ചാം]

    # ── Helpers ────────────────────────────────────────────────────────────────

    def xml_escape(str)
      str.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
         .gsub("'", "&apos;").gsub('"', "&quot;")
    end

    def build_ssml(text)
      parts = text.split.each_with_index.map { |word, i| "<mark name='#{i}'/>#{xml_escape(word)}" }
      "<speak>#{parts.join(' ')}</speak>"
    end

    synthesize = lambda do |text, lang, api_uri, voices|
      body = {
        input: { ssml: build_ssml(text) },
        voice: voices[lang],
        audioConfig: { audioEncoding: "MP3" },
        enableTimePointing: [ "SSML_MARK" ]
      }.to_json

      http = Net::HTTP.new(api_uri.host, api_uri.port)
      http.use_ssl = true
      req = Net::HTTP::Post.new(api_uri)
      req["Content-Type"] = "application/json"
      req.body = body

      resp = http.request(req)
      abort "TTS API error #{resp.code}: #{resp.body}" unless resp.code == "200"

      data = JSON.parse(resp.body)
      words = text.split
      timings = (data["timepoints"] || []).map do |tp|
        { word: words[tp["markName"].to_i], time: tp["timeSeconds"].round(3) }
      end

      [ Base64.decode64(data["audioContent"]), timings ]
    end

    save_files = lambda do |key, lang, mp3_bytes, timings|
      dir = Rails.root.join("public", "audio", lang.to_s)
      FileUtils.mkdir_p(dir)
      File.binwrite(dir.join("#{key}.mp3"), mp3_bytes)
      File.write(dir.join("#{key}.json"), JSON.generate(timings))
      puts "  ✓ #{lang}/#{key}"
    end

    generate = lambda do |key, texts|
      %i[en ml].each do |lang|
        text = texts[lang]
        next if text.nil? || text.strip.empty?

        mp3, timings = synthesize.call(text, lang, api_uri, voices)
        save_files.call(key, lang, mp3, timings)
        sleep 0.25 # stay within API rate limits
      end
    end

    # ── Prayers ────────────────────────────────────────────────────────────────

    puts "=== Prayers ==="
    PRAYERS.each do |key, prayer|
      generate.call(key.to_s, prayer[:text])
    end

    # ── Mystery announcements ──────────────────────────────────────────────────

    puts "\n=== Mystery announcements ==="
    MYSTERIES.each do |set_key, set|
      set[:list].each_with_index do |mystery, i|
        audio_key = "#{set_key}_mystery_#{i + 1}"
        texts = {
          en: "#{ordinals_en[i]} Mystery. #{mystery[:en]}. #{mystery[:desc][:en]}",
          ml: "#{ordinals_ml[i]} രഹസ്യം. #{mystery[:ml]}. #{mystery[:desc][:ml]}"
        }
        generate.call(audio_key, texts)
      end
    end

    puts "\nDone! #{Dir[Rails.root.join('public/audio/**/*.mp3')].count} MP3 files in public/audio/"
  end
end
