"""
Gera boot_c3.hex - fence.i (I-cache flush sync).

Hart 0 e Hart 1 cada um emite uma instrucao FENCE.I e segue para
tohost. Com patch nº 10 (fence_i_o suprimido sob XSIM), fence.i
deve commitar sem disparar flush_icache_o (que poderia tocar outro
continuous assign problematico no kernel xsim).

Esta versao nao testa a semantica completa de fence.i (modificacao
de codigo executavel em runtime — incompativel com nosso layout
flat boot.hex carregado uma vez), apenas a aceitacao do opcode pelo
decoder e o commit sem crash.

FENCE.I encoding = 0x0000_100F
"""

REGS = {'zero':0,'ra':1,'sp':2,'gp':3,'tp':4,
        't0':5,'t1':6,'t2':7,
        's0':8,'s1':9,
        't3':28,'t4':29,'t5':30,'t6':31,
        'x0':0}
def R(s): return REGS[s]

def auipc(rd, imm20): return ((imm20&0xFFFFF)<<12)|(R(rd)<<7)|0x17
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

FENCE_I = 0x0000_100F

MHARTID = 0xF14
BASE    = 0x80000000

HART0_ADDR = 0x80000010
HART1_ADDR = 0x80000030

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR

# Hart 0: fence.i + tohost
ins.append((FENCE_I,                 "fence.i              # sync I-stream (hart 0)"))
ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
ins.append((sw  ('t1','s0', 0),      "sw t1, 0(s0)         # TOHOST hart 0"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1: delay + fence.i + tohost
ins.append((addi('t5','x0', 100),    "addi t5, x0, 100     # delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
ins.append((FENCE_I,                 "fence.i              # sync I-stream (hart 1)"))
ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
ins.append((sw  ('t1','s0', 0),      "sw t1, 0(s0)         # TOHOST hart 1"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}")

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_c3.hex', 'w') as f:
    f.write("// boot_c3.hex - fence.i\n")
    f.write("// Hart 0 e Hart 1 cada um emite uma fence.i e segue para tohost.\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
