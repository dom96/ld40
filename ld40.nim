import os

import csfml, csfml_ext, csfml_window

import utils

const screenSize = (1024, 1024)

type
  Game = ref object
    window: RenderWindow
    currentMap: Map

  Map = ref object
    texture: Texture
    sprite: Sprite

proc newMap(filename: string): Map =
  result = Map(
    texture: newTexture(filename),
    sprite: newSprite()
  )
  result.texture.smooth = false
  result.sprite.texture = result.texture

proc draw(map: Map, target: RenderWindow) =
  target.draw(map.sprite)

proc newGame(): Game =
  result = Game(
    window: newRenderWindow(videoMode(screenSize[0], screenSize[1]), "LD40",
                            WindowStyle.Titlebar or WindowStyle.Close),
    currentMap: newMap(getCurrentDir() / "assets" / "map.png")
  )

proc draw(game: Game) =
  game.window.clear(Black)
  game.currentMap.draw(game.window)

  game.window.display()

when isMainModule:
  var game = newGame()

  while game.window.open:
    for event in game.window.events:
      if event.kind == EventType.Closed or
        (event.kind == EventType.KeyPressed and event.key.code == KeyCode.Escape):
          game.window.close()

    game.draw()

