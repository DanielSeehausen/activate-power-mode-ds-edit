path = require "path"

module.exports =

  playInputSound: ->
    if (@getConfig "audioclip") is "customAudioclip"
      pathtoaudio = @getConfig "customAudioclip"
    else
      pathtoaudio = path.join(__dirname, @getConfig "audioclip")
    audio = new Audio(pathtoaudio)
    audio.currentTime = 0
    audio.volume = @getConfig "volume"
    audio.play()

  playClip: (clip, vol=1) ->
    #volume (vol) should be used as a modifier to maintain relative levels, not to override user set volume level in the config
    try
      console.log("SDSdsd")
      pathtoaudio = path.join(__dirname, "../audioclips/#{clip}.wav")
    catch e then console.error("No audio clip: ../audioclips/#{clip}.wav found!")
    audio = new Audio(pathtoaudio)
    audio.currentTime = 0
    audio.volume = (@getConfig "volume") * vol
    audio.play()



  getConfig: (config) ->
    atom.config.get "activate-power-mode.playAudio.#{config}"
