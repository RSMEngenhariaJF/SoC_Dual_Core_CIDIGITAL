"""
Gera boot_e6.hex - FPU basica (fadd, fmul, fdiv).

Habilita mstatus.FS=01 (Initial) via csrrs e exercita o pipeline FP da
CVA6 com valores que produzem resultados exatos em IEEE 754 binary32
(potencias de 2), evitando questoes de arredondamento.

Hart 0:  fadd.s  1.0 + 2.0 == 3.0   (0x3F800000 + 0x40000000 = 0x40400000)
Hart 1:  fmul.s  2.0 * 2.0 == 4.0   (0x40000000 * 0x40000000 = 0x40800000)
         fdiv.s  4.0 / 2.0 == 2.0   (0x40800000 / 0x40000000 = 0x40000000)

Constantes carregadas via LUI (sem load de memoria, que crasha xsim).
Move int<->float via fmv.w.x / fmv.x.w.
"""

REGS = {'zero':0,'ra':1,'sp':2,'gp':3,'tp':4,
        't0':5,'t1':6,'t2':7,
        's0':8,'s1':9,
        't3':28,'t4':29,'t5':30,'t6':31,
        'x0':0,
        'f0':0,'f1':1,'f2':2,'f3':3}
def R(s): return REGS[s]

def auipc(rd, imm20): return ((imm20&0xFFFFF)<<12)|(R(rd)<<7)|0x17
def lui  (rd, imm20): return ((imm20&0xFFFFF)<<12)|(R(rd)<<7)|0x37
def addi(rd, rs1, imm12): return ((imm12&0xFFF)<<20)|(R(rs1)<<15)|(R(rd)<<7)|0x13
def csrr(rd, csr): return (csr<<20)|(0b010<<12)|(R(rd)<<7)|0x73
def csrrs(rd, csr, rs1): return (csr<<20)|(R(rs1)<<15)|(0b010<<12)|(R(rd)<<7)|0x73
def sw(rs2, rs1, imm12):
    imm = imm12 & 0xFFF
    return ((imm>>5)<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b010<<12)|((imm&0x1F)<<7)|0x23
def bne(rs1, rs2, imm13):
    imm = imm13 & 0x1FFF
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b001<<12)|(b4_1<<8)|(b11<<7)|0x63
def bnez(rs1, imm13): return bne(rs1, 'x0', imm13)
def jal(rd, imm21):
    imm = imm21 & 0x1FFFFF
    b20=(imm>>20)&1; b10_1=(imm>>1)&0x3FF; b11=(imm>>11)&1; b19_12=(imm>>12)&0xFF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(R(rd)<<7)|0x6F

# FP encodings - opcode 0x53 (1010011), rm=000 (RNE)
def _fop(funct7, rs2, rs1, rm, rd):
    return (funct7<<25)|(rs2<<20)|(R(rs1)<<15)|(rm<<12)|(R(rd)<<7)|0x53

def fmv_w_x(frd, rs1): return _fop(0b1111000, 0, rs1, 0b000, frd)
def fmv_x_w(rd, frs1): return (0b1110000<<25)|(0<<20)|(R(frs1)<<15)|(0b000<<12)|(R(rd)<<7)|0x53
def fadd_s (frd, frs1, frs2): return _fop(0b0000000, R(frs2), frs1, 0b000, frd)
def fmul_s (frd, frs1, frs2): return _fop(0b0001000, R(frs2), frs1, 0b000, frd)
def fdiv_s (frd, frs1, frs2): return _fop(0b0001100, R(frs2), frs1, 0b000, frd)

MHARTID = 0xF14
MSTATUS = 0x300
BASE    = 0x80000000

