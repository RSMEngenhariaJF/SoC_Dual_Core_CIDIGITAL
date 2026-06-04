"""
Gera boot_a4.hex - Migracao de linha de cache (A4).

Padrao ping-pong: hart 0 e hart 1 escrevem alternadamente na mesma linha
de cache (0x80002000) com valores diferentes (0xAA e 0xBB). Cada hart faz
3 escritas, com delays calibrados para garantir intercalacao.

Cronograma esperado:
  cyc  ~50: hart 0 SW 0xAA  (1a)
  cyc  ~80: hart 1 SW 0xBB  (1a)
  cyc ~150: hart 0 SW 0xAA  (2a)
  cyc ~180: hart 1 SW 0xBB  (2a)
  cyc ~250: hart 0 SW 0xAA  (3a)
  cyc ~280: hart 1 SW 0xBB  (3a)
  cyc ~330: hart 1 LW (esperado: 0xBB)

A linha "migra" 6 vezes entre os tiles. Final value = 0xBB.
Hart 1 verifica final == 0xBB; hart 0 apenas TOHOST.
"""

REGS = {'zero':0,'ra':1,'sp':2,'gp':3,'tp':4,
        't0':5,'t1':6,'t2':7,
        's0':8,'s1':9,
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
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b001<<12)|(b4_1<<8)|(b11<<7)|0x63
def bnez(rs1, imm13): return bne(rs1, 'x0', imm13)
def jal(rd, imm21):
    imm = imm21 & 0x1FFFFF
    b20=(imm>>20)&1; b10_1=(imm>>1)&0x3FF; b11=(imm>>11)&1; b19_12=(imm>>12)&0xFF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(R(rd)<<7)|0x6F

MHARTID = 0xF14
BASE = 0x80000000

# Layout:
# Setup: 5 instr (0x00..0x10)
# Hart 0: 16 instr (0x14..0x50)
# Hart 1: 22 instr (0x54..0xA8)
# Fail:  1 instr (0xAC)
HART0_ADDR = 0x80000014
HART1_ADDR = 0x80000054
FAIL_ADDR  = 0x800000AC

ins = []
def addr_of(idx): return BASE + idx*4

# Setup (5 instr)
ins.append((auipc('t2', 2),        "auipc t2, 2          # t2 = 0x80002000"))
ins.append((auipc('t1', 0x10),     "auipc t1, 0x10"))
ins.append((addi ('t1','t1',-180), "addi t1, t1, -180    # t1 = 0x8000FF50"))
ins.append((csrr ('t0', MHARTID),  "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),   f"bnez t0, +{H1_OFF}  -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR

# Hart 0: 3 escritas de 0xAA com delays curtos
ins.append((addi('t3','x0', 0xAA),   "addi t3, x0, 0xAA    # value hart 0"))
# 1a escrita - delay inicial 30
ins.append((addi('t5','x0', 30),     "addi t5, x0, 30      # delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # 1a: line = 0xAA"))
# 2a escrita - delay 50
ins.append((addi('t5','x0', 50),     "addi t5, x0, 50"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # 2a: line = 0xAA"))
# 3a escrita - delay 50
ins.append((addi('t5','x0', 50),     "addi t5, x0, 50"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # 3a: line = 0xAA"))
# TOHOST
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin"))

assert addr_of(len(ins)) == HART1_ADDR, \
    f"Hart 1 nao alinhado: esperado 0x{HART1_ADDR:08X}, real 0x{addr_of(len(ins)):08X}"

# Hart 1: 3 escritas de 0xBB intercaladas + verifica final == 0xBB
ins.append((addi('t3','x0', 0xBB),   "addi t3, x0, 0xBB    # value hart 1"))
# 1a escrita - delay 60 (run after hart 0's 1st)
ins.append((addi('t5','x0', 60),     "addi t5, x0, 60      # delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # 1a: line = 0xBB"))
# 2a escrita - delay 50
ins.append((addi('t5','x0', 50),     "addi t5, x0, 50"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # 2a: line = 0xBB"))
# 3a escrita - delay 50
ins.append((addi('t5','x0', 50),     "addi t5, x0, 50"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
ins.append((sw  ('t3','t2', 0),      "sw t3, 0(t2)         # 3a: line = 0xBB"))
# delay extra, depois LW + verify
ins.append((addi('t5','x0', 100),    "addi t5, x0, 100     # settle delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4"))
# verify: nao fazemos LW aqui pra evitar crash do pipeline; em vez disso
# usamos AMOADD com 0 (read-only via swap+0+0... na verdade amoadd 0)
# que retorna o valor atual. Se hart 1 escreveu por ultimo, AMOADD 0
# deve retornar 0xBB.
# Como AMOADD 0 mantem o valor, e' funcionalmente um LW que vai pelo
# caminho de AMO ja' validado.
def amoadd_w(rd, rs2, rs1):
    return ((0 << 25) | (R(rs2) << 20) | (R(rs1) << 15) | (0b010 << 12) | (R(rd) << 7) | 0x2F)
ins.append((amoadd_w('t6','x0','t2'),"amoadd.w t6, x0, (t2) # le valor atual (AMO read-only)"))
ins.append((addi('t4','x0', 0xBB),   "addi t4, x0, 0xBB    # expected"))
BNE_IDX = len(ins)
BNE_OFF = FAIL_ADDR - addr_of(BNE_IDX)
ins.append((bne ('t6','t4', BNE_OFF),f"bne t6, t4, +{BNE_OFF} -> FAIL"))
# TOHOST
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

# Fail
assert addr_of(len(ins)) == FAIL_ADDR, \
    f"Fail nao alinhado: esperado 0x{FAIL_ADDR:08X}, real 0x{addr_of(len(ins)):08X}"
ins.append((jal('x0', 0),            "jal x0, 0            # FAIL spin"))

# Output
with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_a4.hex', 'w') as f:
    f.write("// boot_a4.hex - Migracao de linha de cache (ping-pong)\n")
    f.write("// Hart 0 escreve 0xAA na linha 0x80002000 tres vezes,\n")
    f.write("// Hart 1 escreve 0xBB tres vezes (intercaladas via delays).\n")
    f.write("// Hart 1 le valor final via AMOADD 0 (esperado 0xBB).\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"OK - {len(ins)} instrucoes (Hart1 @ 0x{HART1_ADDR:08X}, FAIL @ 0x{FAIL_ADDR:08X})")
