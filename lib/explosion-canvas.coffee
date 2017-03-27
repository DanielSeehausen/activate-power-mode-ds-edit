{CompositeDisposable} = require "atom"
comboMode = require "./combo-mode"

module.exports =
  subscriptions: null

  init: ->
    @resetExplosions()
    @animationOn()
    @explosionSpriteSheet = new Image()
    @explosionSpriteSheet.src = "../../../../../../Desktop/power-mode-ds-edit/sprites/explosion-sprite.png"
    @spriteWidth = @spriteHeight = 130.5
    @spriteLocs = [[0, 0],     [130.5, 0],     [261, 0],     [391.5, 0],
                   [0, 130.5], [130.5, 130.5], [261, 130.5], [391.5, 130.5],
                   [0, 261],   [130.5, 261],   [261, 261],   [391.5, 261],
                   [0, 391.5], [130.5, 391.5], [261, 391.5], [391.5, 391.5]]
    @minOffset = -8
    @maxOffset = 8
    @explosionTicCount = 4 #used to control the speed of the animation

  resetCanvas: ->
    @animationOff()
    @editor = null
    @editorElement = null

  animationOff: ->
    console.log("animation over")
    cancelAnimationFrame(@animationFrame)
    @animationFrame = null

  animationOn: ->
    console.log("animation starting")
    @animationFrame = requestAnimationFrame @drawExplosion.bind(this)

  resetExplosions: ->
    @explosions = []

  destroy: ->
    @resetCanvas()
    @resetExplosions()
    @canvas?.parentNode.removeChild @canvas
    @canvas = null
    @subscriptions?.dispose()

  setupCanvas: (editor, editorElement) ->
    if not @canvas
      @canvas = document.createElement "canvas"
      @context = @canvas.getContext "2d"
      @canvas.classList.add "power-mode-canvas"

    editorElement.appendChild @canvas
    @canvas.style.display = "block"
    @canvas.width = editorElement.offsetWidth
    @canvas.height = editorElement.offsetHeight
    @scrollView = editorElement.querySelector(".scroll-view")
    @editorElement = editorElement
    @editor = editor
    @init()

  calculatePositions: (screenPosition) ->
    {left, top} = @editorElement.pixelPositionForScreenPosition screenPosition
    left: left + @scrollView.offsetLeft - @editorElement.getScrollLeft()
    top: top + @scrollView.offsetTop - @editorElement.getScrollTop() + @editor.getLineHeightInPixels() / 2

  spawnBigExplosion: (screenPosition) ->
    x = screenPosition[0]
    y = screenPosition[1]
    spriteSheet = @explosionSpriteSheet
    size = 1.5
    @explosions.push {x: x, y: y, sizeMod: size, frame:  0, tics: 0}

  spawnRandomSizeExplosion: (screenPosition) ->
    {left, top} = @calculatePosition screenPosition
    size = Math.random()
    x = (Math.random() * (max - @minOffset) + @minOffset) + left
    y = (Math.random() * (max - @minOffset) + @minOffset) + top
    @explosions.push {x: left + x, y: top+y, sizeMod: size, frame: 0, tics: 0}

  renderExplosion: (e) ->
    @context.drawImage(@explosionSpriteSheet,    #img
                  @spriteLocs[e.frame][0], #source x
                  @spriteLocs[e.frame][1], #source y
                  @spriteWidth, #source width
                  @spriteHeight, #source height
                  e.x, #destination x
                  e.y, #destination y
                  e.x*e.sizeMod, #frame width
                  e.y*e.sizeMod) #frame height

  drawExplosion: ->
    @animationOn()
    if not @explosions.length
      @animationOff()
      return
    @canvas.width = @canvas.width
    for i in [@explosions.length - 1]
      e = @explosions[i]
      if e.tics > @explosionTicCount #if we are ready for the next sprite
        e.tics = 0
        e.frame += 1
        if e.frame == @spriteLocs.length #if we have completed the animation, remove it and escape via continue
          @explosions.splice i, 1
          continue
      e.tics++
      @renderExplosion(e)

  getConfig: (config) ->
    atom.config.get "activate-power-mode.explosions.#{config}"
