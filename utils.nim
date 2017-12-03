import csfml_util, csfml

converter toCint*(x: int): cint = x.cint

proc `or`*(a, b: BitMaskU32): BitMaskU32 = BitMaskU32(uint32(a) or uint32(b))

proc `not`*(a: BitMaskU32): BitMaskU32 = BitMaskU32(not uint32(a))