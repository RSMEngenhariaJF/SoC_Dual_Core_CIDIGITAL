#!/usr/bin/env python3
"""
build_rw_test.py
Gera boot_rw.hex -- teste de escrita (SW) com leituras de instrucao via I-cache.

Limitacao xsim 2025.1: instrucoes LW/LD que ativam a D-cache travam o kernel
do simulador (mesmo bug de struct empacotado confirmado em store_buffer.sv).
Operandos sao carregados por ADDI (imediato); os SW stores sao visíveis via
o monitor SB0_STORE/SB1_STORE em uvmt_opc_dut_wrap.sv, e as leituras de
instrucao sao visíveis como AXI_AR INST no canal AXI4.

Hart 0: a=10, b=6  -> ADD=16, SUB=4,  MUL=60, AND=2,  OR=14
Hart 1: a=9,  b=3  -> ADD=12, SUB=6,  MUL=27, AND=1,  OR=11

Resultados escritos via SW em BASE+0x1000:
  Hart 0: ADD/SUB/MUL/AND/OR em 0x80001000..0x80001010
  Hart 1: ADD/SUB/MUL/AND/OR em 0x80001020..0x80001030

Layout de codigo (BASE=0x80000000):
  0x000 _start      csrr a0, mhartid / bnez hart1_init
  0x008 hart0_init  addi a1=10 / addi a2=6 / jal compute
  0x014 hart1_init  addi a1=9  / addi a2=3  (fall-through)
  0x01C compute     add/sub/mul/and/or / bnez store_h1
  0x034 store_h0    auipc+addi + 5xsw / jal verify_h0
  0x054 store_h1    auipc+addi + 5xsw / jal verify_h1
  0x074 verify_h0   5x(addi+bne) + jal pass
  0x0A0 verify_h1   5x(addi+bne) + jal pass
  0x0CC pass        bnez halt / auipc+addi+addi+sw (GOOD TRAP)
  0x0E0 halt        jal x0, 0
  0x0E4 fail        auipc+addi+addi+sw (BAD TRAP) / jal x0, 0
"""

import os

BASE        = 0x80000000
TOHOST_PASS = 0x8000_FF50
TOHOST_FAIL = 0x8000_FF58
MEM_WORDS   = 1040   # cobre codigo (0..0xFF) e area de dados (0x1000..0x103F)

