"""
Gera boot_b2.hex - AMO suite (RISC-V A-extension).

Hart 0 executa AMOSWAP, AMOADD, AMOXOR em sequência no endereço 0x80002000,
verificando que cada operação retorna o valor anterior correto. No fim,
mem[0x80002000] = 0x2AA. Hart 1 (após delay) faz LW e valida que vê 0x2AA
cross-tile.

Sequência hart 0:
  SW    mem = 0x100
  AMOSWAP 0x200 -> rd=0x100, mem=0x200   (verifica rd == 0x100)
  AMOADD  0x55  -> rd=0x200, mem=0x255   (verifica rd == 0x200)
  AMOXOR  0xFF  -> rd=0x255, mem=0x2AA   (verifica rd == 0x255)
  SW    tohost = 1
Hart 1:
  delay
  LW mem (deve ver 0x2AA)
  SW tohost = 1
"""

REGS = {'zero':0,'ra':1,'sp':2,'gp':3,'tp':4,
        't0':5,'t1':6,'t2':7,
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

# AMO instructions (funct5, funct3=010 for W)
def _amo(funct5, rd, rs2, rs1, aq=0, rl=0):
    funct7 = (funct5 << 2) | (aq << 1) | rl
    return (funct7 << 25) | (R(rs2) << 20) | (R(rs1) << 15) | (0b010 << 12) | (R(rd) << 7) | 0x2F

def amoswap_w(rd, rs2, rs1): return _amo(0b00001, rd, rs2, rs1)
def amoadd_w (rd, rs2, rs1): return _amo(0b00000, rd, rs2, rs1)
def amoxor_w (rd, rs2, rs1): return _amo(0b00100, rd, rs2, rs1)
def amoor_w  (rd, rs2, rs1): return _amo(0b01000, rd, rs2, rs1)
def amoand_w (rd, rs2, rs1): return _amo(0b01100, rd, rs2, rs1)
def amomin_w (rd, rs2, rs1): return _amo(0b10000, rd, rs2, rs1)
def amomax_w (rd, rs2, rs1): return _amo(0b10100, rd, rs2, rs1)

MHARTID = 0xF14
BASE = 0x80000000

# Layout planejado:
# Setup: 5 instr, 0x00..0x10
# Hart 0: 17 instr, 0x14..0x54
# Hart 1: 9 instr,  0x58..0x78
# Fail:  1 instr,  0x7C
HART1_ADDR = 0x80000058
FAIL_ADDR  = 0x8000007C

ins = []  # lista de (code, asm)

# Setup
ins.append((auipc('t2', 2),        "auipc t2, 2          # t2 = 0x80002000"))
ins.append((auipc('t1', 0x10),     "auipc t1, 0x10"))
ins.append((addi ('t1','t1',-180), "addi t1, t1, -180    # t1 = 0x8000FF50"))
ins.append((csrr ('t0', MHARTID),  "csrr t0, mhartid"))

H1_OFF = HART1_ADDR - (BASE + 0x10)
ins.append((bnez ('t0', H1_OFF),   f"bnez t0, +{H1_OFF}  -> 0x{HART1_ADDR:08X}"))

# Hart 0 - AMO suite
# Calcula offsets de bne usando posicoes conhecidas
# Cada instrucao tem 4 bytes; calcula no momento da emissao
def addr_of(idx):  # idx zero-based dentro de ins
    return BASE + idx*4

# instr 5..21 (indices 5 a 21) = hart 0, 17 instr
# bne em hart 0 sao indices 9, 13, 17 (relativos a posicao corrente)

# 1. SW inicial
ins.append((addi('t3','x0', 0x100),   "addi t3, x0, 0x100   # initial value"))
ins.append((sw  ('t3','t2', 0),       "sw t3, 0(t2)         # mem = 0x100"))
# 2. AMOSWAP
ins.append((addi('t3','x0', 0x200),   "addi t3, x0, 0x200   # swap operand"))
ins.append((amoswap_w('t6','t3','t2'),"amoswap.w t6, t3, (t2)  # rd=mem, mem=t3"))
ins.append((addi('t4','x0', 0x100),   "addi t4, x0, 0x100   # expected old=0x100"))
# bne index 9, fail at idx (FAIL_ADDR-BASE)/4 = 31
bne_idx = len(ins)
bne_off = FAIL_ADDR - addr_of(bne_idx)
ins.append((bne ('t6','t4', bne_off), f"bne t6, t4, +{bne_off} -> FAIL (amoswap check)"))
# 3. AMOADD
ins.append((addi('t3','x0', 0x55),    "addi t3, x0, 0x55    # add operand"))
ins.append((amoadd_w ('t6','t3','t2'),"amoadd.w t6, t3, (t2)   # rd=mem, mem+=t3"))
ins.append((addi('t4','x0', 0x200),   "addi t4, x0, 0x200   # expected old=0x200"))
bne_idx = len(ins)
bne_off = FAIL_ADDR - addr_of(bne_idx)
ins.append((bne ('t6','t4', bne_off), f"bne t6, t4, +{bne_off} -> FAIL (amoadd check)"))
# 4. AMOXOR
ins.append((addi('t3','x0', 0xFF),    "addi t3, x0, 0xFF    # xor operand"))
ins.append((amoxor_w ('t6','t3','t2'),"amoxor.w t6, t3, (t2)   # rd=mem, mem^=t3"))
ins.append((addi('t4','x0', 0x255),   "addi t4, x0, 0x255   # expected old=0x255"))
bne_idx = len(ins)
bne_off = FAIL_ADDR - addr_of(bne_idx)
ins.append((bne ('t6','t4', bne_off), f"bne t6, t4, +{bne_off} -> FAIL (amoxor check)"))
# Sucesso hart 0
ins.append((addi('t4','x0', 1),       "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),       "sw t4, 0(t1)         # TOHOST = 1"))
ins.append((jal ('x0', 0),            "jal x0, 0            # spin"))

# Hart 1 - delay + LW + verify
assert addr_of(len(ins)) == HART1_ADDR, \
    f"Hart 1 nao alinhado: esperado 0x{HART1_ADDR:08X}, real 0x{addr_of(len(ins)):08X}"

ins.append((addi('t5','x0', 500),     "addi t5, x0, 500     # delay long"))
ins.append((addi('t5','t5', -1),      "addi t5, t5, -1"))
ins.append((bnez('t5', -4),           "bnez t5, -4          # delay loop"))
ins.append((lw  ('t6','t2', 0),       "lw t6, 0(t2)         # le mem (cross-tile)"))
ins.append((addi('t4','x0', 0x2AA),   "addi t4, x0, 0x2AA   # expected: 0x255 XOR 0xFF"))
bne_idx = len(ins)
bne_off = FAIL_ADDR - addr_of(bne_idx)
ins.append((bne ('t6','t4', bne_off), f"bne t6, t4, +{bne_off} -> FAIL (cross-tile check)"))
ins.append((addi('t4','x0', 1),       "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),       "sw t4, 0(t1)         # TOHOST = 1"))
ins.append((jal ('x0', 0),            "jal x0, 0            # spin"))

# Fail spin
assert addr_of(len(ins)) == FAIL_ADDR, \
    f"Fail nao alinhado: esperado 0x{FAIL_ADDR:08X}, real 0x{addr_of(len(ins)):08X}"
ins.append((jal ('x0', 0),            "jal x0, 0            # FAIL spin"))

# Escreve arquivo
with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_b2.hex', 'w') as f:
    f.write("// boot_b2.hex - AMO suite (RISC-V A-extension)\n")
    f.write("// Hart 0 executa AMOSWAP, AMOADD, AMOXOR em 0x80002000 e valida\n")
    f.write("// cada retorno. Hart 1 (apos delay) le o resultado final = 0x2AA.\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"OK - {len(ins)} instrucoes (Hart1 @ 0x{HART1_ADDR:08X}, FAIL @ 0x{FAIL_ADDR:08X})")
