"""
Gera boot_b3.hex - AMO em regiao NC (MMIO).

Endereco-alvo 0x40002000 fica fora da janela cacheable
(CachedRegionAddrBase=0x80000000, CachedRegionLength=0x40000000), logo
e' tratado como non-cacheable pelo dcache_ctrl. Exercita o caminho de
miss_nc_o + AMO no missunit.

Hart 0: AMOADD +1 (esperado old=0)
Hart 1: AMOSWAP 7  (esperado old=1, validando que o hart 0 ja escreveu)

Observacao: no stub xsim do missunit, shadow_mem indexa por operand_a
[16:3] sem distinguir NC/C, entao o teste verifica principalmente que
o caminho de AMO em endereco fora da DRAM nao crasha o RTL e ainda
preserva a ordem cross-tile.
"""

REGS = {'zero':0,'ra':1,'sp':2,'gp':3,'tp':4,
        't0':5,'t1':6,'t2':7,
        's0':8,'s1':9,
        't3':28,'t4':29,'t5':30,'t6':31,
        'x0':0}
def R(s): return REGS[s]

def auipc(rd, imm20): return ((imm20&0xFFFFF)<<12)|(R(rd)<<7)|0x17
def lui  (rd, imm20): return ((imm20&0xFFFFF)<<12)|(R(rd)<<7)|0x37
def addi(rd, rs1, imm12): return ((imm12&0xFFF)<<20)|(R(rs1)<<15)|(R(rd)<<7)|0x13
def csrr(rd, csr): return (csr<<20)|(0b010<<12)|(R(rd)<<7)|0x73
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

def _amo(funct5, rd, rs2, rs1):
    funct7 = (funct5 << 2)
    return (funct7<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b010<<12)|(R(rd)<<7)|0x2F

def amoadd_w (rd, rs2, rs1): return _amo(0b00000, rd, rs2, rs1)
def amoswap_w(rd, rs2, rs1): return _amo(0b00001, rd, rs2, rs1)

MHARTID = 0xF14
BASE    = 0x80000000

HART0_ADDR = 0x80000014
HART1_ADDR = 0x80000040
FAIL_ADDR  = 0x80000088

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000 (auipc no addr 0)"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((lui  ('t2', 0x40002),    "lui t2, 0x40002      # t2 = 0x40002000 (NC addr)"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR, f"setup terminou em 0x{addr_of(len(ins)):08X}"

# Hart 0: AMOADD +1 em endereco NC 0x40002000
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((amoadd_w('t6','t3','t2'),"amoadd.w t6, t3, (t2)  # NC: +1, espera old=0"))
ins.append((addi('t4','x0', 0),      "addi t4, x0, 0       # esperado old=0"))
BNE0_IDX = len(ins)
BNE0_OFF = FAIL_ADDR - addr_of(BNE0_IDX)
ins.append((bne ('t6','t4', BNE0_OFF),f"bne t6, t4, +{BNE0_OFF} -> FAIL"))
ins.append((addi('s1','x0', 1),      "addi s1, x0, 1"))
ins.append((sw  ('s1','s0', 0),      "sw s1, 0(s0)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding em 0x{addr_of(len(ins)-1):08X}")
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1: AMOSWAP 7 em endereco NC (espera old=1, escrito por hart 0)
ins.append((addi('t5','x0', 400),    "addi t5, x0, 400     # long delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
ins.append((addi('t3','x0', 7),      "addi t3, x0, 7"))
ins.append((amoswap_w('t6','t3','t2'),"amoswap.w t6, t3, (t2)  # swap, espera old=1"))
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1       # esperado old=1"))
BNE1_IDX = len(ins)
BNE1_OFF = FAIL_ADDR - addr_of(BNE1_IDX)
ins.append((bne ('t6','t4', BNE1_OFF),f"bne t6, t4, +{BNE1_OFF} -> FAIL"))
ins.append((addi('s1','x0', 1),      "addi s1, x0, 1"))
ins.append((sw  ('s1','s0', 0),      "sw s1, 0(s0)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}, FAIL esperado em 0x{FAIL_ADDR:08X}")
while addr_of(len(ins)) < FAIL_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding em 0x{addr_of(len(ins)-1):08X}")

ins.append((jal('x0', 0),            "jal x0, 0            # FAIL spin"))

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_b3.hex', 'w') as f:
    f.write("// boot_b3.hex - AMO em regiao NC (0x40002000)\n")
    f.write("// Hart 0: amoadd.w +1 (espera old=0)\n")
    f.write("// Hart 1: amoswap.w 7 (espera old=1, escrito por hart 0)\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
