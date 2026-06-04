"""
Gera boot_e7.hex - M-extension (mul, div, rem).

Cada hart executa operacoes da extensao M e valida os resultados
diretamente em registradores. Sem dependencia de memoria compartilhada
ou coerencia - testa apenas o pipeline integer da CVA6.

Hart 0:  MUL 7 * 6 == 42
Hart 1:  DIV 100 / 7 == 14 e REM 100 % 7 == 2
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

def _r(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(funct3<<12)|(R(rd)<<7)|opcode

def mul (rd, rs1, rs2): return _r(0b0000001, rs2, rs1, 0b000, rd, 0b0110011)
def div (rd, rs1, rs2): return _r(0b0000001, rs2, rs1, 0b100, rd, 0b0110011)
def rem (rd, rs1, rs2): return _r(0b0000001, rs2, rs1, 0b110, rd, 0b0110011)

MHARTID = 0xF14
BASE = 0x80000000

# Layout: hart 0 comeca imediatamente apos bnez (sem padding spin antes!).
HART0_ADDR = 0x80000010
HART1_ADDR = 0x80000040
FAIL_ADDR  = 0x80000088

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('t1', 0x10),     "auipc t1, 0x10"))
ins.append((addi ('t1','t1',-180), "addi t1, t1, -180    # t1 = 0x8000FF50 (tohost)"))
ins.append((csrr ('t0', MHARTID),  "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),   f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

print(f"Setup terminou em 0x{addr_of(len(ins)):08X}, hart 0 esperado em 0x{HART0_ADDR:08X}")
while addr_of(len(ins)) < HART0_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding em 0x{addr_of(len(ins)-1):08X}")
assert addr_of(len(ins)) == HART0_ADDR

# Hart 0: testa MUL
ins.append((addi('t0','x0', 7),      "addi t0, x0, 7       # operando A"))
ins.append((addi('t1','x0', 6),      "addi t1, x0, 6       # operando B"))
ins.append((mul ('t3','t0','t1'),    "mul t3, t0, t1       # 7 * 6 = 42"))
ins.append((addi('t4','x0', 42),     "addi t4, x0, 42      # esperado"))
BNE0_IDX = len(ins)
BNE0_OFF = FAIL_ADDR - addr_of(BNE0_IDX)
ins.append((bne ('t3','t4', BNE0_OFF),f"bne t3, t4, +{BNE0_OFF} -> FAIL"))
# t1 foi sobrescrito (operando), precisa restaurar tohost
ins.append((auipc('t1', 0x10),       "auipc t1, 0x10"))
# recalcular offset para 0x8000FF50 depende do PC atual
t1_pc_idx = len(ins) - 1
t1_pc = addr_of(t1_pc_idx)
t1_off = 0x8000FF50 - (t1_pc + (0x10<<12))
ins.append((addi ('t1','t1', t1_off),f"addi t1, t1, {t1_off}  # t1 = 0x8000FF50"))
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding em 0x{addr_of(len(ins)-1):08X}")
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1: testa DIV e REM
ins.append((addi('t5','x0', 200),    "addi t5, x0, 200     # delay"))
ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
ins.append((addi('t0','x0', 100),    "addi t0, x0, 100     # dividendo"))
ins.append((addi('t1','x0', 7),      "addi t1, x0, 7       # divisor"))
ins.append((div ('t3','t0','t1'),    "div t3, t0, t1       # 100 / 7 = 14"))
ins.append((addi('t4','x0', 14),     "addi t4, x0, 14      # esperado"))
BNE1_IDX = len(ins)
BNE1_OFF = FAIL_ADDR - addr_of(BNE1_IDX)
ins.append((bne ('t3','t4', BNE1_OFF),f"bne t3, t4, +{BNE1_OFF} -> FAIL"))
ins.append((rem ('t3','t0','t1'),    "rem t3, t0, t1       # 100 % 7 = 2"))
ins.append((addi('t4','x0', 2),      "addi t4, x0, 2       # esperado"))
BNE2_IDX = len(ins)
BNE2_OFF = FAIL_ADDR - addr_of(BNE2_IDX)
ins.append((bne ('t3','t4', BNE2_OFF),f"bne t3, t4, +{BNE2_OFF} -> FAIL"))
# restaurar t1 (foi sobrescrito como divisor)
ins.append((auipc('t1', 0x10),       "auipc t1, 0x10"))
t1_pc_idx = len(ins) - 1
t1_pc = addr_of(t1_pc_idx)
t1_off = 0x8000FF50 - (t1_pc + (0x10<<12))
ins.append((addi ('t1','t1', t1_off),f"addi t1, t1, {t1_off}  # t1 = 0x8000FF50"))
ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
ins.append((sw  ('t4','t1', 0),      "sw t4, 0(t1)         # TOHOST"))
ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}, FAIL esperado em 0x{FAIL_ADDR:08X}")
while addr_of(len(ins)) < FAIL_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
    print(f"  padding em 0x{addr_of(len(ins)-1):08X}")

ins.append((jal('x0', 0),            "jal x0, 0            # FAIL spin"))

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_e7.hex', 'w') as f:
    f.write("// boot_e7.hex - M-extension (mul, div, rem)\n")
    f.write("// Hart 0: MUL 7*6==42\n")
    f.write("// Hart 1: DIV 100/7==14 e REM 100%%7==2\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
