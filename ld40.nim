import nico
import math

import vec, utils

proc gameInit() =
  discard

proc gameUpdate(dt: float) =
  discard

proc gameDraw() =
  setColor(1)
  rectfill(0, 0, screenWidth, screenHeight)

  # Show pallette
  for i in 0..<16:
    setColor(i)
    fill(Rect(pos: (i*8, 50), size: (2, 4)))

# initialization
nico.init("nico", "test")

# we want a fixed sized screen with perfect square pixels
fixedSize(true)
integerScale(true)

# create the window
nico.createWindow("LD40", 128, 128, 4)

# start, say which functions to use for init, update and draw
nico.run(gameInit, gameUpdate, gameDraw)
