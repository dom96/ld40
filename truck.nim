import csfml

import utils
type
  Truck* = ref object
    fuelCapacity*: int
    fuel*: int
    currentStop*: MapStop
    pos*: Vector2f
    dir*: Direction
    truckTexture*: array[Direction, Texture]
    travellingTo*: Neighbour
    roadTravelClock*: Clock