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

  resetCanvas: ->
    @animationOff()
    @editor = null
    @editorElement = null

  animationOff: ->
    cancelAnimationFrame(@animationFrame)
    @animationFrame = null

  animationOn: ->
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
    # {left, top} = @calculatePosition screenPosition
    x = screenPosition[0]
    y = screenPosition[1]
    spriteSheet = @explosionSpriteSheet
    size = 1.5
    @explosions.push {x: x, y: y, sizeMod: size, frame:  0}

  spawnRandomSizeExplosion: (screenPosition) ->
    {left, top} = @calculatePosition screenPosition
    size = Math.random()
    x = (Math.random() * (max - @minOffset) + @minOffset) + left
    y = (Math.random() * (max - @minOffset) + @minOffset) + top
    @explosions.push {x: left + x, y: top+y, sizeMod: size, frame: 0}

  drawExplosion: ->
    @animationOn()
    @canvas.width = @canvas.width
    return if not @explosions.length

    gco = @context.globalCompositeOperation
    @context.globalCompositeOperation = "lighter"
    debugger
    for i in [@explosions.length - 1]
      e = @explosions[i]
      if e.frame >= @spriteLocs.length
        @explosions.splice i, 1
        continue
      currFrame = e.frame
      @context.drawImage(@explosionSpriteSheet,    #img
                         @spriteLocs[currFrame][0], #source x
                         @spriteLocs[currFrame][1], #source y
                         @spriteWidth, #source width
                         @spriteHeight, #source height
                         e.x, #destination x
                         e.y, #destination y
                         e.x*e.sizeMod, #frame width
                         e.y*e.sizeMod) #frame height

    @context.globalCompositeOperation = gco

  getConfig: (config) ->
    atom.config.get "activate-power-mode.explosions.#{config}"
