import os, math, strutils, options

import csfml, csfml_ext, csfml_window

import utils, consts, hud, camera, stats, truck

type
  Scene {.pure.} = enum
    Map, Title

  Title = ref object
    titleTexture: Texture
    titleClock: Clock
    titleText: Text
    lastTransparency: float

  Game = ref object
    window: RenderWindow
    currentMap: Map
    camera: Camera
    crosshair: Crosshair
    hud: Hud
    truck: Truck
    currentScene: Scene
    title: Title
    stats: Stats

  Map = ref object
    texture: Texture
    sprite: Sprite
    selectedMapStop: Texture
    deselectedMapStop: Texture
    stops: seq[MapStop]

  Crosshair = ref object
    texture: Texture


proc createMapStop(map: Map, name: string, pos: Vector2i): MapStop =
  map.stops.add(
    MapStop(
      name: name,
      pos: pos,
      neighbours: @[]
    )
  )

  return map.stops[^1]

proc link(a, b: MapStop, fuelCost: int, roads: seq[Road] = @[]) =
  ## Links two MapStops togethers.
  a.neighbours.add((b, fuelCost, roads))
  b.neighbours.add((a, fuelCost, roads))
  var newRoads: seq[Road] = @[]
  for road in mitems(b.neighbours[^1].roads):
    newRoads.insert(
      (
        start: road.finish,
        finish: road.start,
        dir:
          case road.dir
          of North: South
          of South: North
          of East: West
          of West: East
      )
    )
  b.neighbours[^1].roads = newRoads

proc getBoundingBox(a: MapStop): IntRect =
  return IntRect(
    left: a.pos.x - (mapStopSize[0] div 2),
    top: a.pos.y - (mapStopSize[1] div 2),
    width: mapStopSize[0],
    height: mapStopSize[1]
  )

