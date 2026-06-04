"""
Gera boot_a1.hex - True sharing com spinlock (A1).

Dois harts disputam um spinlock e cada um faz 3 iteracoes de
AMOADD(1) dentro da secao critica. Counter final esperado = 6.

Estrutura de cada hart:
  delay
  addi t5, x0, 3        ; iter counter
.loop:
  lr.w  t6, (s0)        ; spinlock acquire
  bnez  t6, -4          ; retry if locked
  addi  t3, x0, 1
  sc.w  t0, t3, (s0)
  bnez  t0, -16         ; retry if SC failed
  amoadd.w t6, t3, (t2) ; counter += 1
  sw    x0, 0(s0)       ; release lock
  addi  t5, t5, -1
  bnez  t5, -32         ; loop back
  ; tohost...

Hart 1 ao final faz amoadd.w x0, (t2) como read-only e valida
counter == 6.
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
def jal(rd, imm21):
    imm = imm21 & 0x1FFFFF
    b20=(imm>>20)&1; b10_1=(imm>>1)&0x3FF; b11=(imm>>11)&1; b19_12=(imm>>12)&0xFF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(R(rd)<<7)|0x6F

def _amo(funct5, rd, rs2, rs1, aq=0, rl=0):
    funct7 = (funct5 << 2) | (aq << 1) | rl
    return (funct7<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b010<<12)|(R(rd)<<7)|0x2F

def lr_w     (rd, rs1):      return _amo(0b00010, rd, 'x0', rs1)
def sc_w     (rd, rs2, rs1): return _amo(0b00011, rd, rs2, rs1)
def amoadd_w (rd, rs2, rs1): return _amo(0b00000, rd, rs2, rs1)

MHARTID = 0xF14
BASE = 0x80000000

# Layout planejado (a verificar):
# Setup:  6 instr
# Hart 0: 17 instr
# Hart 1: 21 instr (com verify)
# Fail:    1 instr
HART0_ADDR = 0x80000018
HART1_ADDR = 0x80000058
FAIL_ADDR  = 0x800000AC

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('t2', 2),        "auipc t2, 2          # t2 = 0x80002000 (counter)"))
ins.append((auipc('t1', 0x10),     "auipc t1, 0x10"))
ins.append((addi ('t1','t1',-180), "addi t1, t1, -180    # t1 = 0x8000FF50 (tohost)"))
ins.append((addi ('s0','t2', 64),  "addi s0, t2, 64      # s0 = 0x80002040 (lock)"))
ins.append((csrr ('t0', MHARTID),  "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),   f"bnez t0, +{H1_OFF}  -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR

# Hart 0: delay + loop (3 iter de spinlock+AMOADD) + tohost
ins.append((addi('t5','x0', 30),     "addi t5, x0, 30      # delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
ins.append((addi('t5','x0', 3),      "addi t5, x0, 3       # iter counter"))
# loop body (9 instr) - target of bnez t5
LOOP_START = len(ins)
ins.append((lr_w('t6', 's0'),        "lr.w t6, (s0)"))
ins.append((bnez('t6', -4),          "bnez t6, -4          # retry if locked"))
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((sc_w('t0','t3','s0'),    "sc.w t0, t3, (s0)"))
ins.append((bnez('t0', -16),         "bnez t0, -16         # retry if SC failed"))
ins.append((amoadd_w('t6','t3','t2'),"amoadd.w t6, t3, (t2)  # counter += 1"))
ins.append((sw  ('x0','s0', 0),      "sw x0, 0(s0)         # release lock"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1      # iter--"))
# bnez t5 jumps back to LOOP_START
LOOP_BACK = (addr_of(LOOP_START) - addr_of(len(ins)))
ins.append((bnez('t5', LOOP_BACK),   f"bnez t5, {LOOP_BACK}  # back to loop_start"))
# tohost
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin"))

# Check alignment for hart 1
print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding adicionado em 0x{addr_of(len(ins)-1):08X}")

# Hart 1: delay + loop (3 iter) + verify + tohost
assert addr_of(len(ins)) == HART1_ADDR

ins.append((addi('t5','x0', 200),    "addi t5, x0, 200     # long delay (hart 0 ja terminou)"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
ins.append((addi('t5','x0', 3),      "addi t5, x0, 3       # iter counter"))
# loop body
LOOP1_START = len(ins)
ins.append((lr_w('t6', 's0'),        "lr.w t6, (s0)"))
ins.append((bnez('t6', -4),          "bnez t6, -4          # retry if locked"))
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((sc_w('t0','t3','s0'),    "sc.w t0, t3, (s0)"))
ins.append((bnez('t0', -16),         "bnez t0, -16         # retry if SC failed"))
ins.append((amoadd_w('t6','t3','t2'),"amoadd.w t6, t3, (t2)  # counter += 1"))
ins.append((sw  ('x0','s0', 0),      "sw x0, 0(s0)         # release lock"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
LOOP_BACK1 = addr_of(LOOP1_START) - addr_of(len(ins))
ins.append((bnez('t5', LOOP_BACK1),  f"bnez t5, {LOOP_BACK1}  # back to loop_start"))
# Verify: amoadd.w t6, x0, (t2)  -> le valor atual sem alterar
ins.append((amoadd_w('t6','x0','t2'),"amoadd.w t6, x0, (t2)  # READ counter (AMO+0)"))
ins.append((addi('t4','x0', 6),      "addi t4, x0, 6       # expected counter"))
BNE_IDX = len(ins)
BNE_OFF = FAIL_ADDR - addr_of(BNE_IDX)
ins.append((bne ('t6','t4', BNE_OFF),f"bne t6, t4, +{BNE_OFF} -> FAIL (counter != 6)"))
# tohost
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

# Check alignment for fail
print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}, FAIL esperado em 0x{FAIL_ADDR:08X}")
while addr_of(len(ins)) < FAIL_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding adicionado em 0x{addr_of(len(ins)-1):08X}")

ins.append((jal('x0', 0),            "jal x0, 0            # FAIL spin"))

# Output
with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_a1.hex', 'w') as f:
    f.write("// boot_a1.hex - True sharing com spinlock (3 iter por hart)\n")
    f.write("// Hart 0 + Hart 1 cada um incrementa 3x via AMOADD dentro\n")
    f.write("// de secao critica protegida por spinlock LR/SC.\n")
    f.write("// Final esperado: counter == 6.\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
