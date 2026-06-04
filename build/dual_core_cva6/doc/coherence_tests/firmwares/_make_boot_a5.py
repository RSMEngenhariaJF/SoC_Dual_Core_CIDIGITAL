"""
Gera boot_a5.hex (multi-line stress) com encoding RISC-V correto.

Layout (32 instrucoes = 128 bytes):
  0x80000000-0x80000010  Setup (5 instr)
  0x80000014-0x80000044  Hart 0 (13 instr)
  0x80000048-0x80000078  Hart 1 (13 instr)
  0x8000007C             Fail spin (1 instr)

Cada hart escreve em 2 linhas de cache (espacadas em 64B) e depois le UMA
linha do outro, validando cross-tile via shadow_mem em multiplas posicoes.
"""

REGS = {'zero':0,'ra':1,'sp':2,'gp':3,'tp':4,
        't0':5,'t1':6,'t2':7,
        't3':28,'t4':29,'t5':30,'t6':31,
        'x0':0}
def R(s): return REGS[s]

def auipc(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | (R(rd) << 7) | 0x17

def addi(rd, rs1, imm12):
    return ((imm12 & 0xFFF) << 20) | (R(rs1) << 15) | (R(rd) << 7) | 0x13

def csrr(rd, csr):
    return (csr << 20) | (0b010 << 12) | (R(rd) << 7) | 0x73

def sw(rs2, rs1, imm12):
    imm = imm12 & 0xFFF
    return ((imm >> 5) << 25) | (R(rs2) << 20) | (R(rs1) << 15) | (0b010 << 12) | ((imm & 0x1F) << 7) | 0x23

def lw(rd, rs1, imm12):
    return ((imm12 & 0xFFF) << 20) | (R(rs1) << 15) | (0b010 << 12) | (R(rd) << 7) | 0x03

def bne(rs1, rs2, imm13):
    imm = imm13 & 0x1FFF
    b12   = (imm >> 12) & 1
    b10_5 = (imm >> 5)  & 0x3F
    b4_1  = (imm >> 1)  & 0xF
    b11   = (imm >> 11) & 1
    return (b12 << 31) | (b10_5 << 25) | (R(rs2) << 20) | (R(rs1) << 15) | (0b001 << 12) | (b4_1 << 8) | (b11 << 7) | 0x63

def bnez(rs1, imm13):
    return bne(rs1, 'x0', imm13)

def jal(rd, imm21):
    imm = imm21 & 0x1FFFFF
    b20    = (imm >> 20) & 1
    b10_1  = (imm >> 1)  & 0x3FF
    b11    = (imm >> 11) & 1
    b19_12 = (imm >> 12) & 0xFF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (R(rd) << 7) | 0x6F

MHARTID = 0xF14

# Calcular offsets
BASE         = 0x80000000
HART1_ADDR   = 0x80000048
HART1_OFFSET = HART1_ADDR - 0x80000010   # = 0x38 = 56
FAIL_ADDR    = 0x8000007C
BNE_H0_ADDR  = 0x80000038
BNE_H1_ADDR  = 0x8000006C
BNE_H0_OFF   = FAIL_ADDR - BNE_H0_ADDR   # = 0x44 = 68
BNE_H1_OFF   = FAIL_ADDR - BNE_H1_ADDR   # = 0x10 = 16

ins = []

# ---------------------- SETUP (5 instr) ----------------------
ins.append( (auipc('t2', 2),        "auipc t2, 2          # t2 = 0x80002000") )
ins.append( (auipc('t1', 0x10),     "auipc t1, 0x10") )
ins.append( (addi ('t1','t1',-180), "addi  t1, t1, -180   # t1 = 0x8000FF50") )
ins.append( (csrr ('t0', MHARTID),  "csrr  t0, mhartid") )
ins.append( (bnez ('t0', HART1_OFFSET), f"bnez  t0, +{HART1_OFFSET}  -> 0x{HART1_ADDR:08x}") )

# ---------------------- HART 0 (13 instr) ----------------------
ins.append( (addi('t3','x0', 0x10), "addi t3, x0, 0x10") )
ins.append( (sw  ('t3','t2', 0),    "sw t3, 0(t2)         # linha 0 idx 1024 = 0x10") )
ins.append( (addi('t3','x0', 0x11), "addi t3, x0, 0x11") )
ins.append( (sw  ('t3','t2', 64),   "sw t3, 64(t2)        # linha 1 idx 1032 = 0x11") )
ins.append( (addi('t5','x0', 200),  "addi t5, x0, 200     # delay counter") )
ins.append( (addi('t5','t5', -1),   "addi t5, t5, -1") )
ins.append( (bnez('t5', -4),        "bnez t5, -4          # delay loop") )
ins.append( (lw  ('t6','t2', 128),  "lw t6, 128(t2)       # le linha 2 (hart1)") )
ins.append( (addi('t4','x0', 0x20), "addi t4, x0, 0x20    # esperado") )
ins.append( (bne ('t6','t4', BNE_H0_OFF), f"bne t6, t4, +{BNE_H0_OFF}  -> FAIL") )
ins.append( (addi('t4','x0', 1),    "addi t4, x0, 1") )
ins.append( (sw  ('t4','t1', 0),    "sw t4, 0(t1)         # TOHOST = 1") )
ins.append( (jal ('x0', 0),         "jal x0, 0            # spin") )

# ---------------------- HART 1 (13 instr) ----------------------
ins.append( (addi('t3','x0', 0x20), "addi t3, x0, 0x20") )
ins.append( (sw  ('t3','t2', 128),  "sw t3, 128(t2)       # linha 2 = 0x20") )
ins.append( (addi('t3','x0', 0x21), "addi t3, x0, 0x21") )
ins.append( (sw  ('t3','t2', 192),  "sw t3, 192(t2)       # linha 3 = 0x21") )
ins.append( (addi('t5','x0', 100),  "addi t5, x0, 100     # delay counter") )
ins.append( (addi('t5','t5', -1),   "addi t5, t5, -1") )
ins.append( (bnez('t5', -4),        "bnez t5, -4          # delay loop") )
ins.append( (lw  ('t6','t2', 0),    "lw t6, 0(t2)         # le linha 0 (hart0)") )
ins.append( (addi('t4','x0', 0x10), "addi t4, x0, 0x10    # esperado") )
ins.append( (bne ('t6','t4', BNE_H1_OFF), f"bne t6, t4, +{BNE_H1_OFF}  -> FAIL") )
ins.append( (addi('t4','x0', 1),    "addi t4, x0, 1") )
ins.append( (sw  ('t4','t1', 0),    "sw t4, 0(t1)         # TOHOST = 1") )
ins.append( (jal ('x0', 0),         "jal x0, 0            # spin") )

# ---------------------- FAIL SPIN ----------------------
ins.append( (jal('x0', 0),          "jal x0, 0            # FAIL spin") )

# Escreve o arquivo
header = [
    "// boot_a5.hex - Multi-line stress (2 linhas por hart + read cross-tile)",
    "// Layout:  0x80002000 idx 1024  linha 0 (hart 0 -> 0x10)",
    "//          0x80002040 idx 1032  linha 1 (hart 0 -> 0x11)",
    "//          0x80002080 idx 1040  linha 2 (hart 1 -> 0x20)",
    "//          0x800020C0 idx 1048  linha 3 (hart 1 -> 0x21)",
    "// Hart 0 le linha 2 (hart1 escreveu); hart 1 le linha 0 (hart0 escreveu).",
    "//",
]

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_a5.hex', 'w') as f:
    for line in header:
        f.write(line + "\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"OK - {len(ins)} instrucoes (esperado 32)")
print(f"Hart1 starts at 0x{HART1_ADDR:08X}, fail at 0x{FAIL_ADDR:08X}")
