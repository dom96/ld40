import nico
import vec

type
  Rect* = object
    pos*: Vec2i
    size*: Vec2i

proc fill*(rect: Rect) =
  rectFill(rect.pos.x, rect.pos.y, rect.pos.x + rect.size.x,
           rect.pos.y + rect.size.y)