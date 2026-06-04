"""
Gera boot_d2.hex - Memory barrier (fence variants).

Exercita tres variantes da instrucao FENCE com pred/succ distintos
(rw,rw; r,r; w,w). Todas devem commitar sem crash; com patches 8+9
aplicados a fence funciona como no-op no controller (suprime flush
downstream que crasha xsim), mas o commit_ack e dado normalmente.

Estrutura:
  Hart 0 (producer):
    SW DATA=0x1AAA1 em 0x80002000
    fence.w,w
    SW FLAG=1     em 0x80002040
    fence.rw,rw
    tohost
  Hart 1 (consumer):
    polling LW FLAG ate ver != 0
    fence.r,r
    LW DATA
    validar contra 0x1AAA1 via bne
    tohost

Validacao: GOOD TRAP AMBOS TILES com tres variantes distintas de fence
commitadas sem FATAL_ERROR.
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
def lw(rd, rs1, imm12): return ((imm12&0xFFF)<<20)|(R(rs1)<<15)|(0b010<<12)|(R(rd)<<7)|0x03
def bne(rs1, rs2, imm13):
    imm = imm13 & 0x1FFF
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b001<<12)|(b4_1<<8)|(b11<<7)|0x63
def bnez(rs1, imm13): return bne(rs1, 'x0', imm13)
def beqz(rs1, imm13):
    imm = imm13 & 0x1FFF
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(0<<20)|(R(rs1)<<15)|(0b000<<12)|(b4_1<<8)|(b11<<7)|0x63
def jal(rd, imm21):
    imm = imm21 & 0x1FFFFF
    b20=(imm>>20)&1; b10_1=(imm>>1)&0x3FF; b11=(imm>>11)&1; b19_12=(imm>>12)&0xFF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(R(rd)<<7)|0x6F

# FENCE: fm[31:28] pred[27:24] succ[23:20] rs1[19:15]=0 funct3[14:12]=000 rd[11:7]=0 opcode=0001111
# pred/succ bits: I=8 O=4 R=2 W=1
def fence(pred, succ): return (0<<28)|(pred<<24)|(succ<<20)|(0<<15)|(0b000<<12)|(0<<7)|0x0F
FENCE_RW_RW = fence(0b0011, 0b0011)
FENCE_R_R   = fence(0b0010, 0b0010)
FENCE_W_W   = fence(0b0001, 0b0001)

MHARTID = 0xF14
BASE    = 0x80000000

HART0_ADDR = 0x80000010
HART1_ADDR = 0x80000040

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR

# Hart 0: SW DATA, fence.w,w, SW FLAG, fence.rw,rw, tohost
ins.append((addi('t2','s0', 0),      "addi t2, s0, 0       # t2 = tohost (provisorio)"))
ins.append((auipc('t2', 0),          "auipc t2, 0"))
# Construir DATA addr 0x80002000 via auipc; precisa ajustar
# Mais simples: usar offset positivo de auipc.
# Atual PC = addr_of(len(ins)-1)
# Target = 0x80002000
# auipc(t2, X) -> t2 = PC + (X << 12)
# Para X=2, t2 = PC + 0x2000. Se PC = 0x80000018, t2 = 0x80002018.
# Quero t2 = 0x80002000, entao auipc 2 e addi -0x18.
# Vou recalcular dinamicamente.
auipc_pc = addr_of(len(ins)-1)
DATA_ADDR = 0x80002000
imm20 = 2  # +0x2000
ins[-1] = (auipc('t2', imm20), "auipc t2, 2")
addi_off = DATA_ADDR - (auipc_pc + (imm20 << 12))
ins.append((addi('t2','t2', addi_off), f"addi t2, t2, {addi_off}   # t2 = 0x80002000 (DATA)"))
ins.append((addi('t3','x0', 0x6AA),  "addi t3, x0, 0x6AA   # DATA valor (cabe 12-bit signed)"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # DATA = 0x6AA"))
# fence.w,w
ins.append((FENCE_W_W,               "fence w,w            # variante 1"))
# SW FLAG=1 em t2+0x40
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t2', 0x40),   "sw t4, 0x40(t2)      # FLAG = 1"))
# fence.rw,rw
ins.append((FENCE_RW_RW,             "fence rw,rw          # variante 2"))
# tohost
ins.append((sw  ('t4','s0', 0),      "sw t4, 0(s0)         # TOHOST hart 0"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1: polling FLAG, fence.r,r, LW DATA, validar
ins.append((auipc('t2', 2),          "auipc t2, 2"))
auipc_h1_pc = addr_of(len(ins)-1)
addi_off_h1 = DATA_ADDR - (auipc_h1_pc + (2 << 12))
ins.append((addi('t2','t2', addi_off_h1), f"addi t2, t2, {addi_off_h1}  # t2 = 0x80002000 (DATA)"))
# polling LW FLAG ate ver != 0
poll_idx = len(ins)
ins.append((lw  ('t6','t2', 0x40),   "lw t6, 0x40(t2)      # poll FLAG"))
back_off = addr_of(poll_idx) - addr_of(len(ins))
ins.append((beqz('t6', back_off),    f"beqz t6, {back_off}   # loop ate FLAG=1"))
# fence.r,r
ins.append((FENCE_R_R,               "fence r,r            # variante 3"))
# LW DATA e validar
ins.append((lw  ('t6','t2', 0),      "lw t6, 0(t2)         # le DATA"))
ins.append((addi('t4','x0', 0x6AA),  "addi t4, x0, 0x6AA"))
# bne para FAIL se != 0x6AA
ins.append((bne ('t6','t4', 12),     "bne t6, t4, +12      # FAIL se valor errado"))
ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
ins.append((sw  ('t1','s0', 0),      "sw t1, 0(s0)         # TOHOST hart 1"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))
ins.append((jal ('x0', 0),           "jal x0, 0            # FAIL spin"))

print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}")

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_d2.hex', 'w') as f:
    f.write("// boot_d2.hex - Memory barrier (fence variants w,w / r,r / rw,rw)\n")
    f.write("// Hart 0: SW DATA, fence.w,w, SW FLAG, fence.rw,rw, tohost\n")
    f.write("// Hart 1: poll FLAG, fence.r,r, LW DATA, validar, tohost\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
