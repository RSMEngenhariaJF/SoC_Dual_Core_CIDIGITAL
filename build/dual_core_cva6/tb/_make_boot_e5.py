"""
Gera boot_e5.hex - Transicao de modo M -> S/U + trap handler.

Esqueleto reusavel para os demais testes E (E1/E2/E3 reaproveitarao
mtvec + handler).

Fluxo:
  Setup (M-mode): configura s0=tohost, mtvec=HANDLER, bnez mhartid.
  Hart 0 (M->S): mepc=S_ENTRY, mstatus.MPP=01, mret, ecall (mcause=9).
  Hart 1 (M->U): mepc=U_ENTRY, mstatus.MPP=00, mret, ecall (mcause=8).
  Handler (M-mode, comum):
    valida mcause em {8,9}; escreve tohost; spin.

Esperado:
  Cada ecall dispara trap em M-mode, handler escreve tohost,
  monitor SB_TRAP detecta sw para 0x8000FF50.
  GOOD TRAP AMBOS TILES.
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
def slli(rd, rs1, shamt): return (shamt<<20)|(R(rs1)<<15)|(0b001<<12)|(R(rd)<<7)|0x13
def csrrw(rd, csr, rs1): return (csr<<20)|(R(rs1)<<15)|(0b001<<12)|(R(rd)<<7)|0x73
def csrrs(rd, csr, rs1): return (csr<<20)|(R(rs1)<<15)|(0b010<<12)|(R(rd)<<7)|0x73
def csrrc(rd, csr, rs1): return (csr<<20)|(R(rs1)<<15)|(0b011<<12)|(R(rd)<<7)|0x73
def csrr (rd, csr):      return csrrs(rd, csr, 'x0')
def csrw (csr, rs1):     return csrrw('x0', csr, rs1)
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

ECALL = 0x00000073
MRET  = 0x30200073

MHARTID  = 0xF14
MSTATUS  = 0x300
MTVEC    = 0x305
MEPC     = 0x341
MCAUSE   = 0x342
PMPCFG0  = 0x3A0
PMPADDR0 = 0x3B0
BASE     = 0x80000000

# Layout ajustado p/ acomodar setup PMP (4 ins extra antes do bnez):
HART0_ADDR = 0x8000002C
HART1_ADDR = 0x80000054
HANDLER    = 0x80000080
FAIL_ADDR  = 0x800000B0

ins = []
def addr_of(idx): return BASE + idx*4

# --- Setup (11 instrucoes) ---
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000 (auipc no addr 0)"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
# Compute HANDLER address via auipc PC-relative
auipc_t1_pc = addr_of(len(ins))
ins.append((auipc('t1', 0),          f"auipc t1, 0          # t1 = 0x{auipc_t1_pc:08X}"))
ins.append((addi ('t1','t1', HANDLER - auipc_t1_pc),
                                     f"addi t1, t1, {HANDLER - auipc_t1_pc}  # t1 = HANDLER"))
ins.append((csrw (MTVEC, 't1'),      "csrw mtvec, t1"))
# --- PMP: entry 0 cobre tudo (TOR, R=W=X=1) ---
ins.append((addi ('t1','x0', -1),    "addi t1, x0, -1      # t1 = 0xFFFF...FFFF"))
ins.append((csrw (PMPADDR0, 't1'),   "csrw pmpaddr0, t1    # top of range = max"))
ins.append((addi ('t1','x0', 0x0F),  "addi t1, x0, 0x0F    # R=1,W=1,X=1,A=01(TOR)"))
ins.append((csrw (PMPCFG0, 't1'),    "csrw pmpcfg0, t1     # PMP entry 0 ativa, cobre tudo"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR, f"setup terminou em 0x{addr_of(len(ins)):08X}"

# --- Hart 0: M -> S -> ecall (cause 9) ---
hart0_start = addr_of(len(ins))
ins.append((auipc('t1', 0),          f"auipc t1, 0          # t1 = 0x{hart0_start:08X}"))
# S_ENTRY = hart0_start + 7*4 (auipc, addi, csrw, addi, slli, csrrs, mret) = +28
S_ENTRY = hart0_start + 7*4
ins.append((addi ('t1','t1', S_ENTRY - hart0_start),
                                     f"addi t1, t1, {S_ENTRY - hart0_start}  # t1 = S_ENTRY"))
ins.append((csrw (MEPC, 't1'),       "csrw mepc, t1"))
ins.append((addi ('t1','x0', 1),     "addi t1, x0, 1"))
ins.append((slli ('t1','t1', 11),    "slli t1, t1, 11      # t1 = 0x800 (MPP[11] = 1)"))
ins.append((csrrs('x0', MSTATUS, 't1'),"csrrs zero, mstatus, t1  # mstatus.MPP = 01 (S)"))
ins.append((MRET,                    "mret                 # M -> S, salta para mepc"))
assert addr_of(len(ins)) == S_ENTRY
ins.append((ECALL,                   "ecall                # S-mode: trap p/ M (mcause=9)"))
ins.append((jal('x0', 0),            "jal x0, 0            # safety se ecall nao trapar"))

# Padding/alinhamento ate HART1_ADDR
print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
assert addr_of(len(ins)) == HART1_ADDR

# --- Hart 1: M -> U -> ecall (cause 8) ---
hart1_start = addr_of(len(ins))
ins.append((auipc('t1', 0),          f"auipc t1, 0          # t1 = 0x{hart1_start:08X}"))
U_ENTRY = hart1_start + 7*4
ins.append((addi ('t1','t1', U_ENTRY - hart1_start),
                                     f"addi t1, t1, {U_ENTRY - hart1_start}  # t1 = U_ENTRY"))
ins.append((csrw (MEPC, 't1'),       "csrw mepc, t1"))
ins.append((addi ('t1','x0', 3),     "addi t1, x0, 3"))
ins.append((slli ('t1','t1', 11),    "slli t1, t1, 11      # t1 = 0x1800 (mascara MPP[12:11])"))
ins.append((csrrc('x0', MSTATUS, 't1'),"csrrc zero, mstatus, t1  # mstatus.MPP = 00 (U)"))
ins.append((MRET,                    "mret                 # M -> U"))
assert addr_of(len(ins)) == U_ENTRY
ins.append((ECALL,                   "ecall                # U-mode: trap p/ M (mcause=8)"))
ins.append((jal('x0', 0),            "jal x0, 0            # safety"))

# Padding/alinhamento ate HANDLER
print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}, HANDLER esperado em 0x{HANDLER:08X}")
while addr_of(len(ins)) < HANDLER:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
assert addr_of(len(ins)) == HANDLER

# --- Trap Handler (M-mode, comum aos 2 harts) ---
# Le mcause, grava em 0x8000FF60 (debug), valida em {8,9}, escreve tohost.
ins.append((csrr ('t0', MCAUSE),     "csrr t0, mcause      # ler causa"))
ins.append((sw  ('t0','s0', 0x10),   "sw t0, 0x10(s0)      # debug mcause @ 0x8000FF60"))
ins.append((addi ('t3','x0', 8),     "addi t3, x0, 8       # cause U-ecall"))
ins.append((addi ('t4','x0', 9),     "addi t4, x0, 9       # cause S-ecall"))
# Se t0==t3 (cause==8 == ECALL_U), pula validacao da cause=9.
beq_idx = len(ins)
# bne t0, t3, +8 -> se t0!=8, segue para teste de cause=9; se ==8 segue (skip jal)
ins.append((bne ('t0','t3', 8),      "bne t0, t3, +8       # se t0!=8, segue p/ teste cause=9"))
# t0==8: pula para tohost (skip o bne t0, t4)
ins.append((jal ('x0', 8),           "jal x0, +8           # cause=8 OK, pular bne"))
# t0!=8: testa t0==9
bne_to_fail_idx = len(ins)
bne_to_fail_off = FAIL_ADDR - addr_of(bne_to_fail_idx)
ins.append((bne ('t0','t4', bne_to_fail_off),
                                     f"bne t0, t4, +{bne_to_fail_off} -> FAIL (mcause invalida)"))
# tohost
ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
ins.append((sw  ('t1','s0', 0),      "sw t1, 0(s0)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

# Padding ate FAIL_ADDR
print(f"Handler termina em 0x{addr_of(len(ins)):08X}, FAIL esperado em 0x{FAIL_ADDR:08X}")
while addr_of(len(ins)) < FAIL_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))

ins.append((jal('x0', 0),            "jal x0, 0            # FAIL spin"))

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_e5.hex', 'w') as f:
    f.write("// boot_e5.hex - Transicao de modo M->S/U + trap handler\n")
    f.write("// Hart 0: M->S, ecall (mcause=9)\n")
    f.write("// Hart 1: M->U, ecall (mcause=8)\n")
    f.write("// Handler: valida mcause em {8,9} e escreve tohost.\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
