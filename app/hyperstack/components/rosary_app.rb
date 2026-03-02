class RosaryApp < HyperComponent
  include RosaryData

  COLORS = [
    { key: :amber,  hex: "#e8a020" },
    { key: :rose,   hex: "#e05078" },
    { key: :blue,   hex: "#3b82f6" },
    { key: :teal,   hex: "#0ea5a0" },
    { key: :purple, hex: "#8b5cf6" }
  ]

  before_mount do
    @lang        = load_saved_lang || :ml
    @theme       = load_saved_theme || :classic
    @color       = load_saved_color || :blue
    @menu_open      = false
    @confirm_set    = nil
    @confirm_jump   = nil
    @speaking       = false

    today_set  = MYSTERY_FOR_DAY[Time.now.wday]
    today_date = Time.now.strftime("%Y-%m-%d")

    if load_saved_date == today_date
      @set  = load_saved_set || today_set
      @step = load_saved_step || 0
    else
      clear_saved_progress
      @set  = today_set
      @step = 0
    end
    @sequence = build_sequence(@set)
  end

  render do
    DIV(class: "app#{@theme == :classic ? ' classic' : ''} color-#{@color}") do
      render_mystery_menu
      render_jump_confirm
      render_header
      if @step >= @sequence.length
        render_complete
      else
        render_progress_bar
        bead = @sequence[@step]
        render_bead_header(bead)
        DIV(class: "content#{bead[:prayer] == :mystery_announce ? ' content-announce' : ''}") do
          if bead[:prayer] == :mystery_announce
            render_mystery_announce(bead)
          else
            render_prayer_bead(bead)
          end
        end
        render_nav
      end
    end
  end

  private

  # ── Mystery picker menu ──────────────────────────────────────────────────────

  def render_mystery_menu
    return unless @menu_open

    today_set = MYSTERY_FOR_DAY[Time.now.wday]

    DIV(class: "menu-overlay").on(:click) { mutate { @menu_open = false; @confirm_set = nil } }
    DIV(class: "mystery-menu") do
      DIV(class: "menu-title") { @lang == :en ? "Choose Mysteries" : "രഹസ്യങ്ങൾ തിരഞ്ഞെടുക്കുക" }
      %i[joyful sorrowful glorious luminous].each do |key|
        css = [ "menu-item" ]
        css << "menu-item-today"    if key == today_set
        css << "menu-item-selected" if key == @set
        css << "menu-item-confirm"  if key == @confirm_set
        DIV(class: css.join(" ")) do
          I(class: "bi #{MYSTERIES[key][:icon]} menu-item-icon")
          DIV(class: "menu-item-text") do
            DIV(class: "menu-item-name") { MYSTERIES[key][:name][@lang] }
            DIV(class: "menu-item-days") { MYSTERIES[key][:days][@lang] }
          end
          I(class: "bi bi-check2 menu-check") if key == @set
        end.on(:click) do
          if key == @set
            mutate { @menu_open = false; @confirm_set = nil }
          elsif key == @confirm_set
            select_set(key)
          else
            mutate @confirm_set = key
          end
        end
      end

      if @confirm_set
        DIV(class: "menu-warning") do
          SPAN(class: "menu-warning-text") do
            @lang == :en ? "This will reset your current progress." : "നിലവിലെ പുരോഗതി നഷ്ടപ്പെടും."
          end
          DIV(class: "menu-warning-actions") do
            BUTTON(class: "menu-btn menu-btn-cancel") { @lang == :en ? "Cancel" : "റദ്ദാക്കുക" }
              .on(:click) { mutate @confirm_set = nil }
            BUTTON(class: "menu-btn menu-btn-switch") { @lang == :en ? "Switch" : "മാറ്റുക" }
              .on(:click) { select_set(@confirm_set) }
          end
        end
      end
    end
  end

  def select_set(key)
    mutate do
      @set         = key
      @step        = 0
      @sequence    = build_sequence(@set)
      @menu_open   = false
      @confirm_set = nil
      save_progress
    end
  end

  # ── Jump confirm modal ───────────────────────────────────────────────────────

  def render_jump_confirm
    return unless @confirm_jump

    DIV(class: "menu-overlay").on(:click) { mutate @confirm_jump = nil }
    DIV(class: "jump-confirm") do
      P(class: "jump-confirm-title") do
        @lang == :en ? "Jump to #{step_label(@confirm_jump)}?" : "#{step_label(@confirm_jump)}-ലേക്ക് പോകണോ?"
      end
      P(class: "jump-confirm-body") do
        @lang == :en ? "Your current progress will be reset." : "നിലവിലെ പുരോഗതി നഷ്ടപ്പെടും."
      end
      DIV(class: "menu-warning-actions") do
        BUTTON(class: "menu-btn menu-btn-cancel") { @lang == :en ? "Cancel" : "റദ്ദാക്കുക" }
          .on(:click) { mutate @confirm_jump = nil }
        BUTTON(class: "menu-btn menu-btn-switch") { @lang == :en ? "Jump" : "പോകുക" }
          .on(:click) { jump_to_step }
      end
    end
  end

  def step_label(step)
    bead = @sequence[step]
    if bead[:prayer] == :mystery_announce
      @lang == :en ? "#{bead[:ordinal][:en]} Mystery" : "#{bead[:ordinal][:ml]} രഹസ്യം"
    elsif bead[:prayer] == :hail_holy_queen
      @lang == :en ? "Closing Prayer" : "അന്ത്യ പ്രാർത്ഥന"
    else
      name = PRAYERS[bead[:prayer]][:name][@lang]
      bead[:count] ? "#{name} #{bead[:count]}/#{bead[:total]}" : name
    end
  end

  # ── Header ──────────────────────────────────────────────────────────────────

  def render_header
    DIV(class: "app-header") do
      DIV(class: "mystery-selector") do
        DIV(class: "mystery-day")  { MYSTERIES[@set][:days][@lang] }
        DIV(class: "mystery-name") do
          I(class: "bi #{MYSTERIES[@set][:icon]} mystery-type-icon")
          SPAN { MYSTERIES[@set][:short][@lang] }
          I(class: "bi bi-chevron-down mystery-selector-icon")
        end
        SPAN(class: "step-counter") { "#{[ @step, @sequence.length ].min} / #{@sequence.length}" }
      end.on(:click) { mutate @menu_open = true }
      DIV(class: "header-right") do
        DIV(class: "header-btns") do
          BUTTON(class: "lang-btn") do
            I(class: "bi bi-translate")
            SPAN { @lang == :en ? " മല" : " EN" }
          end.on(:click) { mutate { @lang = (@lang == :en ? :ml : :en); save_lang } }
          BUTTON(class: "lang-btn") do
            if @theme == :classic
              I(class: "bi bi-feather")
              SPAN { " Minimal" }
            else
              I(class: "bi bi-book")
              SPAN { " Classic" }
            end
          end.on(:click) do
            mutate { @theme = (@theme == :classic ? :minimal : :classic); save_theme }
          end
        end
        DIV(class: "color-swatches") do
          COLORS.each do |c|
            css = "color-dot#{@color == c[:key] ? ' color-dot-active' : ''}"
            DIV(class: css, style: { background: c[:hex], color: c[:hex] })
              .on(:click) { mutate { @color = c[:key]; save_color } }
          end
        end
      end
    end
  end

  # ── Progress bar ────────────────────────────────────────────────────────────

  def render_progress_bar
    pct = @sequence.length > 0 ? (@step.to_f / @sequence.length * 100).round : 0
    DIV(class: "progress-wrap") do
      DIV(class: "progress-fill", style: { width: "#{pct}%" })
    end
  end

  # ── Fixed bead header ────────────────────────────────────────────────────────

  def render_bead_header(bead)
    section = if bead[:prayer] == :hail_holy_queen
      6
    elsif bead[:decade]
      bead[:decade]
    else
      0
    end

    DIV(class: "bead-header") do
      render_section_nav(section)

      if bead[:decade]
        render_decade_bead_track(bead)
      elsif bead[:prayer] != :hail_holy_queen
        render_opening_bead_track(bead)
      end
    end
  end

  # ── Section nav (O · 1 · 2 · 3 · 4 · 5 · C) ─────────────────────────────────

  def render_section_nav(current_section)
    DIV(class: "decade-dots") do
      render_section_dot(0, current_section, "✦", target_step: 0, symbol: true)
      5.times do |i|
        render_section_dot(i + 1, current_section, (i + 1).to_s, target_step: 6 + i * 14)
      end
      render_section_dot(6, current_section, "✝", target_step: @sequence.length - 1, symbol: true)
    end
  end

  def render_section_dot(idx, current_section, label, target_step:, symbol: false)
    css = if idx < current_section
      "decade-dot done"
    elsif idx == current_section
      "decade-dot active"
    else
      "decade-dot"
    end
    DIV(class: css) do
      symbol ? SPAN(style: { fontSize: "14px" }) { label } : SPAN { label }
    end.on(:click) { mutate @confirm_jump = target_step unless idx == current_section }
  end

  # ── Bead track: opening prayers (6 beads) ───────────────────────────────────

  def render_opening_bead_track(bead)
    pos = case bead[:prayer]
    when :apostles_creed then 0
    when :our_father     then 1
    when :hail_mary      then 1 + bead[:count]
    when :glory_be       then 5
    else 0
    end

    DIV(class: "bead-track-wrapper") do
      DIV(class: "bead-track-line")
      DIV(class: "bead-track") do
        [
          { idx: 0, special: true  },
          { idx: 1, special: true  },
          { idx: 2, special: false },
          { idx: 3, special: false },
          { idx: 4, special: false },
          { idx: 5, special: true  }
        ].each do |b|
          state = b[:idx] < pos ? " bead-done" : (b[:idx] == pos ? " bead-active" : "")
          DIV(class: "bead#{b[:special] ? ' bead-special' : ''}#{state}")
            .on(:click) { mutate @confirm_jump = b[:idx] unless b[:idx] == @step }
        end
      end
    end
  end

  # ── Bead track: one decade (13 beads) ───────────────────────────────────────

  def render_decade_bead_track(bead)
    d    = bead[:decade]
    base = 6 + (d - 1) * 14

    pos = case bead[:prayer]
    when :mystery_announce then -1
    when :our_father       then 0
    when :hail_mary        then bead[:count]
    when :glory_be         then 11
    when :fatima           then 12
    else -1
    end

    DIV(class: "bead-track-wrapper") do
      DIV(class: "bead-track-line")
      DIV(class: "bead-track") do
        of_state = pos > 0 ? " bead-done" : (pos == 0 ? " bead-active" : "")
        DIV(class: "bead bead-special#{of_state}")
          .on(:click) { mutate @confirm_jump = base + 1 unless base + 1 == @step }

        (1..10).each do |i|
          hm_state = pos > i ? " bead-done" : (pos == i ? " bead-active" : "")
          DIV(class: "bead#{hm_state}")
            .on(:click) { mutate @confirm_jump = base + 1 + i unless base + 1 + i == @step }
        end

        gb_state = pos > 11 ? " bead-done" : (pos == 11 ? " bead-active" : "")
        DIV(class: "bead bead-special#{gb_state}")
          .on(:click) { mutate @confirm_jump = base + 12 unless base + 12 == @step }

        f_state = pos > 12 ? " bead-done" : (pos == 12 ? " bead-active" : "")
        DIV(class: "bead bead-special#{f_state}")
          .on(:click) { mutate @confirm_jump = base + 13 unless base + 13 == @step }
      end
    end
  end

  # ── Shared nav buttons ───────────────────────────────────────────────────────

  def render_nav
    is_last = @step >= @sequence.length - 1
    DIV(class: "nav-row") do
      if @theme == :minimal
        BUTTON(class: "btn-nav", disabled: @step == 0) do
          I(class: "bi bi-arrow-left")
        end.on(:click) { go_back }
        BUTTON(class: "btn-nav btn-nav-speak") do
          I(class: @speaking ? "bi bi-pause-fill" : "bi bi-play-fill")
        end.on(:click) { @speaking ? stop_speaking : speak_current }
        BUTTON(class: "btn-nav btn-nav-next") do
          I(class: is_last ? "bi bi-check-lg" : "bi bi-arrow-right")
        end.on(:click) { advance }
      else
        BUTTON(class: "btn-nav", disabled: @step == 0) do
          I(class: "bi bi-arrow-left-circle-fill", style: { fontSize: "3rem", color: "#ddd" })
        end.on(:click) { go_back }
        BUTTON(class: "btn-nav btn-nav-speak") do
          icon = @speaking ? "bi-pause-circle-fill" : "bi-play-circle-fill"
          I(class: "bi #{icon}", style: { fontSize: "3rem", color: "var(--accent)", opacity: "0.7" })
        end.on(:click) { @speaking ? stop_speaking : speak_current }
        BUTTON(class: "btn-nav") do
          icon = is_last ? "bi-check-circle-fill" : "bi-arrow-right-circle-fill"
          I(class: "bi #{icon}", style: { fontSize: "3rem", color: "var(--accent)" })
        end.on(:click) { advance }
      end
    end
  end

  # ── Mystery announce ─────────────────────────────────────────────────────────

  def render_mystery_announce(bead)
    DIV(class: "mystery-ordinal") do
      "#{bead[:ordinal][@lang]} #{@lang == :en ? 'Mystery' : 'രഹസ്യം'}"
    end
    H1(class: "mystery-heading") { bead[:mystery][@lang] }
    P(class: "mystery-desc") { bead[:mystery][:desc][@lang] }
  end

  # ── Prayer bead ──────────────────────────────────────────────────────────────

  def render_prayer_bead(bead)
    prayer_key = bead[:prayer]

    if bead[:prayer] == :hail_holy_queen
      DIV(class: "closing-label") { @lang == :en ? "Closing Prayer" : "അവസാന പ്രാർത്ഥന" }
    end

    P(class: "prayer-context") { bead[:mystery][@lang] } if bead[:mystery]

    H1(class: "prayer-heading") { PRAYERS[prayer_key][:name][@lang] }

    if bead[:count] && bead[:total]
      P(class: "prayer-count") { "#{bead[:count]} / #{bead[:total]}" }
    end

    DIV(class: "prayer-body") { PRAYERS[prayer_key][:text][@lang] }
  end

  # ── Completion screen ────────────────────────────────────────────────────────

  def render_complete
    DIV(class: "completion") do
      if @theme == :minimal
        P(class: "completion-symbol") { "✝" }
      else
        I(class: "bi bi-flower3 completion-icon")
      end
      H2(class: "completion-heading") do
        @lang == :en ? "Rosary Complete" : "ജപമാല പൂർത്തിയായി"
      end
      P(class: "completion-sub") do
        @lang == :en ? "Thanks be to God." : "ദൈവത്തിന് നന്ദി."
      end
      BUTTON(class: "btn-restart") do
        I(class: "bi bi-arrow-clockwise")
        SPAN { @lang == :en ? "Pray Again" : "വീണ്ടും ജപിക്കുക" }
      end.on(:click) { restart }
    end
  end

  # ── Sequence builder ─────────────────────────────────────────────────────────

  def build_sequence(set)
    seq = []

    seq << { prayer: :apostles_creed }
    seq << { prayer: :our_father }
    3.times { |i| seq << { prayer: :hail_mary, count: i + 1, total: 3 } }
    seq << { prayer: :glory_be }

    mysteries = MYSTERIES[set][:list]
    ordinals_en = %w[First Second Third Fourth Fifth]
    ordinals_ml = %w[ഒന്നാം രണ്ടാം മൂന്നാം നാലാം അഞ്ചാം]
    5.times do |d|
      mystery = mysteries[d]
      seq << { prayer: :mystery_announce, decade: d + 1, mystery: mystery,
               ordinal: { en: ordinals_en[d], ml: ordinals_ml[d] } }
      seq << { prayer: :our_father, decade: d + 1, mystery: mystery }
      10.times { |i| seq << { prayer: :hail_mary, count: i + 1, total: 10, decade: d + 1, mystery: mystery } }
      seq << { prayer: :glory_be,  decade: d + 1, mystery: mystery }
      seq << { prayer: :fatima,    decade: d + 1, mystery: mystery }
    end

    seq << { prayer: :hail_holy_queen }

    seq
  end

  # ── Navigation + localStorage ────────────────────────────────────────────────

  def go_back
    return if @step <= 0
    stop_speaking
    mutate do
      @step           -= 1
      @confirm_jump  = nil
      save_progress
    end
  end

  def advance
    stop_speaking
    mutate do
      @step           += 1
      @confirm_jump  = nil
      save_progress
    end
  end

  def restart
    stop_speaking
    mutate do
      @step = 0
      clear_saved_progress
    end
  end

  def jump_to_step
    stop_speaking
    mutate do
      @step         = @confirm_jump
      @confirm_jump = nil
      save_progress
    end
  end

  def speak_current
    bead = @sequence[@step]
    text = if bead[:prayer] == :mystery_announce
      "#{bead[:ordinal][@lang]} #{@lang == :en ? 'Mystery' : 'രഹസ്യം'}. #{bead[:mystery][@lang]}. #{bead[:mystery][:desc][@lang]}"
    else
      PRAYERS[bead[:prayer]][:text][@lang]
    end
    lang_code = @lang == :en ? "en-US" : "ml-IN"
    `
      window.speechSynthesis.cancel();
      var utt = new SpeechSynthesisUtterance(#{text});
      utt.lang = #{lang_code};
      utt.onend = function() { #{mutate @speaking = false} };
      utt.onerror = function() { #{mutate @speaking = false} };
      window.speechSynthesis.speak(utt);
    `
    mutate @speaking = true
  end

  def stop_speaking
    `window.speechSynthesis.cancel()`
    mutate @speaking = false
  end

  def save_progress
    set_str  = @set.to_s
    step_str = @step.to_s
    date_str = Time.now.strftime("%Y-%m-%d")
    `localStorage.setItem('rosary_step', #{step_str})`
    `localStorage.setItem('rosary_set',  #{set_str})`
    `localStorage.setItem('rosary_date', #{date_str})`
  end

  def clear_saved_progress
    `localStorage.removeItem('rosary_step')`
    `localStorage.removeItem('rosary_set')`
    `localStorage.removeItem('rosary_date')`
  end

  def load_saved_step
    val = `localStorage.getItem('rosary_step')`
    `#{val} === null` ? nil : val.to_i
  end

  def load_saved_set
    val = `localStorage.getItem('rosary_set')`
    `#{val} === null` ? nil : val.to_sym
  end

  def load_saved_date
    val = `localStorage.getItem('rosary_date')`
    `#{val} === null` ? nil : val
  end

  def load_saved_theme
    val = `localStorage.getItem('rosary_theme')`
    `#{val} === null` ? nil : val.to_sym
  end

  def save_theme
    `localStorage.setItem('rosary_theme', #{@theme})`
  end

  def load_saved_lang
    val = `localStorage.getItem('rosary_lang')`
    `#{val} === null` ? nil : val.to_sym
  end

  def save_lang
    `localStorage.setItem('rosary_lang', #{@lang})`
  end

  def load_saved_color
    val = `localStorage.getItem('rosary_color')`
    `#{val} === null` ? nil : val.to_sym
  end

  def save_color
    `localStorage.setItem('rosary_color', #{@color})`
  end
end