proc find(map: Map, name: string): MapStop =
  for stop in map.stops:
    if stop.name == name: return stop

  assert false

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

  postOffice.link(lighthouse, 2,
    @[
      (start: postOffice.pos, finish: lighthouse.pos, dir: West)
    ]
  )
  lighthouse.link(residence, 1,
    @[
      (start: lighthouse.pos, finish: residence.pos, dir: West)
    ]
  )
  residence.link(cafe, 1,
    @[
      (start: residence.pos, finish: vec2(142, 378), dir: South),
      (start: vec2(142, 377), finish: vec2(185, 378), dir: East),
      (start: vec2(185, 378), finish: cafe.pos, dir: South)
    ]
  )
  cafe.link(supermarket, 1,
    @[
      (start: cafe.pos, finish: vec2(366, 429), dir: East),
      (start: vec2(366, 429), finish: supermarket.pos, dir: North)
    ]
  )
  cafe.link(residence2, 1,
    @[
      (start: cafe.pos, finish: vec2(366, 429), dir: East),
      (start: vec2(366, 429), finish: vec2(366, 379), dir: North),
      (start: vec2(366, 379), finish: vec2(498, 379), dir: East),
      (start: vec2(498, 379), finish: residence2.pos, dir: South),
    ]
  )
  cafe.link(southDocks, 1,
    @[
      (start: cafe.pos, finish: vec2(186, 597), dir: South),
      (start: vec2(186, 597), finish: vec2(202, 600), dir: East),
      (start: vec2(202, 600), finish: southDocks.pos, dir: South)
    ]
  )
  supermarket.link(lighthouse, 1,
   @[
      (start: supermarket.pos, finish: lighthouse.pos, dir: North)
    ]
  )
  supermarket.link(hospital, 1,
    @[
      (start: supermarket.pos, finish: vec2(366, 263), dir: North),
      (start: vec2(366, 263), finish: hospital.pos, dir: East),
    ]
  )
  supermarket.link(residence2, 1,
    @[
      (start: supermarket.pos, finish: vec2(366, 379), dir: South),
      (start: vec2(366, 379), finish: vec2(498, 380), dir: East),
      (start: vec2(498, 380), finish: residence2.pos, dir: South),
    ]
  )
  residence2.link(beach, 1,
    @[
      (start: residence2.pos, finish: vec2(498, 380), dir: North),
      (start: vec2(498, 380), finish: vec2(594, 380), dir: East),
      (start: vec2(594, 380), finish: vec2(594, 262), dir: North),
      (start: vec2(594, 262), finish: beach.pos, dir: East),
    ]
  )
  residence2.link(residence3, 1,
    @[
      (start: residence2.pos, finish: vec2(498, 380), dir: North),
      (start: vec2(498, 380), finish: vec2(594, 380), dir: East),
      (start: vec2(594, 380), finish: vec2(594, 544), dir: South),
      (start: vec2(594, 544), finish: residence3.pos, dir: East),
    ]
  )
  beach.link(residence3, 1,
    @[
      (start: beach.pos, finish: vec2(594, 262), dir: West),
      (start: vec2(594, 262), finish: vec2(594, 544), dir: South),
      (start: vec2(594, 544), finish: residence3.pos, dir: East),
    ]
  )
  beach.link(postOffice, 1,
    @[
      (start: beach.pos, finish: vec2(594, 262), dir: West),
      (start: vec2(594, 262), finish: vec2(594, 151), dir: North),
      (start: vec2(594, 151), finish: postOffice.pos, dir: East),
    ]
  )
  residence3.link(fuelStation, 1,
    @[
      (start: residence3.pos, finish: vec2(566, 543), dir: West),
      (start: vec2(566, 543), finish: vec2(566, 647), dir: South),
      (start: vec2(566, 647), finish: fuelStation.pos, dir: West),
    ]
  )
  fuelStation.link(southDocks, 1,
    @[
      (start: fuelStation.pos, finish: southDocks.pos, dir: West),
    ]
  )
  hospital.link(beach, 1,
    @[
      (start: hospital.pos, finish: beach.pos, dir: East),
    ]
  )
  hospital.link(postOffice, 1,
    @[
      (start: hospital.pos, finish: vec2(593, 261), dir: East),
      (start: vec2(593, 261), finish: vec2(593, 152), dir: North),
      (start: vec2(593, 152), finish: postOffice.pos, dir: East),
    ]
  )
  hospital.link(residence2, 1,
    @[
      (start: hospital.pos, finish: vec2(593, 261), dir: East),
      (start: vec2(593, 261), finish: vec2(593, 379), dir: South),
      (start: vec2(593, 379), finish: vec2(497, 379), dir: West),
      (start: vec2(497, 379), finish: residence2.pos, dir: South),
    ]
  )
  hospital.link(residence3, 1,
    @[
      (start: hospital.pos, finish: vec2(593, 261), dir: East),
      (start: vec2(593, 261), finish: vec2(593, 540), dir: South),
      (start: vec2(593, 540), finish: residence3.pos, dir: East),
    ]
  )
  hospital.link(lighthouse, 1,
    @[
      (start: hospital.pos, finish: vec2(365, 262), dir: West),
      (start: vec2(365, 262), finish: lighthouse.pos, dir: North),
    ]
  )

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
    sprite.destroy()

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

proc getMapPos(crosshair: Crosshair, game: Game): Vector2f =
  game.window.mapPixelToCoords(getWindowPos(crosshair), game.camera.view)

proc draw(crosshair: Crosshair, target: RenderWindow) =
  # Cross hair
  let sprite = newSprite()
  sprite.texture = crosshair.texture
  sprite.origin = vec2(16, 16)
  sprite.position = getWindowPos(crosshair)
  sprite.scale = vec2(3, 3)
  target.draw(sprite)
  sprite.destroy()

