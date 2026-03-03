# RosaryAudio — plays pre-generated MP3s with word-by-word highlighting.
#
# Audio files:  /audio/{lang}/{key}.mp3
# Timing files: /audio/{lang}/{key}.json  → [{word, time}, ...]
#
# API:
#   RosaryAudio.play(key, lang) { on_end_callback }
#   RosaryAudio.stop

module RosaryAudio
  # JS-level state survives async callbacks; Opal module vars don't.
  `window._ra = window._ra || { audio: null, onEnd: null, cache: {} }`

  def self.clear_highlight
    `document.querySelectorAll('.prayer-word').forEach(function(s) {
      s.classList.remove('word-active');
    })`
  end

  def self.highlight_word(idx)
    `
      var el = null;
      document.querySelectorAll('.prayer-word').forEach(function(s) {
        if (parseInt(s.dataset.idx, 10) === #{idx}) { s.classList.add('word-active'); el = s; }
        else { s.classList.remove('word-active'); }
      });
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    `
  end

  def self.stop
    `
      var ra = window._ra;
      if (ra.audio) { ra.audio.pause(); ra.audio.src = ''; ra.audio = null; }
      ra.onEnd = null;
    `
    clear_highlight
  end

  def self.play(key, lang, &on_end)
    stop
    mp3_url  = "/audio/#{lang}/#{key}.mp3"
    json_url = "/audio/#{lang}/#{key}.json"
    `
      var ra = window._ra;
      ra.onEnd = #{on_end};

      var audioRef = new Audio(#{mp3_url});
      ra.audio = audioRef;

      function finish() {
        #{clear_highlight};
        if (audioRef !== ra.audio) return;
        ra.audio = null;
        var cb = ra.onEnd; ra.onEnd = null;
        if (cb && cb.$call) cb.$call();
      }

      audioRef.addEventListener('ended', finish);
      audioRef.addEventListener('error', finish);

      var jsonUrl = #{json_url};
      var timingsReady = ra.cache[jsonUrl]
        ? Promise.resolve(ra.cache[jsonUrl])
        : fetch(jsonUrl)
            .then(function(r) { return r.json(); })
            .then(function(d) { ra.cache[jsonUrl] = d; return d; })
            .catch(function() { return []; });

      timingsReady.then(function(timings) {
        if (audioRef !== ra.audio) return;
        if (timings.length > 0) {
          audioRef.addEventListener('timeupdate', function() {
            var t = audioRef.currentTime;
            for (var i = timings.length - 1; i >= 0; i--) {
              if (t >= timings[i].time) { #{highlight_word(`i`)}; return; }
            }
          });
        }
        audioRef.play().catch(function() {
          #{clear_highlight};
          if (audioRef === ra.audio) { ra.audio = null; ra.onEnd = null; }
        });
      });
    `
  end
end
