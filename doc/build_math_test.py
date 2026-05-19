#!/usr/bin/env python3
"""
build_math_test.py
Gera boot_math.hex — teste de operações matemáticas nos dois núcleos CVA6.

Programa (RV64GC, carregado em 0x80000000):
  Ambos os harts lêem mhartid (CSR 0xF14) e executam o mesmo código
  com operandos distintos:
    Hart 0: a=10, b=6  -> ADD=16, SUB=4, MUL=60, AND=2, OR=14
    Hart 1: a=9,  b=3  -> ADD=12, SUB=6, MUL=27, AND=1, OR=11

  Após verificação:
    PASS -> Hart 0 escreve 1 em TOHOST_PASS (0x8000_FF50) -> GOOD_TRAP
    FAIL -> Hart 0 escreve 2 em TOHOST_FAIL (0x8000_FF58) -> BAD_TRAP
    Hart 1 entra em loop infinito em ambos os casos.

Layout de memória (offsets relativos a BASE=0x80000000):
  0x00  _start      csrr a0, mhartid
  0x04              bnez a0, hart1_init
  0x08  hart0_init  addi a1,x0,10 / addi a2,x0,6 / jal compute
  0x14  hart1_init  addi a1,x0,9  / addi a2,x0,3
  0x1C  compute     add/sub/mul/and/or a3-a7, bnez a0,verify_h1
  0x34  verify_h0   5×(addi t0,imm + bne reg,t0,fail) + jal pass
  0x60  verify_h1   5×(addi t0,imm + bne reg,t0,fail) + jal pass
  0x8C  pass        bnez a0,halt / auipc+addi+sw(tohost) / fall-through
  0xA0  halt        jal x0,0  (loop infinito — ambos os harts terminam aqui)
  0xA4  fail        auipc+addi+sw(tohost_fail) / jal x0,0
"""

import os, sys

BASE         = 0x80000000
TOHOST_PASS  = 0x8000_FF50
TOHOST_FAIL  = 0x8000_FF58
MEM_WORDS    = 80           # tamanho mínimo do hex de saída (palavras)

# ---------------------------------------------------------------------------
# Funções de codificação RISC-V
# ---------------------------------------------------------------------------
def u32(v):
    return int(v) & 0xFFFF_FFFF

