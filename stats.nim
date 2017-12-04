import os

import csfml

import utils, consts, truck

type
  Tasks* = ref object
    deliveries: seq[(bool, MapStop)]

  Stats* = ref object
    panel: Texture
    fuel: Texture
    xOffset: float # Current x offset (used for showing the panel)
    shown: bool
    smoothToggleClock: Clock
    fuelBar: Sprite
    fuelBars: int

const maxOffset = 256

proc newStats*(): Stats =
  result = Stats(
    panel: newTexture(getCurrentDir() / "assets" / "stats.png"),
    fuel: newTexture(getCurrentDir() / "assets" / "fuel_bars.png"),
  )
  result.fuelBar = newSprite(result.fuel)

proc draw*(stats: Stats, target: RenderWindow) =
  let panel = newSprite(stats.panel)
  panel.position = vec2((-stats.panel.size.x).float + 52.0 + stats.xOffset, 50)
  target.draw(panel)

  destroy(panel)

  for i in 0..<stats.fuelBars:
    stats.fuelBar.position = vec2(
      panel.position.x + (24 + float(50*stats.fuelBar.scale.x*i.float)),
      panel.position.y + 18
    )
    target.draw(stats.fuelBar)

proc toggle*(stats: Stats) =
  stats.shown = not stats.shown
  stats.smoothToggleClock = newClock()

  discard stats.smoothToggleClock.restart()

proc update*(stats: Stats, truck: Truck) =
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