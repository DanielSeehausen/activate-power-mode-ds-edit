debounce = require "lodash.debounce"
defer = require "lodash.defer"
sample = require "lodash.sample"
colorHelper = require "./color-helper"
explosionsCanvas = require "./explosion-canvas"
audio = require "./play-audio"

module.exports =
  currentStreak: 0
  reached: false
  maxStreakReached: false

  reset: ->
    @container?.parentNode?.removeChild @container

  destroy: ->
    @reset()
    @container = null
    @debouncedEndStreak?.cancel()
    @debouncedEndStreak = null
    @streakTimeoutObserver?.dispose()
    @opacityObserver?.dispose()
    @currentStreak = 0
    @reached = false
    @maxStreakReached = false

  createElement: (name, parent)->
    @element = document.createElement "div"
    @element.classList.add name
    parent.appendChild @element if parent
    @element

  setup: (editorElement) ->
    if not @container
      @container = @createElement "streak-container"
      @container.classList.add "combo-zero"
      @title = @createElement "title", @container
      @title.textContent = "Combo"
      @max = @createElement "max", @container
      @avg = @createElement "avg", @container
      @counter = @createElement "counter", @container
      @counter.setAttribute("id", "combo-counter")
      @bar = @createElement "bar", @container
      @exclamations = @createElement "exclamations", @container
      @maximumPower = 1.8
      @atMaxPower = false

      @avgStreak = @updateAvgStreak()
      @maxStreak = @getMaxStreak()
      @max.textContent = "Max #{@maxStreak}"

      @streakTimeoutObserver?.dispose()
      @streakTimeoutObserver = atom.config.observe 'activate-power-mode.comboMode.streakTimeout', (value) =>
        @streakTimeout = value * 1000
        @endStreak()
        @debouncedEndStreak?.cancel()
        @debouncedEndStreak = debounce @endStreak.bind(this), @streakTimeout

      @opacityObserver?.dispose()
      @opacityObserver = atom.config.observe 'activate-power-mode.comboMode.opacity', (value) =>
        @container?.style.opacity = value

    @exclamations.innerHTML = ''

    editorElement.querySelector(".scroll-view").appendChild @container

    if @currentStreak
      leftTimeout = @streakTimeout - (performance.now() - @lastStreak)
      @refreshStreakBar leftTimeout

    @renderStreak()

  increaseStreak: ->
    @lastStreak = performance.now()
    @debouncedEndStreak()
    @currentStreak++
    @container.classList.remove "combo-zero"
    if @currentStreak > @maxStreak
      @increaseMaxStreak()
    @showExclamation() if @currentStreak > 0 and @currentStreak % @getConfig("exclamationEvery") is 0
    if @currentStreak >= @getConfig("activationThreshold") and not @reached
      @reached = true
      @container.classList.add "reached"
    @refreshStreakBar()
    @renderStreak()

  endStreak: ->
    if @currentStreak > 5
      @updateAvgStreak()
    @currentStreak = 0
    if @atMaxPower
      audio.playClip('sn-unconscious-incompetence')
      @counter.classList.remove "shimmer"
      @bar.classList.remove "shimmer"
    @atMaxPower = false
    @reached = false
    @maxStreakReached = false
    @container.classList.add "combo-zero"
    @container.classList.remove "reached"
    @renderStreak()

  renderStreak: ->
    @counter.textContent = @currentStreak
    b = @getBenchmark()
    @counter.style.opacity = if (b > 1.2) then 1 else ((b * .5) + .4)
    @bar.style.opacity = if (b > 1.2) then 1 else ((b * .5) + .4)
    @counter.style.fontSize = if b*80 < 30 then "30px" else if b*80 > 120 then "120px" else "#{b*80}px"
    comboColor = colorHelper.getComboCountColor(b)
    @counter.style.color = @bar.style.background = comboColor

    if !@atMaxPower && b > @maximumPower
      explosionsCanvas.maxPowerExplosion()
      audio.playClip('ludicrous-kill')
      @atMaxPower = true
      @counter.classList.add "shimmer"
      @bar.classList.add "shimmer"

    @counter.classList.remove "bump"
    defer =>
      @counter.classList.add "bump"

  refreshStreakBar: (leftTimeout = @streakTimeout) ->
    scale = leftTimeout / @streakTimeout
    @bar.style.transition = "none"
    @bar.style.transform = "scaleX(#{scale})"
    setTimeout =>
      @bar.style.transform = ""
      @bar.style.transition = "transform #{leftTimeout}ms linear"
    , 100

  showExclamation: (text = null) ->
    exclamation = document.createElement "span"
    exclamation.classList.add "exclamation"
    text = sample @getConfig "exclamationTexts" if text is null
    exclamation.textContent = text

    @exclamations.insertBefore exclamation, @exclamations.childNodes[0]
    setTimeout =>
      if exclamation.parentNode is @exclamations
        @exclamations.removeChild exclamation
    , 2000

  hasReached: ->
    @reached

  setAvgStreakDefaults: ->
    count = 0
    sum = 0
    localStorage.setItem "activate-power-mode.totalStreakCount", count
    localStorage.setItem "activate-power-mode.totalStreakSum", sum
    @avgStreak = 0
    @avg.textContent = "Avg #{@avgStreak}"

  updateAvgStreak: ->
    sum = localStorage.getItem "activate-power-mode.totalStreakSum"
    count = localStorage.getItem "activate-power-mode.totalStreakCount"
    if (sum == null) || (count == null)
      @setAvgStreakDefaults()
    else
      if @currentStreak > 0
        count = parseInt(count) + 1
        sum = parseInt(sum) + @currentStreak
      else
        count = parseInt(count)
        sum = parseInt(sum)
      localStorage.setItem "activate-power-mode.totalStreakCount", count
      localStorage.setItem "activate-power-mode.totalStreakSum", sum
      @avgStreak = if count == 0 then 0 else Math.trunc(sum/count)
      @avg.textContent = "Avg #{@avgStreak}"
      return @avgStreak

  getMaxStreak: ->
    maxStreak = localStorage.getItem "activate-power-mode.maxStreak"
    maxStreak = 0 if maxStreak is null
    maxStreak

  increaseMaxStreak: ->
    localStorage.setItem "activate-power-mode.maxStreak", @currentStreak
    @maxStreak = @currentStreak
    @max.textContent = "Max #{@maxStreak}"
    @showExclamation "NEW PERSONAL BEST!!!" if @maxStreakReached is false
    @maxStreakReached = true

  resetMaxStreak: ->
    localStorage.setItem "activate-power-mode.maxStreak", 0
    @maxStreakReached = false
    @maxStreak = 0
    if @max
      @max.textContent = "Max 0"

  getBenchmark: ->
    return if @avgStreak == 0 then 0 else parseInt(@currentStreak)/parseInt(@avgStreak)

  getConfig: (config) ->
    atom.config.get "activate-power-mode.comboMode.#{config}"
