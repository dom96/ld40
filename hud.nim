import os, math

import csfml

import consts, utils

type
  Message = ref object
    text: string
    clock: Clock
    timeout: int # ms, -1 for infinite

  DialogueMessage = ref object
    text: string
    shown: int
    clock: Clock
    onFinish: proc ()
    next: DialogueMessage

  Hud* = ref object
    currentRoute: Text
    font*: Font
    primaryMessage: Message
    secondaryMessage: Message
    dialogue: DialogueMessage

proc newHud*(): Hud =
  let font = newFont(getCurrentDir() / "assets" / "PICO-8.ttf")
  result = Hud(
    currentRoute: newText("Route: No route selected", font),
    font: font
  )
  result.currentRoute.characterSize = 14
  result.currentRoute.position = vec2(10, 10)

proc draw*(hud: Hud, target: RenderWindow) =
  template drawMessage(message: Message, isPrimary: bool) =
    let margin = (screenSize[0] div 6) +
      (if isPrimary: 0 else: screenSize[0] div 12)
    const primaryHeight = 100
    let fill = newRectangleShape(vec2(
      screenSize[0] - margin,
      if isPrimary: primaryHeight else: 50
    ))
    var fillPos = vec2(
      margin div 2,
      50
    )
    if not isPrimary and (not hud.primaryMessage.isNil):
      # Move message underneath primary message
      fillPos.y += primaryHeight + fillPos.y
    fill.position = fillPos

    # We need this so that the scaling happens from the middle.
    scaleMiddle(fill, fill.size)

    fill.fillColor = color(messageColour)
    fill.outlineColor = color(0x5f574faa)
    fill.outlineThickness = 4

    let text = newText(message.text, hud.font, 20)
    text.position = vec2(
      fillPos.x + (fill.size.x.int div 2),
      fillPos.y + (fill.size.y.int div 2),
    )
    text.origin = vec2(text.localBounds.width / 2, text.localBounds.height / 2)

    if message.timeout != -1:
      let diff = message.timeout - message.clock.elapsedTime().asMilliseconds()
      if diff <= messageDisappearTimeout:
        # Scale down the message to make it disappear.
        let scale = round(diff / messageDisappearTimeout, 1)
        fill.scale = vec2(scale, scale)
        text.scale = vec2(scale, scale)

    target.draw(fill)
    target.draw(text)

    fill.destroy()
    text.destroy()

  if not hud.primaryMessage.isNil:
    drawMessage(hud.primaryMessage, isPrimary=true)
  if not hud.secondaryMessage.isNil:
    drawMessage(hud.secondaryMessage, isPrimary=false)

  if not hud.dialogue.isNil:
    let margin = (screenSize[0] div 6)
    let fill = newRectangleShape(vec2(
      screenSize[0] - margin,
      150
    ))

    var fillPos = vec2(
      margin div 2,
      screenSize[1] - margin
    )
    fill.position = fillPos
    fill.fillColor = color(messageColour)
    fill.outlineColor = color(0x5f574faa)
    fill.outlineThickness = 4

    let text = newText(hud.dialogue.text[0 .. hud.dialogue.shown], hud.font, 20)
    text.position = vec2(
      fillPos.x + (fill.size.x.int div 2),
      fillPos.y + (fill.size.y.int div 2),
    )
    text.origin = vec2(text.localBounds.width / 2, text.localBounds.height / 2)

    target.draw(fill)
    target.draw(text)

    fill.destroy()
    text.destroy()

proc setMessage*(hud: Hud, text: string, timeout = -1, primary=true) =
  let message = Message(
    text: text,
    timeout: timeout
  )

  message.clock = newClock()
  if primary:
    hud.primaryMessage = message
  else:
    hud.secondaryMessage = message

proc removeMessage*(hud: Hud, primary: bool) =
  let message = if primary: hud.primaryMessage else: hud.secondaryMessage
  if not message.isNil:
    let diff = message.clock.elapsedTime().asMilliseconds() - messageDisappearTimeout
    # If the primary message will already expire before the messageDisappearTimeout.
    # So don't reset it.
    if diff < 0: return

    discard message.clock.restart()
    message.timeout = messageDisappearTimeout

proc printDialogue*(hud: Hud, message: string, onFinish = proc () = discard) =
  let dialogue = DialogueMessage(
    text: message,
    shown: 0,
    clock: newClock(),
    onFinish: onFinish
  )
  if hud.dialogue.isNil:
    hud.dialogue = dialogue
  else:
    # Append to the end of our queue.
    var current = hud.dialogue
    while not current.next.isNil:
      current = current.next

    current.next = dialogue

proc update*(hud: Hud) =
  # Using addr here is a bit hacky, but then again this is Ludum Dare.
  for message in [addr hud.primaryMessage, addr hud.secondaryMessage]:
    if not message[].isNil:
      if message.timeout != -1:
        if message.clock.elapsedTime().asMilliseconds() >=
            message.timeout:
          message[] = nil

  if not hud.dialogue.isNil:
    if hud.dialogue.clock.elapsedTime().asMilliseconds() >= dialogueWrite:
      discard hud.dialogue.clock.restart()
      hud.dialogue.shown.inc()
      if hud.dialogue.shown > hud.dialogue.text.len:
        hud.dialogue.shown = hud.dialogue.text.len

proc inProgress(dialogue: DialogueMessage): bool =
  return dialogue.shown != dialogue.text.len

proc select*(hud: Hud): bool =
  ## Returns whether the event was handled by the HUD.
  result = false
  if not hud.dialogue.isNil:
    if hud.dialogue.inProgress():
      hud.dialogue.shown = hud.dialogue.text.len
    else:
      hud.dialogue.onFinish()
      hud.dialogue = hud.dialogue.next
    result = true