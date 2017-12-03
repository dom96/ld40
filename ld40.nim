import os

import csfml, csfml_ext, csfml_window

import utils

const screenSize = (1024, 1024)
const mapStopSize = (32, 32)

type
  Game = ref object
    window: RenderWindow
    currentMap: Map
    camera: View
    crosshair: Crosshair
    hud: Hud

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
    selectedMapStop: Texture
    deselectedMapStop: Texture
    stops: seq[MapStop]

    selectedStops: seq[MapStop]

  Crosshair = ref object
    texture: Texture

  Hud = ref object
    currentRoute: Text

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

proc getBoundingBox(a: MapStop): IntRect =
  return IntRect(
    left: a.pos.x - (mapStopSize[0] div 2),
    top: a.pos.y - (mapStopSize[1] div 2),
    width: mapStopSize[0],
    height: mapStopSize[1]
  )

proc newMap(filename: string): Map =
  result = Map(
    texture: newTexture(filename),
    sprite: newSprite(),
    selectedMapStop: newTexture(filename.splitFile.dir / "selected_stop.png"),
    deselectedMapStop: newTexture(filename.splitFile.dir / "deselected_stop.png"),
    stops: @[],
    selectedStops: @[]

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

  # Draw each map stop sprite.
  # TODO: Should we recycle sprites?
  for stop in map.stops:
    let sprite = newSprite()
    sprite.origin = vec2(16, 16)
    sprite.position = stop.pos
    if stop in map.selectedStops:
      sprite.texture = map.selectedMapStop
    else:
      sprite.texture = map.deselectedMapStop
    target.draw(sprite)

proc newCrosshair(filename: string): Crosshair =
  result = Crosshair(
    texture: newTexture(filename)
  )

proc getWindowPos(crosshair: Crosshair): Vector2i =
  vec2(screenSize[0] div 2, screenSize[1] div 2)

proc draw(crosshair: Crosshair, target: RenderWindow) =
  # Cross hair
  let sprite = newSprite()
  sprite.texture = crosshair.texture
  sprite.origin = vec2(16, 16)
  sprite.position = getWindowPos(crosshair)
  sprite.scale = vec2(3, 3)
  target.draw(sprite)

proc newHud(): Hud =
  let font = newFont(getCurrentDir() / "assets" / "PICO-8.ttf")
  result = Hud(
    currentRoute: newText("Route: No route selected", font)
  )
  result.currentRoute.characterSize = 14
  result.currentRoute.position = vec2(10, 10)

proc draw(hud: Hud, target: RenderWindow) =
  let color = "5f574f"
  let fill = newRectangleShape(vec2(screenSize[0], 40))
  fill.position = vec2(0, 0)
  fill.fillColor = color(0x5f574fff)
  fill.outlineColor = color(0x5f574faa)
  fill.outlineThickness = 2

  target.draw(fill)

  target.draw(hud.currentRoute)

proc newGame(): Game =
  result = Game(
    window: newRenderWindow(videoMode(screenSize[0], screenSize[1]), "LD40",
                            WindowStyle.Titlebar or WindowStyle.Close),
    currentMap: newMap(getCurrentDir() / "assets" / "map.png"),
    crosshair: newCrosshair(getCurrentDir() / "assets" / "crosshair.png"),
    camera: newView(),
    hud: newHud()
  )

  result.camera.zoom(0.5)
  result.window.framerateLimit = 60

proc draw(game: Game) =
  game.window.clear(Black)

  game.window.view = game.camera
  game.currentMap.draw(game.window)

  game.window.view = game.window.defaultView()
  game.crosshair.draw(game.window)
  game.hud.draw(game.window)

  game.window.display()

proc moveCamera(game: Game, dir: Vector2f, mag=16.0) =
  game.camera.move(dir*mag)

proc select(game: Game) =
  ## Selects a stop that's under the crosshair.
  let crosshairPos = game.window.mapPixelToCoords(getWindowPos(game.crosshair), game.camera)
  echo("Select at ", crosshairPos)

  # We need to find the closest stop.
  var closest: MapStop = nil
  for stop in game.currentMap.stops:
    let box = stop.getBoundingBox()
    if box.contains(crosshairPos.x, crosshairPos.y):
      closest = stop
      break # TODO: Let's hope there are no stops right beside each other...

  if closest.isNil:
    echo("Not found")
  else:
    echo("Selected ", closest.name)
    let index = rfind(game.currentMap.selectedStops, closest)
    if index != -1:
      # Remove the last one of this.
      game.currentMap.selectedStops.delete(index)
    else:
      game.currentMap.selectedStops.add(closest)

proc update(game: Game) =
  # Generate the current route.
  var text = "Route: "
  if game.currentMap.selectedStops.len > 0:
    for stop in game.currentMap.selectedStops:
      text.add(stop.name & " > ")
  else:
    text.add("No route selected")

  game.hud.currentRoute.strC = text

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
        of KeyCode.Space:
          game.select()
        else: discard

    game.update()
    game.draw()

