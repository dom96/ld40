import csfml

import consts

type
  Camera* = ref object
    view*: View
    clock: Clock # for smooth camera movement
    movementStart: Vector2f
    currentTarget: Vector2f

proc newCamera*(): Camera =
  result = Camera(
    view: newView()
  )

  result.view.zoom(0.5)

proc moveTo*(camera: Camera, vec: Vector2f, smooth=false) =
  if smooth:
    camera.clock = newClock()
    camera.movementStart = camera.view.center
    camera.currentTarget = vec
  else:
    camera.view.center = vec

proc moveBy*(camera: Camera, vec: Vector2f) =
  camera.view.move(vec)

proc update*(camera: Camera) =
  if not camera.clock.isNil:
    let scale = camera.clock.elapsedTime().asMilliseconds() / cameraScrollSpeed
    if scale >= 1:
      # Scrolling finished.
      camera.view.center = camera.currentTarget
      destroy(camera.clock)
      camera.clock = nil
    else:
      let diff = camera.currentTarget - camera.movementStart
      camera.view.center = camera.movementStart + (diff*scale)