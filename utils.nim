import csfml_util, csfml

import math
import consts

type
  Direction* = enum
    North, East, South, West

  Road* = tuple
    start, finish: Vector2i
    dir: Direction

  Neighbour* = tuple
    stop: MapStop
    fuelCost: int
    roads: seq[Road]

  MapStop* = ref object
    name*: string
    pos*: Vector2i # Relative to map
    neighbours*: seq[Neighbour]
    isDepot*: bool
    isSelected*: bool
    isFuelStation*: bool


converter toCint*(x: int): cint = x.cint

proc `or`*(a, b: BitMaskU32): BitMaskU32 = BitMaskU32(uint32(a) or uint32(b))

proc `not`*(a: BitMaskU32): BitMaskU32 = BitMaskU32(not uint32(a))

proc rfind*[T](a: seq[T], item: T): int =
  result = -1
  for i in countdown(a.len-1, 0):
    if a[i] == item:
      return i

proc scaleMiddle*[T](a: T, size: Vector2f) =
  a.origin = vec2(size.x / 2, size.y / 2)
  a.position = vec2(a.position.x + a.origin.x, a.position.y + a.origin.y)

proc length*(a: Vector2i | Vector2f): float =
  return sqrt(float(a.x*a.x + a.y*a.y))

proc drawScaled*[T](target: RenderWindow, obj: T) =
  let original = obj.scale
  let position = obj.position
  obj.scale = obj.scale * globalScale
  obj.position = position * globalScale
  target.draw(obj)
  obj.scale = original
  obj.position = position