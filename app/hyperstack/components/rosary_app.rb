class RosaryApp < HyperComponent
  include RosaryData

  before_mount do
    @lang  = :en
    @theme = load_saved_theme || :minimal
    @set   = MYSTERY_FOR_DAY[Time.now.wday]
    saved_step = load_saved_step
    saved_set  = load_saved_set
    if saved_set && saved_set != @set
      clear_saved_progress
      @step = 0
    else
      @step = saved_step || 0
    end
    @sequence = build_sequence(@set)
  end

  render do
    DIV(class: "app#{@theme == :classic ? ' classic' : ''}") do
      render_header
      if @step >= @sequence.length
        render_complete
      else
        render_progress_bar
        bead = @sequence[@step]
        DIV(class: "content#{bead[:prayer] == :mystery_announce ? ' content-announce' : ''}") do
          if bead[:prayer] == :mystery_announce
            render_mystery_announce(bead)
          else
            render_prayer_bead(bead)
          end
        end
      end
    end
  end

  private

  # ── Header ──────────────────────────────────────────────────────────────────

  def render_header
    DIV(class: "app-header") do
      DIV do
        DIV(class: "mystery-day")  { MYSTERIES[@set][:days][@lang] }
        DIV(class: "mystery-name") { MYSTERIES[@set][:name][@lang] }
      end
      DIV(class: "header-right") do
        SPAN(class: "step-counter") { "#{[ @step, @sequence.length ].min} / #{@sequence.length}" }
        BUTTON(class: "lang-btn") { @lang == :en ? "ML" : "EN" }
          .on(:click) { mutate @lang = (@lang == :en ? :ml : :en) }
        BUTTON(class: "lang-btn") do
          @theme == :classic ? "Minimal" : "Classic"
        end.on(:click) do
          mutate { @theme = (@theme == :classic ? :minimal : :classic); save_theme }
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

  # ── Decade dots ──────────────────────────────────────────────────────────────

  def render_decade_dots(current_decade)
    DIV(class: "decade-dots") do
      5.times do |i|
        d = i + 1
        css = d < current_decade ? "decade-dot done" : (d == current_decade ? "decade-dot active" : "decade-dot")
        DIV(class: css) do
          d < current_decade ? I(class: "bi bi-check-lg") : SPAN { d.to_s }
        end
      end
    end
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
        end
      end
    end
  end

  # ── Bead track: one decade (13 beads) ───────────────────────────────────────

  def render_decade_bead_track(bead)
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

        (1..10).each do |i|
          hm_state = pos > i ? " bead-done" : (pos == i ? " bead-active" : "")
          DIV(class: "bead#{hm_state}")
        end

        gb_state = pos > 11 ? " bead-done" : (pos == 11 ? " bead-active" : "")
        DIV(class: "bead bead-special#{gb_state}")

        f_state = pos > 12 ? " bead-done" : (pos == 12 ? " bead-active" : "")
        DIV(class: "bead bead-special#{f_state}")
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
        BUTTON(class: "btn-nav btn-nav-next") do
          I(class: is_last ? "bi bi-check-lg" : "bi bi-arrow-right")
        end.on(:click) { advance }
      else
        BUTTON(class: "btn-nav", disabled: @step == 0) do
          I(class: "bi bi-arrow-left-circle-fill", style: { fontSize: "3rem", color: "#ddd" })
        end.on(:click) { go_back }
        BUTTON(class: "btn-nav") do
          icon = is_last ? "bi-check-circle-fill" : "bi-arrow-right-circle-fill"
          I(class: "bi #{icon}", style: { fontSize: "3rem", color: "#e8a020" })
        end.on(:click) { advance }
      end
    end
  end

  # ── Mystery announce ─────────────────────────────────────────────────────────

  def render_mystery_announce(bead)
    render_decade_dots(bead[:decade])
    render_decade_bead_track(bead)

    DIV(class: "mystery-ordinal") do
      "#{bead[:ordinal][@lang]} #{@lang == :en ? 'Mystery' : 'രഹസ്യം'}"
    end
    H1(class: "mystery-heading") { bead[:mystery][@lang] }
    P(class: "mystery-desc") { bead[:mystery][:desc][@lang] }

    render_nav
  end

  # ── Prayer bead ──────────────────────────────────────────────────────────────

  def render_prayer_bead(bead)
    prayer_key = bead[:prayer]

    if bead[:prayer] == :hail_holy_queen
      DIV(class: "closing-label") { @lang == :en ? "Closing Prayer" : "അവസാന പ്രാർത്ഥന" }
    elsif bead[:decade]
      render_decade_dots(bead[:decade])
      render_decade_bead_track(bead)
    else
      render_opening_bead_track(bead)
    end

    P(class: "prayer-context") { bead[:mystery][@lang] } if bead[:mystery]

    H1(class: "prayer-heading") { PRAYERS[prayer_key][:name][@lang] }

    if bead[:count] && bead[:total]
      P(class: "prayer-count") { "#{bead[:count]} / #{bead[:total]}" }
    end

    DIV(class: "prayer-body") { PRAYERS[prayer_key][:text][@lang] }

    render_nav
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
    mutate do
      @step -= 1
      save_progress
    end
  end

  def advance
    mutate do
      @step += 1
      save_progress
    end
  end

  def restart
    mutate do
      @step = 0
      clear_saved_progress
    end
  end

  def save_progress
    set_str = @set.to_s
    step_str = @step.to_s
    `localStorage.setItem('rosary_step', #{step_str})`
    `localStorage.setItem('rosary_set',  #{set_str})`
  end

  def clear_saved_progress
    `localStorage.removeItem('rosary_step')`
    `localStorage.removeItem('rosary_set')`
  end

  def load_saved_step
    val = `localStorage.getItem('rosary_step')`
    `#{val} === null` ? nil : val.to_i
  end

  def load_saved_set
    val = `localStorage.getItem('rosary_set')`
    `#{val} === null` ? nil : val.to_sym
  end

  def load_saved_theme
    val = `localStorage.getItem('rosary_theme')`
    `#{val} === null` ? nil : val.to_sym
  end

  def save_theme
    `localStorage.setItem('rosary_theme', #{@theme})`
  end
end
