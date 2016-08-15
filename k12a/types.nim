type
  Register* = enum
    regA
    regB
    regC
    regD
  
  Operation* = enum
    opAddsp
    opDec
    opGetsp
    opHalt
    opIn
    opInc
    opLd
    opLdd
    opLjmp
    opMov
    opOut
    opPop
    opPush
    opPutsp
    opRcall
    opRjmp
    opSkip
    opSt
    opStd
  
  Condition* = enum
    condZero
    condNegative
    condBorrow
    condOverflow
    condULT
    condULE
    condSLT
    condSLE
  
  SkipFlag* = enum
    skipImm
    skipNegate
  
  MovSrc* = enum
    msAluAB
    msAluAI
    msC
    msD
  
  AluOperation* = enum
    aluA
    aluAnd
    aluOr
    aluXor
    aluAdd
    aluSub
    aluAsr
    aluB
  
  Port* = range[0u8..7u8]
  Offset* = range[-1024i16..1023i16]
  Imm* = uint8
  
  Instruction* = uint16
  
  InvalidOperationError* = object of ValueError

proc unreachable[T](): T {.noSideEffect, raises: [].} =
  assert false, "unreachable"

proc decodeOperation*(inst: Instruction): Operation {.noSideEffect, raises: [InvalidOperationError].} =
  if   (inst and 0b1111100000000000u16) == 0b0101000000000000u16: result = opAddsp
  elif (inst and 0b1111110000000000u16) == 0b0100000000000000u16: result = opDec
  elif (inst and 0b1011110000000000u16) == 0b0000010000000000u16: result = opGetsp
  elif (inst and 0b1111100000000000u16) == 0b1111000000000000u16: result = opHalt
  elif (inst and 0b1111110000000000u16) == 0b0001000000000000u16: result = opIn
  elif (inst and 0b1111110000000000u16) == 0b0000000000000000u16: result = opInc
  elif (inst and 0b1111110000000000u16) == 0b0010000000000000u16: result = opLd
  elif (inst and 0b1111100000000000u16) == 0b0011000000000000u16: result = opLdd
  elif (inst and 0b1111110000000000u16) == 0b1110000000000000u16: result = opLjmp
  elif (inst and 0b0000100000000000u16) == 0b0000100000000000u16: result = opMov
  elif (inst and 0b1111110000000000u16) == 0b0001010000000000u16: result = opOut
  elif (inst and 0b1111110000000000u16) == 0b0010010000000000u16: result = opPop
  elif (inst and 0b1111110000000000u16) == 0b0110010000000000u16: result = opPush
  elif (inst and 0b1111110000000000u16) == 0b1110010000000000u16: result = opPutsp
  elif (inst and 0b1111100000000000u16) == 0b1101000000000000u16: result = opRcall
  elif (inst and 0b1111100000000000u16) == 0b1100000000000000u16: result = opRjmp
  elif (inst and 0b1100100000000000u16) == 0b1000000000000000u16: result = opSkip
  elif (inst and 0b1111110000000000u16) == 0b0110000000000000u16: result = opSt
  elif (inst and 0b1111100000000000u16) == 0b0111000000000000u16: result = opStd
  else:
    raise newException(InvalidOperationError, "invalid operation code")

proc decodeCondition*(inst: Instruction): Condition {.noSideEffect, raises: [].} =
  case inst and 0x0700u16
  of 0x0000u16: condZero
  of 0x0100u16: condNegative
  of 0x0200u16: condBorrow
  of 0x0300u16: condOverflow
  of 0x0400u16: condULT
  of 0x0500u16: condULE
  of 0x0600u16: condSLT
  of 0x0700u16: condSLE
  else: unreachable[Condition]()

proc decodeSkipFlags*(inst: Instruction): set[SkipFlag] {.noSideEffect, raises: [].} =
  if (inst and 0x1000u16) != 0u16:
    result.incl(skipImm)
  if (inst and 0x2000u16) != 0u16:
    result.incl(skipNegate)

