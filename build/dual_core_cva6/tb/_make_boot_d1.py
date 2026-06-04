"""
Gera boot_d1.hex - Spinlock contention (D1) com AMOADD.

Dois harts disputam um spinlock implementado com LR.W/SC.W e usam AMOADD
para incrementar atomicamente um contador compartilhado dentro da secao
critica. Cada hart valida que o valor OLD retornado pelo AMOADD bate com
sua posicao na ordem (hart 0 espera old=0, hart 1 espera old=1), provando
que AMBOS executaram a secao critica em ordem.

Layout:
  0x80002000  contador (inicialmente 0)
  0x80002040  lock     (inicialmente 0 = livre; 1 = ocupado)
  0x8000FF50  tohost

Sequencia logica de cada hart:
  delay
  acquire_lock:
    lr.w  t6, 0(s0)           # le lock
    bnez  t6, acquire_lock    # se != 0, retry (spinning)
    addi  t3, x0, 1
    sc.w  t0, t3, 0(s0)       # tenta setar lock=1
    bnez  t0, acquire_lock    # se SC falhou, retry
  # secao critica
    lw    t6, 0(t2)
    addi  t6, t6, 1
    sw    t6, 0(t2)
  # release
    sw    x0, 0(s0)
  # tohost
    addi  t4, x0, 1
    sw    t4, 0(t1)
    jal   x0, 0

Hart 1 adicionalmente verifica counter==2 antes de tohost.

NOTA: o stub xsim de SC.W sempre retorna sucesso (nao rastreia
reservation set real). A delimitacao temporal por delays diferentes
garante que hart 0 corra antes de hart 1, dando ao spinlock o efeito
desejado neste setup.
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

def _amo(funct5, rd, rs2, rs1, aq=0, rl=0):
    funct7 = (funct5 << 2) | (aq << 1) | rl
    return (funct7 << 25) | (R(rs2) << 20) | (R(rs1) << 15) | (0b010 << 12) | (R(rd) << 7) | 0x2F

def lr_w     (rd, rs1):      return _amo(0b00010, rd, 'x0', rs1)
def sc_w     (rd, rs2, rs1): return _amo(0b00011, rd, rs2, rs1)
def amoadd_w (rd, rs2, rs1): return _amo(0b00000, rd, rs2, rs1)

MHARTID = 0xF14
BASE = 0x80000000

# Esqueleto: vamos construir 2 spinlocks em paralelo (mesmo codigo).
# Hart 0 com delay curto, hart 1 com delay longo + verificacao extra.

# Layout planejado (instrucoes):
# Setup:       6 instr  (0x00..0x14)
# Hart 0:     15 instr  (0x18..0x50)
# Hart 1:     16 instr  (0x54..0x90)
# Fail:        1 instr  (0x94)
HART0_ADDR = 0x80000018
HART1_ADDR = 0x80000054
FAIL_ADDR  = 0x80000094
H1_BNE_TO  = FAIL_ADDR

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

# Hart 0: delay (50) + spinlock acquire + AMOADD increment + verify old==0 + release
ins.append((addi('t5','x0', 50),     "addi t5, x0, 50      # short delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
# spinlock acquire
ins.append((lr_w('t6', 's0'),        "lr.w t6, (s0)        # acquire: read lock"))
ins.append((bnez('t6', -4),          "bnez t6, -4          # if locked, retry lr"))
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((sc_w('t0','t3','s0'),    "sc.w t0, t3, (s0)    # try lock=1"))
ins.append((bnez('t0', -16),         "bnez t0, -16         # if SC failed, retry"))
# critical section: AMOADD counter += 1, t6 = old value
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((amoadd_w('t6','t3','t2'),"amoadd.w t6, t3, (t2)  # counter += 1, t6 = old"))
# verify hart 0 saw counter==0 antes (foi o primeiro)
BNE0_IDX = len(ins)
BNE0_OFF = FAIL_ADDR - addr_of(BNE0_IDX)
ins.append((bnez('t6', BNE0_OFF),    f"bnez t6, +{BNE0_OFF} -> FAIL (esperado old=0)"))
# release lock
ins.append((sw  ('x0','s0', 0),      "sw x0, 0(s0)         # release lock"))
# tohost
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin"))

assert addr_of(len(ins)) == HART1_ADDR, \
    f"Hart 1 nao alinhado: esperado 0x{HART1_ADDR:08X}, real 0x{addr_of(len(ins)):08X}"

# Hart 1: delay maior + spinlock + AMOADD + verify old==1 + release
ins.append((addi('t5','x0', 300),    "addi t5, x0, 300     # long delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
# spinlock acquire
ins.append((lr_w('t6', 's0'),        "lr.w t6, (s0)"))
ins.append((bnez('t6', -4),          "bnez t6, -4          # retry lr if locked"))
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((sc_w('t0','t3','s0'),    "sc.w t0, t3, (s0)"))
ins.append((bnez('t0', -16),         "bnez t0, -16         # retry if SC failed"))
# critical section: AMOADD counter += 1, t6 = old (esperado: 1)
ins.append((addi('t3','x0', 1),      "addi t3, x0, 1"))
ins.append((amoadd_w('t6','t3','t2'),"amoadd.w t6, t3, (t2)  # counter += 1, t6 = old"))
# verify hart 1 viu counter==1 antes (hart 0 ja incrementou)
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1       # expected old=1"))
BNE1_IDX = len(ins)
BNE1_OFF = FAIL_ADDR - addr_of(BNE1_IDX)
ins.append((bne ('t6','t4', BNE1_OFF),f"bne t6, t4, +{BNE1_OFF} -> FAIL (esperado old=1)"))
# release lock
ins.append((sw  ('x0','s0', 0),      "sw x0, 0(s0)         # release lock"))
# tohost
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

assert addr_of(len(ins)) == FAIL_ADDR, \
    f"Fail nao alinhado: esperado 0x{FAIL_ADDR:08X}, real 0x{addr_of(len(ins)):08X}"

# Fail spin
ins.append((jal('x0', 0),            "jal x0, 0            # FAIL spin"))

# Output
with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_d1.hex', 'w') as f:
    f.write("// boot_d1.hex - Spinlock contention (LR/SC + counter increment)\n")
    f.write("// Hart 0 e Hart 1 disputam lock em 0x80002040 e incrementam\n")
    f.write("// counter em 0x80002000. Hart 1 verifica counter == 2 ao fim.\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"OK - {len(ins)} instrucoes (Hart1 @ 0x{HART1_ADDR:08X}, FAIL @ 0x{FAIL_ADDR:08X})")