# Layout: hart 0 comeca imediatamente apos setup (sem padding-spin).
# Setup ocupa 7 instrucoes.
HART0_ADDR = 0x80000018
HART1_ADDR = 0x80000058
FAIL_ADDR  = 0x800000B8

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('s0', 0x10),         "auipc s0, 0x10       # s0 = 0x80010000 (auipc no addr 0)"))
ins.append((addi ('s0','s0',-176),     "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((lui  ('t0', 0x00002),      "lui t0, 0x2          # t0 = 0x2000 (FS=01 mask)"))
ins.append((csrrs('zero', MSTATUS, 't0'),"csrrs x0, mstatus, t0  # enable FPU (FS=Initial)"))
ins.append((csrr ('t0', MHARTID),      "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),       f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

print(f"Setup terminou em 0x{addr_of(len(ins)):08X}, hart 0 esperado em 0x{HART0_ADDR:08X}")
while addr_of(len(ins)) < HART0_ADDR:
    ins.append((addi('x0','x0',0), "addi x0,x0,0  # nop"))
    print(f"  nop em 0x{addr_of(len(ins)-1):08X}")
assert addr_of(len(ins)) == HART0_ADDR

# Hart 0: fadd.s 1.0 + 2.0 == 3.0
ins.append((lui    ('t0', 0x3F800),      "lui t0, 0x3F800      # t0 = 0x3F800000 (1.0)"))
ins.append((fmv_w_x('f1','t0'),          "fmv.w.x f1, t0"))
ins.append((lui    ('t0', 0x40000),      "lui t0, 0x40000      # t0 = 0x40000000 (2.0)"))
ins.append((fmv_w_x('f2','t0'),          "fmv.w.x f2, t0"))
ins.append((fadd_s ('f3','f1','f2'),     "fadd.s f3, f1, f2    # 1.0 + 2.0 = 3.0"))
ins.append((fmv_x_w('t3','f3'),          "fmv.x.w t3, f3"))
ins.append((lui    ('t4', 0x40400),      "lui t4, 0x40400      # esperado 0x40400000 (3.0)"))
BNE0_IDX = len(ins)
BNE0_OFF = FAIL_ADDR - addr_of(BNE0_IDX)
ins.append((bne ('t3','t4', BNE0_OFF), f"bne t3, t4, +{BNE0_OFF} -> FAIL"))
ins.append((addi('s1','x0', 1),          "addi s1, x0, 1"))
ins.append((sw  ('s1','s0', 0),          "sw s1, 0(s0)         # TOHOST"))
ins.append((jal ('x0', 0),               "jal x0, 0            # spin success"))

print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding (apos hart 0 spin success)"))
    print(f"  padding em 0x{addr_of(len(ins)-1):08X}")
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1: fmul.s 2.0*2.0==4.0 ; fdiv.s 4.0/2.0==2.0
ins.append((addi('t5','x0', 200),    "addi t5, x0, 200     # delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
ins.append((lui    ('t0', 0x40000),  "lui t0, 0x40000      # t0 = 0x40000000 (2.0)"))
ins.append((fmv_w_x('f1','t0'),      "fmv.w.x f1, t0"))
ins.append((fmv_w_x('f2','t0'),      "fmv.w.x f2, t0       # f2 = 2.0"))
ins.append((fmul_s ('f3','f1','f2'), "fmul.s f3, f1, f2    # 2.0 * 2.0 = 4.0"))
ins.append((fmv_x_w('t3','f3'),      "fmv.x.w t3, f3"))
ins.append((lui    ('t4', 0x40800),  "lui t4, 0x40800      # esperado 0x40800000 (4.0)"))
BNE1_IDX = len(ins)
BNE1_OFF = FAIL_ADDR - addr_of(BNE1_IDX)
ins.append((bne ('t3','t4', BNE1_OFF), f"bne t3, t4, +{BNE1_OFF} -> FAIL"))
ins.append((fdiv_s ('f3','f3','f2'), "fdiv.s f3, f3, f2    # 4.0 / 2.0 = 2.0"))
ins.append((fmv_x_w('t3','f3'),      "fmv.x.w t3, f3"))
ins.append((lui    ('t4', 0x40000),  "lui t4, 0x40000      # esperado 0x40000000 (2.0)"))
BNE2_IDX = len(ins)
BNE2_OFF = FAIL_ADDR - addr_of(BNE2_IDX)
ins.append((bne ('t3','t4', BNE2_OFF), f"bne t3, t4, +{BNE2_OFF} -> FAIL"))
ins.append((addi('s1','x0', 1),      "addi s1, x0, 1"))
ins.append((sw  ('s1','s0', 0),      "sw s1, 0(s0)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}, FAIL esperado em 0x{FAIL_ADDR:08X}")
while addr_of(len(ins)) < FAIL_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding em 0x{addr_of(len(ins)-1):08X}")

ins.append((jal('x0', 0),            "jal x0, 0            # FAIL spin"))

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_e6.hex', 'w') as f:
    f.write("// boot_e6.hex - FPU basica (fadd, fmul, fdiv)\n")
    f.write("// Hart 0: fadd.s 1.0+2.0==3.0\n")
    f.write("// Hart 1: fmul.s 2.0*2.0==4.0 ; fdiv.s 4.0/2.0==2.0\n")
    f.write("// FPU habilitada via mstatus.FS=01.\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
