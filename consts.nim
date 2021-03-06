const screenSize* = (1024, 1024)
when defined(windows) or defined(linux):
  const globalScale* = 0.5
else:
  const globalScale* = 1
const mapStopSize* = (32, 32)
const messageDisappearTimeout* = 700 # ms
const textPulse* = 800 # ms
const dialogueWrite* = 100 # ms
const messageColour* = 0x5f574fff
const cameraScrollSpeed* = 1000 # ms
const truckSpeed* = 1200 # ms # TODO: replace this

const statsToggleSpeed* = 700 # ms

const nextLevelFadeSpeed* = 1500 # ms
const waves* = 800 # ms