def R(f7, rs2, rs1, f3, rd, op):
    return u32((f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op)

def I(imm, rs1, f3, rd, op):
    return u32(((imm & 0xFFF)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op)

def S(imm, rs2, rs1, f3, op):
    imm &= 0xFFF
    return u32(((imm>>5)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1F)<<7)|op)

def B(imm, rs2, rs1, f3, op):
    """B-type: imm é o offset em bytes (deve ser múltiplo de 2)."""
    imm &= 0x1FFE                          # bits [12:1], bit-0 sempre 0
    b12, b10_5, b4_1, b11 = (imm>>12)&1, (imm>>5)&0x3F, (imm>>1)&0xF, (imm>>11)&1
    return u32((b12<<31)|(b10_5<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(b4_1<<8)|(b11<<7)|op)

def U(imm20, rd, op):
    return u32(((imm20 & 0xFFFFF)<<12)|(rd<<7)|op)

def J(imm, rd, op):
    """J-type: imm é o offset em bytes (deve ser múltiplo de 2)."""
    imm &= 0x1F_FFFE                       # bits [20:1], bit-0 sempre 0
    b20, b10_1, b11, b19_12 = (imm>>20)&1, (imm>>1)&0x3FF, (imm>>11)&1, (imm>>12)&0xFF
    return u32((b20<<31)|(b19_12<<12)|(b11<<20)|(b10_1<<21)|(rd<<7)|op)

# Registradores
X0=0; A0=10; A1=11; A2=12; A3=13; A4=14; A5=15; A6=16; A7=17
T0=5; T1=6

# Opcodes / funct
OP_IMM, OP_REG, OP_BRANCH = 0x13, 0x33, 0x63
OP_JAL, OP_AUIPC, OP_STORE, OP_SYSTEM = 0x6F, 0x17, 0x23, 0x73
MHARTID = 0xF14

# ---------------------------------------------------------------------------
# Rótulos (offsets a partir de BASE)
# ---------------------------------------------------------------------------
L = dict(
    start      = 0x00,
    hart0_init = 0x08,
    hart1_init = 0x14,
    compute    = 0x1C,
    verify_h0  = 0x34,
    verify_h1  = 0x60,
    pass_      = 0x8C,
    halt       = 0xA0,
    fail       = 0xA4,
)

# ---------------------------------------------------------------------------
# Montagem
# ---------------------------------------------------------------------------
prog = []   # lista de (offset, encoding, mnemônico)

def emit(off, enc, mnem=""):
    prog.append((off, enc & 0xFFFF_FFFF, mnem))

# ---- _start ----
emit(0x00, I(MHARTID, X0, 0b010, A0, OP_SYSTEM),         "csrr  a0, mhartid")
emit(0x04, B(L['hart1_init']-0x04, X0, A0, 0b001, OP_BRANCH), "bnez  a0, hart1_init")

# ---- hart0_init ----
emit(0x08, I(10, X0, 0b000, A1, OP_IMM),                 "addi  a1, x0, 10")
emit(0x0C, I( 6, X0, 0b000, A2, OP_IMM),                 "addi  a2, x0,  6")
emit(0x10, J(L['compute']-0x10, X0, OP_JAL),             "jal   x0, compute")

# ---- hart1_init ----
emit(0x14, I( 9, X0, 0b000, A1, OP_IMM),                 "addi  a1, x0,  9")
emit(0x18, I( 3, X0, 0b000, A2, OP_IMM),                 "addi  a2, x0,  3")

# ---- compute ----
emit(0x1C, R(0b0000000, A2, A1, 0b000, A3, OP_REG),      "add   a3, a1, a2")
emit(0x20, R(0b0100000, A2, A1, 0b000, A4, OP_REG),      "sub   a4, a1, a2")
emit(0x24, R(0b0000001, A2, A1, 0b000, A5, OP_REG),      "mul   a5, a1, a2   # M-ext")
emit(0x28, R(0b0000000, A2, A1, 0b111, A6, OP_REG),      "and   a6, a1, a2")
emit(0x2C, R(0b0000000, A2, A1, 0b110, A7, OP_REG),      "or    a7, a1, a2")
emit(0x30, B(L['verify_h1']-0x30, X0, A0, 0b001, OP_BRANCH), "bnez  a0, verify_h1")

# ---- verify_h0 (a=10, b=6 -> ADD=16, SUB=4, MUL=60, AND=2, OR=14) ----
checks_h0 = [(A3,16), (A4,4), (A5,60), (A6,2), (A7,14)]
for i, (reg, val) in enumerate(checks_h0):
    addi_off = L['verify_h0'] + i*8
    bne_off  = addi_off + 4
    emit(addi_off, I(val, X0, 0b000, T0, OP_IMM),        f"addi  t0, x0, {val}")
    emit(bne_off,  B(L['fail']-bne_off, T0, reg, 0b001, OP_BRANCH), f"bne   a{reg-10}, t0, fail")
emit(L['verify_h0']+40, J(L['pass_']-L['verify_h0']-40, X0, OP_JAL), "jal   x0, pass")

# ---- verify_h1 (a=9, b=3 -> ADD=12, SUB=6, MUL=27, AND=1, OR=11) ----
checks_h1 = [(A3,12), (A4,6), (A5,27), (A6,1), (A7,11)]
for i, (reg, val) in enumerate(checks_h1):
    addi_off = L['verify_h1'] + i*8
    bne_off  = addi_off + 4
    emit(addi_off, I(val, X0, 0b000, T0, OP_IMM),        f"addi  t0, x0, {val}")
    emit(bne_off,  B(L['fail']-bne_off, T0, reg, 0b001, OP_BRANCH), f"bne   a{reg-10}, t0, fail")
emit(L['verify_h1']+40, J(L['pass_']-L['verify_h1']-40, X0, OP_JAL), "jal   x0, pass")

# ---- pass ----
# AUIPC em 0x80000090 -> t1 = 0x80010090 -> +imm = 0x8000FF50
auipc_pass_abs = BASE + L['pass_'] + 4        # 0x80000090
t1_pass        = auipc_pass_abs + (0x10 << 12) # 0x80010090
imm_p          = TOHOST_PASS - t1_pass         # -320
emit(L['pass_'],   B(L['halt']-L['pass_'], X0, A0, 0b001, OP_BRANCH), "bnez  a0, halt")
emit(L['pass_']+4, U(0x10, T1, OP_AUIPC),                             "auipc t1, 0x10")
emit(L['pass_']+8, I(imm_p, T1, 0b000, T1, OP_IMM),                  f"addi  t1, t1, {imm_p}  # ->0x{TOHOST_PASS:08X}")
emit(L['pass_']+12, I(1, X0, 0b000, T0, OP_IMM),                     "addi  t0, x0, 1")
emit(L['pass_']+16, S(0, T0, T1, 0b010, OP_STORE),                   "sw    t0, 0(t1)  # GOOD TRAP")

# ---- halt (loop infinito — ambos os harts terminam aqui) ----
emit(L['halt'], J(0, X0, OP_JAL),                                     "jal   x0, 0  # loop")

# ---- fail ----
# AUIPC em 0x800000A4 -> t1 = 0x800100A4 -> +imm = 0x8000FF58
auipc_fail_abs = BASE + L['fail']               # 0x800000A4
t1_fail        = auipc_fail_abs + (0x10 << 12)  # 0x800100A4
imm_f          = TOHOST_FAIL - t1_fail           # -332
emit(L['fail'],    U(0x10, T1, OP_AUIPC),                             "auipc t1, 0x10")
emit(L['fail']+4,  I(imm_f, T1, 0b000, T1, OP_IMM),                  f"addi  t1, t1, {imm_f}  # ->0x{TOHOST_FAIL:08X}")
emit(L['fail']+8,  I(2, X0, 0b000, T0, OP_IMM),                      "addi  t0, x0, 2  # BAD TRAP code")
emit(L['fail']+12, S(0, T0, T1, 0b010, OP_STORE),                    "sw    t0, 0(t1)  # BAD TRAP")
emit(L['fail']+16, J(0, X0, OP_JAL),                                  "jal   x0, 0  # loop")

# ---------------------------------------------------------------------------
# Verificação de sanidade
# ---------------------------------------------------------------------------
prog_sorted = sorted(prog, key=lambda x: x[0])

print("=" * 60)
print("  Dual-Core CVA6 Math Test -- Layout de Instrucoes")
print("=" * 60)
for off, enc, mnem in prog_sorted:
    print(f"  [BASE+0x{off:04X}]  0x{enc:08X}   {mnem}")

print()
print("Resultados esperados:")
for hart, a, b in [(0,10,6),(1,9,3)]:
    print(f"  Hart {hart}: a={a}, b={b} -> "
          f"ADD={a+b}, SUB={a-b}, MUL={a*b}, AND={a&b}, OR={a|b}")

print()
print(f"TOHOST_PASS = 0x{TOHOST_PASS:08X}  (escreve 1 -> GOOD_TRAP)")
print(f"TOHOST_FAIL = 0x{TOHOST_FAIL:08X}  (escreve 2 -> BAD_TRAP)")
print(f"imm_pass = {imm_p}  imm_fail = {imm_f}")
print(f"Verif t1_pass: 0x{BASE+L['pass_']+4:08X} + 0x10000 + {imm_p} = "
      f"0x{(BASE+L['pass_']+4 + 0x10000 + imm_p) & 0xFFFFFFFF:08X}")
print(f"Verif t1_fail: 0x{auipc_fail_abs:08X} + 0x10000 + {imm_f} = "
      f"0x{(auipc_fail_abs + 0x10000 + imm_f) & 0xFFFFFFFF:08X}")

# ---------------------------------------------------------------------------
# Geração do arquivo hex
# ---------------------------------------------------------------------------
# Inicializa memória com jal x0,0 (loop seguro)
mem = [0x0000_006F] * MEM_WORDS
for off, enc, _ in prog:
    idx = off // 4
    assert idx < MEM_WORDS, f"Offset 0x{off:X} fora da memória ({MEM_WORDS} words)"
    mem[idx] = enc

out_dir  = os.path.dirname(os.path.abspath(__file__))
out_path = os.path.join(out_dir, "boot_math.hex")
with open(out_path, "w") as f:
    for word in mem:
        f.write(f"{word:08X}\n")

print()
print(f"Gerado: {out_path}")
print(f"Tamanho: {MEM_WORDS} words = {MEM_WORDS*4} bytes")
