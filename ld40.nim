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
    truck: Truck

  Neighbour = tuple
    stop: MapStop
    fuelCost: int

  MapStop = ref object
    name: string
    pos: Vector2i # Relative to map
    neighbours: seq[Neighbour]
    isDepot: bool
    isSelected: bool

  Map = ref object
    texture: Texture
    sprite: Sprite
    selectedMapStop: Texture
    deselectedMapStop: Texture
    stops: seq[MapStop]

  Crosshair = ref object
    texture: Texture

  Hud = ref object
    currentRoute: Text

  Truck = ref object
    fuelCapacity: int
    currentStop: MapStop

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
    stops: @[]
  )
  result.texture.smooth = false
  result.sprite.texture = result.texture

  # Define default map stops.
  let residence = createMapStop(result, "The Roswell Residence", vec2(142, 150))
  let lighthouse = createMapStop(result, "Lighthouse", vec2(367, 150))
  let postOffice = createMapStop(result, "Post Office", vec2(620, 150))
  postOffice.isDepot = true
  let hospital = createMapStop(result, "Hospital", vec2(474, 261))
  let supermarket = createMapStop(result, "Supermarket", vec2(366, 317))
  let beach = createMapStop(result, "Beach", vec2(630, 262))
  let residence2 = createMapStop(result, "Residence", vec2(499, 420))
  let residence3 = createMapStop(result, "Residence", vec2(638, 543))
  let fuelStation = createMapStop(result, "Fuel station", vec2(499, 647))
  let southDocks = createMapStop(result, "South docks", vec2(202, 647))
  let cafe = createMapStop(result, "Cafe Mauds", vec2(186, 431))

  postOffice.link(lighthouse, 2)
  lighthouse.link(residence, 1)
  residence.link(cafe, 1)
  cafe.link(supermarket, 1)
  cafe.link(southDocks, 1)
  supermarket.link(lighthouse, 1)
  supermarket.link(hospital, 1)
  supermarket.link(residence2, 1)
  residence2.link(beach, 1)
  residence2.link(residence3, 1)
  beach.link(residence3, 1)
  beach.link(postOffice, 1)
  residence3.link(fuelStation, 1)
  fuelStation.link(southDocks, 1)

  # Select post office by default.
  postOffice.isSelected = true

proc draw(map: Map, target: RenderWindow) =
  target.draw(map.sprite)

  # Draw each map stop sprite.
  # TODO: Should we recycle sprites?
  for stop in map.stops:
    let sprite = newSprite()
    sprite.origin = vec2(16, 16)
    sprite.position = stop.pos
    if stop.isSelected:
      sprite.texture = map.selectedMapStop
      sprite.position = sprite.position + vec2(0.0, 4.0)
    else:
      sprite.texture = map.deselectedMapStop
    target.draw(sprite)

proc getStart(map: Map): MapStop =
  for stop in map.stops:
    if stop.isDepot:
      return stop

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
  let fill = newRectangleShape(vec2(screenSize[0], 40))
  fill.position = vec2(0, 0)
  fill.fillColor = color(0x5f574fff)
  fill.outlineColor = color(0x5f574faa)
  fill.outlineThickness = 2

  target.draw(fill)

  target.draw(hud.currentRoute)

proc newTruck(start: MapStop, fuelCapacity=5): Truck =
  result = Truck(
    fuelCapacity: fuelCapacity,
    currentStop: start
  )

proc centerCameraOn(game: Game, stop: MapStop) =
  game.camera.center = stop.pos

proc newGame(): Game =
  result = Game(
    window: newRenderWindow(videoMode(screenSize[0], screenSize[1]), "LD40",
                            WindowStyle.Titlebar or WindowStyle.Close),
    currentMap: newMap(getCurrentDir() / "assets" / "map.png"),
    crosshair: newCrosshair(getCurrentDir() / "assets" / "crosshair.png"),
    camera: newView(),
    hud: newHud()
  )

  result.truck = newTruck(getStart(result.currentMap))

  result.camera.zoom(0.5)
  result.window.framerateLimit = 60

  result.centerCameraOn(result.truck.currentStop)

proc draw(game: Game) =
  game.window.clear(color(0x19abffff))

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
    closest.isSelected = not closest.isSelected

proc update(game: Game) =
  # Generate the current route.
  var text = "Fuel: "
  text.add("No route selected") # TODO: Change this into a message system.

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