proc newTruck(start: MapStop, fuelCapacity=4): Truck =
  result = Truck(
    fuelCapacity: fuelCapacity,
    fuel: fuelCapacity,
    currentStop: start,
    pos: start.pos,
    dir: West,
    roadTravelClock: nil
  )
  for dir in Direction:
    result.truckTexture[dir] = newTexture(getCurrentDir() / "assets" /
        "truck_$1.png" % [toLowerAscii($dir)])

proc draw(truck: Truck, target: RenderWindow) =
  let sprite = newSprite(truck.truckTexture[truck.dir])
  sprite.position = truck.pos
  sprite.origin = vec2(16, 19)
  sprite.scale = vec2(1.5, 1.5)

  target.draw(sprite)

  sprite.destroy()

proc update(truck: Truck, game: Game) =
  if not truck.roadTravelClock.isNil:
    if truck.travellingTo.roads.len == 0:
      assert false
    else:
      let road = truck.travellingTo.roads[0]
      let diff = road.finish - road.start
      let dist = diff.length

      let scale = truck.roadTravelClock.elapsedTime().asMilliseconds().float / (10*dist)
      if scale >= 1:
        # Movement finished.

        if truck.travellingTo.roads.len == 1:
          # Travel finished.
          truck.fuel.dec(truck.travellingTo.fuelCost)
          if game.stats.completeDelivery(truck.travellingTo.stop):
            game.hud.setMessage("You've delivered a package!",
                                timeout=2000, primary=false)

          truck.currentStop = truck.travellingTo.stop
          truck.pos = truck.travellingTo.stop.pos
          destroy(truck.roadTravelClock)
          truck.roadTravelClock = nil
        else:
          # Move on to the next road.
          truck.travellingTo.roads.delete(0)
          truck.pos = road.finish
          discard truck.roadTravelClock.restart()
      else:
        truck.pos = road.start + (diff*scale)
      truck.dir = road.dir

proc findNeighbour(truck: Truck, target: MapStop): Option[Neighbour] =
  result = none(Neighbour)

  for neighbour in truck.currentStop.neighbours:
    if neighbour.stop == target:
      result = some(neighbour)

proc isTravelling(truck: Truck): bool =
  not truck.roadTravelClock.isNil

proc travel(truck: Truck, n: Neighbour) =
  assert(not isTravelling(truck))
  truck.roadTravelClock = newClock()
  truck.travellingTo = n

proc centerCameraOn(game: Game, stop: MapStop, smooth: bool) =
  game.camera.moveTo(stop.pos, smooth=smooth)

proc newTitle(font: Font): Title =
  result = Title(
    titleTexture: newTexture(getCurrentDir() / "assets" / "title.png"),
    titleClock: newClock(),
    lastTransparency: 0.5
  )

  result.titleText = newText("Press space to begin", font, 20)
  result.titleText.position = vec2(
    screenSize[0] div 2,
    screenSize[1] - 200
  )
  result.titleText.origin = vec2(
    result.titleText.localBounds.width / 2,
    result.titleText.localBounds.height / 2
  )

proc draw(title: Title, target: RenderWindow) =
  target.clear(color(0x1d3564ff))

  let sprite = newSprite(title.titleTexture)
  sprite.scale = vec2(
    screenSize[0] / title.titleTexture.size.x,
    screenSize[1] / title.titleTexture.size.y
  )
  target.draw(sprite)

  var scale = (title.titleClock.elapsedTime().asMilliseconds() / textPulse) / 2
  if title.titleClock.elapsedTime().asMilliseconds() <= textPulse:
    var transparency = 0.5
    if (title.lastTransparency-0.5) >= 0.09:
      transparency = title.lastTransparency - scale
    else:
      transparency = title.lastTransparency + scale
    title.titleText.color = color(255.uint8, 255.uint8, 255.uint8, uint8(transparency*255))
  else:
    discard title.titleClock.restart()
    title.lastTransparency = title.titleText.color.a.int / 255

  target.draw(sprite)
  target.draw(title.titleText)

  destroy(sprite)

