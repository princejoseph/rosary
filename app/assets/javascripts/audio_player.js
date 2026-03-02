// RosaryAudio — plays pre-generated MP3s with word-by-word highlighting.
//
// Audio files:  /audio/{lang}/{key}.mp3
// Timing files: /audio/{lang}/{key}.json  → [{word, time}, ...]
//
// API:
//   RosaryAudio.play(key, lang, onEnd)  — start playback
//   RosaryAudio.stop()                  — stop and clear highlight

var RosaryAudio = (function () {
  var _audio = null;
  var _onEnd = null;
  var _timingsCache = {};

  function clearHighlight() {
    document.querySelectorAll('.prayer-word').forEach(function (s) {
      s.classList.remove('word-active');
    });
  }

  function highlightWord(idx) {
    document.querySelectorAll('.prayer-word').forEach(function (s) {
      if (parseInt(s.dataset.idx, 10) === idx) {
        s.classList.add('word-active');
      } else {
        s.classList.remove('word-active');
      }
    });
  }

  function stop() {
    if (_audio) {
      _audio.pause();
      _audio.src = '';
      _audio = null;
    }
    clearHighlight();
    _onEnd = null;
  }

  function play(key, lang, onEnd) {
    stop();
    _onEnd = onEnd;

    var mp3Url  = '/audio/' + lang + '/' + key + '.mp3';
    var jsonUrl = '/audio/' + lang + '/' + key + '.json';

    // Create Audio immediately so the browser starts buffering the MP3.
    var audioRef = new Audio(mp3Url);
    _audio = audioRef;

    // Wire up end/error handlers before we start playing.
    audioRef.addEventListener('ended', function () {
      clearHighlight();
      if (audioRef !== _audio) return;
      _audio = null;
      var cb = _onEnd;
      _onEnd = null;
      if (cb) cb();
    });

    audioRef.addEventListener('error', function () {
      clearHighlight();
      if (audioRef !== _audio) return;
      _audio = null;
      var cb = _onEnd;
      _onEnd = null;
      if (cb) cb();
    });

    // Fetch timing JSON (cached after first load), then start playback.
    var timingsReady = _timingsCache[jsonUrl]
      ? Promise.resolve(_timingsCache[jsonUrl])
      : fetch(jsonUrl)
          .then(function (r) { return r.json(); })
          .then(function (d) { _timingsCache[jsonUrl] = d; return d; })
          .catch(function () { return []; });

    timingsReady.then(function (timings) {
      if (audioRef !== _audio) return; // superseded by stop() or another play()

      if (timings.length > 0) {
        audioRef.addEventListener('timeupdate', function () {
          var t = audioRef.currentTime;
          // Walk backwards to find the last timing entry whose time <= current time.
          for (var i = timings.length - 1; i >= 0; i--) {
            if (t >= timings[i].time) {
              highlightWord(i);
              return;
            }
          }
        });
      }

      audioRef.play().catch(function () {
        // Autoplay blocked (unlikely since we're in a button handler).
        clearHighlight();
        if (audioRef === _audio) { _audio = null; _onEnd = null; }
      });
    });
  }

  return { play: play, stop: stop };
})();
