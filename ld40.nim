import os

import csfml, csfml_ext, csfml_window

import utils

const screenSize = (1024, 1024)

type
  Game = ref object
    window: RenderWindow
    currentMap: Map
    camera: View

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
    currentMap: newMap(getCurrentDir() / "assets" / "map.png"),
    camera: newView()
  )

  result.camera.zoom(0.5)
  result.window.framerateLimit = 60

proc draw(game: Game) =
  game.window.clear(Black)
  game.currentMap.draw(game.window)

  game.window.view = game.camera

  game.window.display()

proc moveCamera(game: Game, dir: Vector2f, mag=16.0) =
  game.camera.move(dir*mag)

when isMainModule:
  var game = newGame()

  while game.window.open:
    for event in game.window.events:
      if event.kind == EventType.Closed or
        (event.kind == EventType.KeyPressed and event.key.code == KeyCode.Escape):
          game.window.close()

      if event.kind == EventType.KeyPressed:
        case event.key.code
        of KeyCode.Left:
          game.moveCamera(vec2(-1, 0))
        of KeyCode.Right:
          game.moveCamera(vec2(1, 0))
        of KeyCode.Down:
          game.moveCamera(vec2(0, 1))
        of KeyCode.Up:
          game.moveCamera(vec2(0, -1))
        else: discard

    game.draw()