proc init(game: Game) =
  game.stats.setTasks(@[game.currentMap.find("Lighthouse")])

  game.hud.printDialogue("This is the Post office...",
    proc () {.gcsafe, nosideeffect.} =
      game.centerCameraOn(game.currentMap.stops[1], true))
  game.hud.printDialogue("Your task is to move packages from the\n post office to people's homes")

proc newGame(): Game =
  result = Game(
    window: newRenderWindow(videoMode(screenSize[0], screenSize[1]), "LD40",
                            WindowStyle.Titlebar or WindowStyle.Close),
    currentMap: newMap(getCurrentDir() / "assets" / "map.png"),
    crosshair: newCrosshair(getCurrentDir() / "assets" / "crosshair.png"),
    camera: newCamera(),
    hud: newHud(),
    stats: newStats(),
    currentScene: Scene.Map#Scene.Title, TODO
  )

  result.truck = newTruck(getStart(result.currentMap))

  result.window.framerateLimit = 60

  result.centerCameraOn(result.truck.currentStop, false)

  result.title = newTitle(result.hud.font)

  init(result) # TODO

proc draw(game: Game) =
  case game.currentScene
  of Scene.Map:
    game.window.clear(color(0x19abffff))
    game.window.view = game.camera.view
    game.currentMap.draw(game.window)
    game.truck.draw(game.window)

    game.window.view = game.window.defaultView()
    game.crosshair.draw(game.window)
    game.stats.draw(game.window, game.hud.font)
    game.hud.draw(game.window)

  of Scene.Title:
    game.title.draw(game.window)

  game.window.display()

proc getHoveredMapStop(game: Game): MapStop =
  ## Returns nil when nothing is under the crosshair.
  let crosshairPos = game.crosshair.getMapPos(game)

  # We need to find the closest stop.
  var closest: MapStop = nil
  for stop in game.currentMap.stops:
    let box = stop.getBoundingBox()
    if box.contains(crosshairPos.x, crosshairPos.y):
      closest = stop
      break # TODO: Let's hope there are no stops right beside each other...
  return closest

proc moveCamera(game: Game, dir: Vector2f, mag=16.0) =
  game.camera.moveBy(dir*mag)

  # Show primary message when hovered over button.
  let closest = game.getHoveredMapStop()
  if closest.isNil:
    game.hud.removeMessage(primary=true)
  else:
    game.hud.setMessage(closest.name, primary=true)

proc select(game: Game) =
  ## Selects a stop that's under the crosshair.
  case game.currentScene
  of Scene.Map:
    if not game.hud.select():
      let closest = game.getHoveredMapStop()

      if closest.isNil:
        game.hud.setMessage("No stop under cursor.", timeout=2000, primary=false)
      else:
        echo("Selected ", closest.name)

        if game.truck.currentStop == closest:
          game.hud.setMessage("Already at the $1." % closest.name,
                              timeout=2000, primary=false)
          return

        if closest.isSelected:
          game.hud.setMessage("You've visited the $1" % closest.name,
                              timeout=2000, primary=false)
          return

        if game.truck.travellingTo.stop == closest:
          game.hud.setMessage("You're already travelling here." % closest.name,
                              timeout=2000, primary=false)
          return

        # Verify we're not currently travelling.
        if game.truck.isTravelling():
          game.hud.setMessage("You cannot change course.", timeout=2000, primary=false)
          return

        # Verify that this is a stop we can go to.
        let neighbour = findNeighbour(game.truck, closest)
        if neighbour.isNone():
          game.hud.setMessage("You cannot move here right now.", timeout=2000, primary=false)
          return

        closest.isSelected = true
        game.truck.travel(neighbour.get())
  of Scene.Title:
    game.currentScene = Scene.Map
    init(game)

proc update(game: Game) =
  # Update dialogs.
  game.hud.update()

  # Update camera.
  game.camera.update()

  game.truck.update(game)

  game.stats.update(game.truck)

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
        of KeyCode.P:
          game.stats.toggle()
        else: discard

    game.update()
    game.draw()