# ---------------------------------------------------------------------------
# Funcoes de codificacao RISC-V
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
    imm &= 0x1FFE
    b12, b10_5, b4_1, b11 = (imm>>12)&1, (imm>>5)&0x3F, (imm>>1)&0xF, (imm>>11)&1
    return u32((b12<<31)|(b10_5<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(b4_1<<8)|(b11<<7)|op)

def U(imm20, rd, op):
    return u32(((imm20 & 0xFFFFF)<<12)|(rd<<7)|op)

def J(imm, rd, op):
    imm &= 0x1F_FFFE
    b20, b10_1, b11, b19_12 = (imm>>20)&1, (imm>>1)&0x3FF, (imm>>11)&1, (imm>>12)&0xFF
    return u32((b20<<31)|(b19_12<<12)|(b11<<20)|(b10_1<<21)|(rd<<7)|op)

# Registradores
X0=0; A0=10; A1=11; A2=12; A3=13; A4=14; A5=15; A6=16; A7=17
T0=5; T1=6

# Opcodes
OP_IMM, OP_REG, OP_BRANCH = 0x13, 0x33, 0x63
OP_JAL, OP_AUIPC, OP_STORE, OP_SYSTEM = 0x6F, 0x17, 0x23, 0x73
MHARTID = 0xF14

# ---------------------------------------------------------------------------
# Rotulos (offsets a partir de BASE)
# ---------------------------------------------------------------------------
L = dict(
    start      = 0x000,
    hart0_init = 0x008,
    hart1_init = 0x014,
    compute    = 0x01C,
    store_h0   = 0x034,
    store_h1   = 0x054,
    verify_h0  = 0x074,
    verify_h1  = 0x0A0,
    pass_      = 0x0CC,
    halt       = 0x0E0,
    fail       = 0x0E4,
)

# ---------------------------------------------------------------------------
# Montagem
# ---------------------------------------------------------------------------
prog = []

def emit(off, enc, mnem=""):
    prog.append((off, enc & 0xFFFF_FFFF, mnem))

# ---- _start ----
emit(0x000, I(MHARTID, X0, 0b010, A0, OP_SYSTEM),                "csrr  a0, mhartid")
emit(0x004, B(L['hart1_init']-0x004, X0, A0, 0b001, OP_BRANCH),  "bnez  a0, hart1_init")

# ---- hart0_init: carrega a1=10, a2=6 por imediato ----
emit(0x008, I(10, X0, 0b000, A1, OP_IMM),                        "addi  a1, x0, 10")
emit(0x00C, I( 6, X0, 0b000, A2, OP_IMM),                        "addi  a2, x0,  6")
emit(0x010, J(L['compute']-0x010, X0, OP_JAL),                   "jal   x0, compute")

# ---- hart1_init: carrega a1=9, a2=3 por imediato ----
emit(0x014, I( 9, X0, 0b000, A1, OP_IMM),                        "addi  a1, x0,  9")
emit(0x018, I( 3, X0, 0b000, A2, OP_IMM),                        "addi  a2, x0,  3")

# ---- compute ----
emit(0x01C, R(0b0000000, A2, A1, 0b000, A3, OP_REG),              "add   a3, a1, a2")
emit(0x020, R(0b0100000, A2, A1, 0b000, A4, OP_REG),              "sub   a4, a1, a2")
emit(0x024, R(0b0000001, A2, A1, 0b000, A5, OP_REG),              "mul   a5, a1, a2  # M-ext")
emit(0x028, R(0b0000000, A2, A1, 0b111, A6, OP_REG),              "and   a6, a1, a2")
emit(0x02C, R(0b0000000, A2, A1, 0b110, A7, OP_REG),              "or    a7, a1, a2")
emit(0x030, B(L['store_h1']-0x030, X0, A0, 0b001, OP_BRANCH),    "bnez  a0, store_h1")

# ---- store_h0: grava resultados em BASE+0x1000 ----
# auipc t0,1 @ 0x034 -> t0 = 0x80001034;  addi -52 -> t0 = 0x80001000
emit(0x034, U(1, T0, OP_AUIPC),                                   "auipc t0, 1")
emit(0x038, I(-52, T0, 0b000, T0, OP_IMM),                       "addi  t0, t0, -52  # t0->0x80001000")
emit(0x03C, S( 0, A3, T0, 0b010, OP_STORE),                      "sw    a3,  0(t0)   # ADD=16")
emit(0x040, S( 4, A4, T0, 0b010, OP_STORE),                      "sw    a4,  4(t0)   # SUB=4")
emit(0x044, S( 8, A5, T0, 0b010, OP_STORE),                      "sw    a5,  8(t0)   # MUL=60")
emit(0x048, S(12, A6, T0, 0b010, OP_STORE),                      "sw    a6, 12(t0)   # AND=2")
emit(0x04C, S(16, A7, T0, 0b010, OP_STORE),                      "sw    a7, 16(t0)   # OR=14")
emit(0x050, J(L['verify_h0']-0x050, X0, OP_JAL),                 "jal   x0, verify_h0")

# ---- store_h1: grava resultados em BASE+0x1020 ----
# auipc t0,1 @ 0x054 -> t0 = 0x80001054;  addi -52 -> t0 = 0x80001020
emit(0x054, U(1, T0, OP_AUIPC),                                   "auipc t0, 1")
emit(0x058, I(-52, T0, 0b000, T0, OP_IMM),                       "addi  t0, t0, -52  # t0->0x80001020")
emit(0x05C, S( 0, A3, T0, 0b010, OP_STORE),                      "sw    a3,  0(t0)   # ADD=12")
emit(0x060, S( 4, A4, T0, 0b010, OP_STORE),                      "sw    a4,  4(t0)   # SUB=6")
emit(0x064, S( 8, A5, T0, 0b010, OP_STORE),                      "sw    a5,  8(t0)   # MUL=27")
emit(0x068, S(12, A6, T0, 0b010, OP_STORE),                      "sw    a6, 12(t0)   # AND=1")
emit(0x06C, S(16, A7, T0, 0b010, OP_STORE),                      "sw    a7, 16(t0)   # OR=11")
emit(0x070, J(L['verify_h1']-0x070, X0, OP_JAL),                 "jal   x0, verify_h1")

# ---- verify_h0 (a=10, b=6 -> ADD=16, SUB=4, MUL=60, AND=2, OR=14) ----
checks_h0 = [(A3,16),(A4,4),(A5,60),(A6,2),(A7,14)]
for i, (reg, val) in enumerate(checks_h0):
    aoff = L['verify_h0'] + i*8
    boff = aoff + 4
    emit(aoff, I(val, X0, 0b000, T0, OP_IMM),                    f"addi  t0, x0, {val}")
    emit(boff, B(L['fail']-boff, T0, reg, 0b001, OP_BRANCH),     f"bne   a{reg-10}, t0, fail")
emit(L['verify_h0']+40, J(L['pass_']-L['verify_h0']-40, X0, OP_JAL), "jal   x0, pass")

# ---- verify_h1 (a=9, b=3 -> ADD=12, SUB=6, MUL=27, AND=1, OR=11) ----
checks_h1 = [(A3,12),(A4,6),(A5,27),(A6,1),(A7,11)]
for i, (reg, val) in enumerate(checks_h1):
    aoff = L['verify_h1'] + i*8
    boff = aoff + 4
    emit(aoff, I(val, X0, 0b000, T0, OP_IMM),                    f"addi  t0, x0, {val}")
    emit(boff, B(L['fail']-boff, T0, reg, 0b001, OP_BRANCH),     f"bne   a{reg-10}, t0, fail")
emit(L['verify_h1']+40, J(L['pass_']-L['verify_h1']-40, X0, OP_JAL), "jal   x0, pass")

# ---- pass ----
# auipc t1, 0x10 @ 0x0D0 -> t1 = 0x800100D0;  addi -384 -> t1 = 0x8000FF50
auipc_pass_pc = BASE + L['pass_'] + 4   # 0x800000D0
t1_pass       = auipc_pass_pc + (0x10 << 12)  # 0x800100D0
imm_p         = TOHOST_PASS - t1_pass   # -384

emit(L['pass_'],    B(L['halt']-L['pass_'], X0, A0, 0b001, OP_BRANCH), "bnez  a0, halt")
emit(L['pass_']+4,  U(0x10, T1, OP_AUIPC),                             "auipc t1, 0x10")
emit(L['pass_']+8,  I(imm_p, T1, 0b000, T1, OP_IMM),                  f"addi  t1, t1, {imm_p}  # ->0x{TOHOST_PASS:08X}")
emit(L['pass_']+12, I(1, X0, 0b000, T0, OP_IMM),                      "addi  t0, x0, 1")
emit(L['pass_']+16, S(0, T0, T1, 0b010, OP_STORE),                    "sw    t0, 0(t1)  # GOOD TRAP")

# ---- halt ----
emit(L['halt'], J(0, X0, OP_JAL),                                      "jal   x0, 0  # loop")

# ---- fail ----
# auipc t1, 0x10 @ 0x0E4 -> t1 = 0x800100E4;  addi -396 -> t1 = 0x8000FF58
auipc_fail_pc = BASE + L['fail']        # 0x800000E4
t1_fail       = auipc_fail_pc + (0x10 << 12)  # 0x800100E4
imm_f         = TOHOST_FAIL - t1_fail   # -396

emit(L['fail'],    U(0x10, T1, OP_AUIPC),                              "auipc t1, 0x10")
emit(L['fail']+4,  I(imm_f, T1, 0b000, T1, OP_IMM),                   f"addi  t1, t1, {imm_f}  # ->0x{TOHOST_FAIL:08X}")
emit(L['fail']+8,  I(2, X0, 0b000, T0, OP_IMM),                      "addi  t0, x0, 2  # BAD TRAP")
emit(L['fail']+12, S(0, T0, T1, 0b010, OP_STORE),                     "sw    t0, 0(t1)  # BAD TRAP")
emit(L['fail']+16, J(0, X0, OP_JAL),                                   "jal   x0, 0  # loop")

# ---------------------------------------------------------------------------
# Verificacao de sanidade
# ---------------------------------------------------------------------------
prog_sorted = sorted(prog, key=lambda x: x[0])

print("=" * 60)
print("  Dual-Core CVA6 Store Test -- Layout de Instrucoes")
print("  (Operandos por ADDI; resultados gravados via SW)")
print("=" * 60)
for off, enc, mnem in prog_sorted:
    print(f"  [BASE+0x{off:04X}]  0x{enc:08X}   {mnem}")

print()
print("Resultados esperados:")
for hart, a, b in [(0,10,6),(1,9,3)]:
    print(f"  Hart {hart}: a={a}, b={b} -> "
          f"ADD={a+b}, SUB={a-b}, MUL={a*b}, AND={a&b}, OR={a|b}")

print()
print("Destinos de SW em BASE+0x1000:")
print("  Hart 0: 0x80001000..0x80001010 (ADD/SUB/MUL/AND/OR)")
print("  Hart 1: 0x80001020..0x80001030 (ADD/SUB/MUL/AND/OR)")
print()
print(f"TOHOST_PASS = 0x{TOHOST_PASS:08X}  (escreve 1 -> GOOD_TRAP)")
print(f"TOHOST_FAIL = 0x{TOHOST_FAIL:08X}  (escreve 2 -> BAD_TRAP)")
print(f"imm_pass = {imm_p}  imm_fail = {imm_f}")
print(f"Verif t1_pass: 0x{auipc_pass_pc:08X} + 0x10000 + ({imm_p}) = "
      f"0x{(auipc_pass_pc + 0x10000 + imm_p) & 0xFFFFFFFF:08X}")
print(f"Verif t1_fail: 0x{auipc_fail_pc:08X} + 0x10000 + ({imm_f}) = "
      f"0x{(auipc_fail_pc + 0x10000 + imm_f) & 0xFFFFFFFF:08X}")

# ---------------------------------------------------------------------------
# Geracao do arquivo hex
# ---------------------------------------------------------------------------
mem = [0x0000_006F] * MEM_WORDS   # inicializa com jal x0,0

for off, enc, _ in prog:
    idx = off // 4
    assert idx < MEM_WORDS, f"Offset 0x{off:X} fora da memoria ({MEM_WORDS} words)"
    mem[idx] = enc

# Grava em doc/ e tb/
script_dir = os.path.dirname(os.path.abspath(__file__))
tb_dir = os.path.normpath(os.path.join(
    script_dir, "../openpiton/build/dual_core_cva6/tb"))

out_paths = [
    os.path.join(script_dir, "boot_rw.hex"),
    os.path.join(tb_dir,     "boot_rw.hex"),
]

for out_path in out_paths:
    with open(out_path, "w") as f:
        for word in mem:
            f.write(f"{word:08X}\n")
    print(f"Gerado: {out_path}")

print(f"Tamanho: {MEM_WORDS} words = {MEM_WORDS*4} bytes")