proc decodeMovDest*(inst: Instruction): Register {.noSideEffect, raises: [].} =
  case inst and 0xC000u16
  of 0x0000u16: regA
  of 0x4000u16: regB
  of 0x8000u16: regC
  of 0xC000u16: regD
  else: unreachable[Register]()

proc decodeMovSrc*(inst: Instruction): MovSrc {.noSideEffect, raises: [].} =
  case inst and 0x3000u16
  of 0x0000u16: msAluAB
  of 0x1000u16: msAluAI
  of 0x2000u16: msC
  of 0x3000u16: msD
  else: unreachable[MovSrc]()

proc decodeAluOperation*(inst: Instruction): AluOperation {.noSideEffect, raises: [].} =
  case inst and 0x0700u16
  of 0x0000u16: aluA
  of 0x0100u16: aluAnd
  of 0x0200u16: aluOr
  of 0x0300u16: aluXor
  of 0x0400u16: aluAdd
  of 0x0500u16: aluSub
  of 0x0600u16: aluAsr
  of 0x0700u16: aluB
  else: unreachable[AluOperation]()

proc decodePort*(inst: Instruction): Port {.noSideEffect, raises: [].} =
  Port(inst and 0x0007u16)

proc signExtend11to16(x: uint16): uint16 {.noSideEffect, raises: [].} =
  ((x and 0x07FFu16) xor 0x0400u16) - 0x0400u16

proc decodeOffset*(inst: Instruction): Offset {.noSideEffect, raises: [].} =
  Offset(signExtend11to16(inst))

proc decodeImm*(inst: Instruction): Imm {.noSideEffect, raises: [].} =
  Imm(inst and 0x00FFu16)

proc encodeOperation*(operation: Operation): Instruction {.noSideEffect, raises: [].} =
  const lookup: array[Operation, Instruction] = [
    0b0101000000000000u16, # opAddsp
    0b0100000000000000u16, # opDec
    0b0000010000000000u16, # opGetsp
    0b1111000000000000u16, # opHalt
    0b0001000000000000u16, # opIn
    0b0000000000000000u16, # opInc
    0b0010000000000000u16, # opLd
    0b0011000000000000u16, # opLdd
    0b1110000000000000u16, # opLjmp
    0b0000100000000000u16, # opMov
    0b0001010000000000u16, # opOut
    0b0010010000000000u16, # opPop
    0b0110010000000000u16, # opPush
    0b1110010000000000u16, # opPutsp
    0b1101000000000000u16, # opRcall
    0b1100000000000000u16, # opRjmp
    0b1000000000000000u16, # opSkip
    0b0110000000000000u16, # opSt
    0b0111000000000000u16, # opStd
  ]
  lookup[operation]

proc encodeCondition*(cond: Condition): Instruction {.noSideEffect, raises: [].} =
  Instruction(ord(cond) shl 8)

proc encodeSkipFlags*(flags: set[SkipFlag]): Instruction {.noSideEffect, raises: [].} =
  if skipImm in flags:
    result = result or 0x1000u16
  if skipNegate in flags:
    result = result or 0x2000u16

proc encodeMovDest*(movDest: Register): Instruction {.noSideEffect, raises: [].} =
  Instruction(ord(movDest) shl 14)

proc encodeMovSrc*(movSrc: MovSrc): Instruction {.noSideEffect, raises: [].} =
  Instruction(ord(movSrc) shl 12)

proc encodeAluOperation*(aluOperation: AluOperation): Instruction {.noSideEffect, raises: [].} =
  Instruction(ord(aluOperation) shl 8)

proc encodePort*(port: Port): Instruction {.noSideEffect, raises: [].} =
  Instruction(port)

proc encodeOffset*(offset: Offset): Instruction {.noSideEffect, raises: [].} =
  Instruction(offset) and 0x07FFu16

proc encodeImm*(imm: Imm): Instruction {.noSideEffect, raises: [].} =
  Instruction(imm)
