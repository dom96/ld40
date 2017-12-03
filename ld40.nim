import os

import csfml, csfml_ext, csfml_window

import utils

const screenSize = (1024, 1024)

type
  Game = ref object
    window: RenderWindow
    currentMap: Map
    camera: View

    selectedStops: seq[MapStop]

  Neighbour = tuple
    stop: MapStop
    fuelCost: int

  MapStop = ref object
    name: string
    pos: Vector2i # Relative to map
    neighbours: seq[Neighbour]
    isDepot: bool

  Map = ref object
    texture: Texture
    sprite: Sprite
    stops: seq[MapStop]

proc createMapStop(map: Map, name: string, pos: Vector2i): MapStop =
  map.stops.add(
    MapStop(
      name: name,
      pos: pos,
      neighbours: @[]
    )
  )

  return map.stops[^1]

proc link(a, b: MapStop, fuelCost: int) =
  ## Links two MapStops togethers.
  a.neighbours.add((b, fuelCost))
  b.neighbours.add((a, fuelCost))

proc newMap(filename: string): Map =
  result = Map(
    texture: newTexture(filename),
    sprite: newSprite(),
    stops: @[]
  )
  result.texture.smooth = false
  result.sprite.texture = result.texture

  # Define default map stops.
  let supermarket = createMapStop(result, "Supermarket", vec2(144, 150))
  let lighthouse = createMapStop(result, "Lighthouse", vec2(368, 150))
  let postOffice = createMapStop(result, "Post Office", vec2(620, 150))
  postOffice.isDepot = true

  postOffice.link(lighthouse, 2)
  lighthouse.link(supermarket, 1)


proc draw(map: Map, target: RenderWindow) =
  target.draw(map.sprite)

proc newGame(): Game =
  result = Game(
    window: newRenderWindow(videoMode(screenSize[0], screenSize[1]), "LD40",
                            WindowStyle.Titlebar or WindowStyle.Close),
    currentMap: newMap(getCurrentDir() / "assets" / "map.png"),
    camera: newView(),
    selectedStops: @[]
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

