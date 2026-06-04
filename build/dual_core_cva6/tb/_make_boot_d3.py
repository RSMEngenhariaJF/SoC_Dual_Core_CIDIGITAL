"""
Gera boot_d3.hex - Barrier sense-reversing (variante simplificada
"join-barrier" para 2 harts).

Cada hart incrementa um counter atomico (AMOADD) e depois fica em
polling ate ver counter == 2 (todos chegaram). Quando ambos
ultrapassam a barreira, sinalizam tohost.

Reusa o caminho atomico de A1/D1 e a infraestrutura de fence (FENCE
rw,rw como acquire/release explicito, mesmo que no nosso ambiente
ela e' no-op via patch nº 9).

Estrutura por hart:
  delay distinto (hart 0 menor, hart 1 maior)
  amoadd.w t6, t3=1, (barrier)
  fence rw,rw
  loop: amoadd.w t6, x0, (barrier)  ; le valor atual sem alterar
        addi t4, x0, 2
        bne t6, t4, loop            ; espera ate counter == 2
  tohost
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

def _amo(funct5, rd, rs2, rs1):
    funct7 = (funct5 << 2)
    return (funct7<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b010<<12)|(R(rd)<<7)|0x2F

def amoadd_w(rd, rs2, rs1): return _amo(0b00000, rd, rs2, rs1)

FENCE_RW_RW = (0<<28)|(0b0011<<24)|(0b0011<<20)|(0<<15)|(0b000<<12)|(0<<7)|0x0F

MHARTID = 0xF14
BASE    = 0x80000000

HART0_ADDR = 0x80000010
HART1_ADDR = 0x80000050

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR

def emit_hart(delay_iters, label):
    """Emite o corpo de um hart: delay, increment barrier, espera, tohost."""
    # delay
    ins.append((addi('t5','x0', delay_iters), f"addi t5, x0, {delay_iters}    # {label} delay"))
    ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
    ins.append((bnez('t5', -4),          "bnez t5, -4"))
    # barrier addr = 0x80002000, construir via auipc
    pc_now = addr_of(len(ins))
    ins.append((auipc('t2', 2),          "auipc t2, 2"))
    addi_off = 0x80002000 - (pc_now + (2 << 12))
    ins.append((addi('t2','t2', addi_off), f"addi t2, t2, {addi_off}   # t2 = 0x80002000 (barrier)"))
    # incrementa barrier (AMOADD +1)
    ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
    ins.append((amoadd_w('t6','t3','t2'), "amoadd.w t6, t3, (t2)  # barrier++"))
    # fence rw,rw (no-op via patch 9; documentacao da semantica)
    ins.append((FENCE_RW_RW,             "fence rw,rw          # release/acquire explicito"))
    # polling: amoadd.w t6, x0, (t2) le valor atual sem alterar
    poll_idx = len(ins)
    ins.append((amoadd_w('t6','x0','t2'),"amoadd.w t6, x0, (t2)  # le counter"))
    ins.append((addi('t4','x0', 2),      "addi t4, x0, 2       # esperado: 2 harts"))
    back_off = addr_of(poll_idx) - addr_of(len(ins))
    ins.append((bne ('t6','t4', back_off), f"bne t6, t4, {back_off}  # espera ate t6==2"))
    # tohost
    ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
    ins.append((sw  ('t1','s0', 0),      f"sw t1, 0(s0)         # TOHOST {label}"))
    ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

# Hart 0 (delay menor)
emit_hart(30, "hart 0")
print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1 (delay maior)
emit_hart(80, "hart 1")
print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}")

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_d3.hex', 'w') as f:
    f.write("// boot_d3.hex - Barrier (join, 2 harts)\n")
    f.write("// Cada hart faz AMOADD no contador, fence rw,rw e polling\n")
    f.write("// (AMOADD+0) ate ver counter==2; entao tohost.\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
