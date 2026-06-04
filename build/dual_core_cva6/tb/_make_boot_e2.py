"""
Gera boot_e2.hex - IPI (inter-processor interrupt) via msip do CLINT.

Hart 0 (sender): apos pequeno delay, escreve 1 em msip[1] (endereco
0xFFF1020004 do CLINT). Vai para tohost.
Hart 1 (receiver): faz polling em CSR mip aguardando bit MSIP (3).
Quando detecta, escreve tohost.

Esta versao usa polling (nao trap-driven) para evitar complicacao com
handler de interrupt. O ponto-chave validado e' que a escrita SW em
msip[1] alcanca o CLINT real (escapando do stub xsim do missunit que
intercepta AMOs), e o CLINT propaga para mip[3] do hart 1.

Endereco msip[1] = CLINTBase + 4 = 0xFFF1020000 + 4 = 0xFFF1020004
   (em 64-bit: 0x000000FF_F1020004)

Debug em 0x8000FF60 (mip final do hart 1) e 0x8000FF68 (marker de
entrada em polling do hart 1).
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
def andi(rd, rs1, imm12): return ((imm12&0xFFF)<<20)|(R(rs1)<<15)|(0b111<<12)|(R(rd)<<7)|0x13
def slli(rd, rs1, shamt): return (shamt<<20)|(R(rs1)<<15)|(0b001<<12)|(R(rd)<<7)|0x13
def srli(rd, rs1, shamt): return (shamt<<20)|(R(rs1)<<15)|(0b101<<12)|(R(rd)<<7)|0x13
def or_ (rd, rs1, rs2):   return (0<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b110<<12)|(R(rd)<<7)|0x33
def csrr (rd, csr):       return (csr<<20)|(R('x0')<<15)|(0b010<<12)|(R(rd)<<7)|0x73
def sw(rs2, rs1, imm12):
    imm = imm12 & 0xFFF
    return ((imm>>5)<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b010<<12)|((imm&0x1F)<<7)|0x23
def bne(rs1, rs2, imm13):
    imm = imm13 & 0x1FFF
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b001<<12)|(b4_1<<8)|(b11<<7)|0x63
def bnez(rs1, imm13): return bne(rs1, 'x0', imm13)
def beq (rs1, rs2, imm13):
    imm = imm13 & 0x1FFF
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b000<<12)|(b4_1<<8)|(b11<<7)|0x63
def beqz(rs1, imm13): return beq(rs1, 'x0', imm13)
def jal(rd, imm21):
    imm = imm21 & 0x1FFFFF
    b20=(imm>>20)&1; b10_1=(imm>>1)&0x3FF; b11=(imm>>11)&1; b19_12=(imm>>12)&0xFF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(R(rd)<<7)|0x6F

MHARTID = 0xF14
MIP     = 0x344
BASE    = 0x80000000

HART0_ADDR = 0x80000010
HART1_ADDR = 0x80000064

ins = []
def addr_of(idx): return BASE + idx*4

# --- Setup ---
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR, f"setup terminou em 0x{addr_of(len(ins)):08X}"

# --- Hart 0 (sender) ---
# delay pequeno para garantir que hart 1 ja entrou em polling
ins.append((addi('t5','x0', 50),     "addi t5, x0, 50      # delay inicial"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
# Construir endereco msip[1] = 0x000000FF_F1020004 em t2
ins.append((addi('t2','x0', 0xFF),   "addi t2, x0, 0xFF    # t2 = 0xFF"))
ins.append((slli('t2','t2', 32),     "slli t2, t2, 32      # t2 = 0xFF_00000000"))
ins.append((lui ('t3', 0xF1020),     "lui t3, 0xF1020      # t3 = 0xFFFFFFFF_F1020000 (sign-ext)"))
ins.append((slli('t3','t3', 32),     "slli t3, t3, 32      # t3 = 0xF1020000_00000000"))
ins.append((srli('t3','t3', 32),     "srli t3, t3, 32      # t3 = 0x00000000_F1020000 (zero-ext)"))
ins.append((or_ ('t2','t2','t3'),    "or t2, t2, t3        # t2 = 0xFF_F1020000 = msip[0]"))
ins.append((addi('t2','t2', 4),      "addi t2, t2, 4       # t2 = msip[1]"))
# debug: gravar endereco computado em 0x8000FF70 (s0+0x20)
ins.append((sw  ('t2','s0', 0x20),   "sw t2, 0x20(s0)      # debug: msip[1] addr"))
# escrever 1 em msip[1]
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # MSIP write -> CLINT"))
# delay para garantir que hart 1 detectou
ins.append((addi('t5','x0', 200),    "addi t5, x0, 200"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
# tohost
ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
ins.append((sw  ('t1','s0', 0),      "sw t1, 0(s0)         # TOHOST hart 0"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding (apos hart 0 spin)"))
assert addr_of(len(ins)) == HART1_ADDR

# --- Hart 1 (receiver, polling em mip.MSIP) ---
# marker: hart 1 entrou em polling -> grava 0x99 em 0x8000FF68 (s0+0x18)
ins.append((addi('t4','x0', 0x99),   "addi t4, x0, 0x99    # marker"))
ins.append((sw  ('t4','s0', 0x18),   "sw t4, 0x18(s0)      # debug: hart 1 em polling"))
# polling: read mip; mask bit 3 (MSIP); loop ate ver 1
poll_idx = len(ins)
ins.append((csrr('t6', MIP),         "csrr t6, mip"))
ins.append((andi('t5','t6', 8),      "andi t5, t6, 8       # bit 3 = MSIP"))
# beqz t5, poll (back to csrr)
back_off = addr_of(poll_idx) - addr_of(len(ins))
ins.append((beqz('t5', back_off),    f"beqz t5, {back_off}   # loop ate MSIP=1"))
# saiu do polling -> grava mip final em 0x8000FF60 (debug)
ins.append((sw  ('t6','s0', 0x10),   "sw t6, 0x10(s0)      # debug: mip final"))
# tohost
ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
ins.append((sw  ('t1','s0', 0),      "sw t1, 0(s0)         # TOHOST hart 1"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}")

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_e2.hex', 'w') as f:
    f.write("// boot_e2.hex - IPI via msip[1] do CLINT (polling)\n")
    f.write("// Hart 0: SW 1 em 0xFFF1020004 (msip[1])\n")
    f.write("// Hart 1: polling em mip ate ver MSIP=1\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
