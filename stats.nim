import os, strutils

import csfml

import utils, consts, truck

type
  Tasks* = ref object
    deliveries: seq[(bool, MapStop)]

  Stats* = ref object
    panel: Texture
    fuel: Texture
    ticks: Texture
    xOffset: float # Current x offset (used for showing the panel)
    shown*: bool
    smoothToggleClock: Clock
    fuelBar: Sprite
    fuelBars: int
    tasks: Tasks
    hour: int
    day: string

const maxOffset = 256

proc newStats*(): Stats =
  result = Stats(
    panel: newTexture(getCurrentDir() / "assets" / "stats.png"),
    fuel: newTexture(getCurrentDir() / "assets" / "fuel_bars.png"),
    ticks: newTexture(getCurrentDir() / "assets" / "ticks.png"),
  )
  result.fuelBar = newSprite(result.fuel)

proc reset*(stats: Stats) =
  for delivery in mitems(stats.tasks.deliveries):
    delivery[0] = false

proc setTasks*(stats: Stats, stops: seq[MapStop]) =
  stats.tasks = Tasks(
    deliveries: @[]
  )

  for stop in stops:
    stats.tasks.deliveries.add((false, stop))

proc completeDelivery*(stats: Stats, stop: MapStop): bool =
  for i in 0..<stats.tasks.deliveries.len:
    if stats.tasks.deliveries[i][1] == stop:
      stats.tasks.deliveries[i][0] = true
      return true

proc draw*(stats: Stats, target: RenderWindow, font: Font) =
  # Sidepanel
  let panel = newSprite(stats.panel)
  panel.position = vec2((-stats.panel.size.x).float + 52.0 + stats.xOffset, 220)
  target.draw(panel)

  # Fuel
  for i in 0..<stats.fuelBars:
    stats.fuelBar.position = vec2(
      panel.position.x + (24 + float(50*stats.fuelBar.scale.x*i.float)),
      panel.position.y + 18
    )
    target.draw(stats.fuelBar)

  # Tasks.
  for i in 0..<stats.tasks.deliveries.len:
    let (completed, stop) = stats.tasks.deliveries[i]
    let checkbox = newSprite(stats.ticks)
    if completed:
      checkbox.textureRect = IntRect(left: 0, top: 0, width: 24, height: 24)
    else:
      checkbox.textureRect = IntRect(left: 27, top: 0, width: 20, height: 24)

    checkbox.position = vec2(
      panel.position.x + 30,
      panel.position.y + 201 + float(i*33)
    )
    target.draw(checkbox)

    let text = newText(stop.name, font, 10)
    text.position = checkbox.position + vec2(cfloat(checkbox.textureRect.width + 10), 10)
    text.color = Black
    target.draw(text)

    destroy(checkbox)
    destroy(text)

  # Clock
  var text = newText("$#: $#:00" % [stats.day, $stats.hour], font, 18)
  text.position = vec2(panel.position.x + 20, panel.position.y + 72)
  text.color = color(0x3d3d3dff)
  target.draw(text)
  destroy(text)

  destroy(panel)

proc toggle*(stats: Stats) =
  stats.shown = not stats.shown
  stats.smoothToggleClock = newClock()

  discard stats.smoothToggleClock.restart()

proc update*(stats: Stats, truck: Truck, level, hour: int) =
  if not stats.smoothToggleClock.isNil:
    let time = stats.smoothToggleClock.elapsedTime().asMilliseconds()
    if time > statsToggleSpeed:
      stats.xOffset =
        if stats.shown:
          maxOffset
        else:
          0
    else:
      let scale = time / statsToggleSpeed
      stats.xOffset = maxOffset*scale
      if not stats.shown:
        stats.xOffset = maxOffset-stats.xOffset

  # Fuel
  let perc = truck.fuel / truck.fuelCapacity
  if perc >= 1:
    # Use green.
    stats.fuelBar.textureRect = IntRect(left: 0, top: 0, width: 48, height: 24)
  elif perc >= 3/4:
    # Use yellow.
    stats.fuelBar.textureRect = IntRect(left: 52, top: 0, width: 48, height: 24)
  elif perc >= 2/4:
    # Use orange.
    stats.fuelBar.textureRect = IntRect(left: 104, top: 0, width: 48, height: 24)
  else:
    # Use red.
    stats.fuelBar.textureRect = IntRect(left: 156, top: 0, width: 48, height: 24)

  stats.fuelBar.scale = vec2(4 / truck.fuelCapacity, 1)
  stats.fuelBars = truck.fuel

  # Clock
  stats.day =
    case level
    of 0, 1: "Mon"
    of 2: "Tue"
    of 3: "Wed"
    of 4: "Thu"
    of 5: "Fri"
    of 6: "Sat"
    of 7: "Sun"
    else: "Hol"
  stats.hour = hour

proc pendingDeliveries*(stats: Stats): int =
  result = 0
  for task in stats.tasks.deliveries:
    if not task[0]:
      result.inc()