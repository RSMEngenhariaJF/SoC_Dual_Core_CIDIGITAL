"""
Gera boot_e3.hex - External interrupt via PLIC mock (mip.MEIP).

Cada hart escreve em endereco do range PLIC enable (0xFFF11020XX), o que
arma plic_enable_any no mock. mock_ext_irq dispara para todos os 4 pinos
irq_i quando armado E mtime > 2000 ciclos. Apos delay aritmetico, cada
hart faz single check em csrr mip aguardando bit MEIP (11).

mip.MEIP = bit 11 (mascara 0x800). Como 0x800 nao cabe em 12-bit signed
addi, usamos lui+srai para construir.

Endereco PLIC enable hart 0 = 0xFFF1102000
Endereco PLIC enable hart 1 = 0xFFF1102080

NOTA: este teste valida o caminho "PLIC write -> ext_irq -> mip.MEIP".
Nao exercita claim/complete real (que exigiria LW MMIO via mock_plic
mais elaborado). E' um BAR minimo que demonstra ponta a ponta o
roteamento do interrupt externo.
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
def and_(rd, rs1, rs2):   return (0<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b111<<12)|(R(rd)<<7)|0x33
def or_ (rd, rs1, rs2):   return (0<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b110<<12)|(R(rd)<<7)|0x33
def csrr (rd, csr):       return (csr<<20)|(R('x0')<<15)|(0b010<<12)|(R(rd)<<7)|0x73
def sw(rs2, rs1, imm12):
    imm = imm12 & 0xFFF
    return ((imm>>5)<<25)|(R(rs2)<<20)|(R(rs1)<<15)|(0b010<<12)|((imm&0x1F)<<7)|0x23
def bnez(rs1, imm13):
    imm = imm13 & 0x1FFF
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(R('x0')<<20)|(R(rs1)<<15)|(0b001<<12)|(b4_1<<8)|(b11<<7)|0x63
def beqz(rs1, imm13):
    imm = imm13 & 0x1FFF
    b12=(imm>>12)&1; b10_5=(imm>>5)&0x3F; b4_1=(imm>>1)&0xF; b11=(imm>>11)&1
    return (b12<<31)|(b10_5<<25)|(0<<20)|(R(rs1)<<15)|(0b000<<12)|(b4_1<<8)|(b11<<7)|0x63
def jal(rd, imm21):
    imm = imm21 & 0x1FFFFF
    b20=(imm>>20)&1; b10_1=(imm>>1)&0x3FF; b11=(imm>>11)&1; b19_12=(imm>>12)&0xFF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(R(rd)<<7)|0x6F

MHARTID = 0xF14
MIP     = 0x344
BASE    = 0x80000000

HART0_ADDR = 0x80000010
HART1_ADDR = 0x80000068

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR

def emit_hart(plic_off_byte, delay_iters, label):
    """Programa PLIC enable, delay longo, single check MEIP, tohost."""
    # Construir endereco PLIC enable = 0xFFF1102000 + offset
    ins.append((addi('t2','x0', 0xFF),   "addi t2, x0, 0xFF"))
    ins.append((slli('t2','t2', 32),     "slli t2, t2, 32      # t2 = 0xFF_00000000"))
    ins.append((lui ('t3', 0xF1102),     "lui t3, 0xF1102      # PLIC enable base low"))
    ins.append((slli('t3','t3', 32),     "slli t3, t3, 32"))
    ins.append((srli('t3','t3', 32),     "srli t3, t3, 32      # zero-extend low 32"))
    ins.append((or_ ('t2','t2','t3'),    f"or t2, t2, t3        # t2 = 0xFF_F1102000"))
    if plic_off_byte != 0:
        ins.append((addi('t2','t2', plic_off_byte),
                                         f"addi t2, t2, {plic_off_byte}      # t2 += offset hart"))
    # SW dummy em PLIC enable (data=1, arma plic_enable_any no mock)
    ins.append((addi('t3','x0', 1),      "addi t3, x0, 1       # enable bit"))
    ins.append((sw  ('t3','t2', 0),      f"sw t3, 0(t2)         # PLIC enable[{label}] = 1"))
    # debug: gravar enable addr em 0x8000FF60+offset
    debug_off = 0x10 if label.endswith("0") else 0x18
    ins.append((sw  ('t2','s0', debug_off), f"sw t2, 0x{debug_off:X}(s0)      # debug enable addr"))
    # Delay aritmetico longo (>2000 ciclos para mock_ext_irq disparar)
    ins.append((addi('t5','x0', delay_iters),
                                         f"addi t5, x0, {delay_iters}      # delay arit"))
    ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
    ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
    # Single check: csrr mip + andi 0x800 (MEIP bit 11)
    # 0x800 nao cabe em andi imm 12-bit signed (max +2047, min -2048; 0x800=2048)
    # Construir mascara via lui + srli ou usar slli em valor menor
    ins.append((csrr('t6', MIP),         "csrr t6, mip"))
    ins.append((sw  ('t6','s0', 0x20),   "sw t6, 0x20(s0)      # debug mip lido"))
    # mascara 0x800: addi 1 + slli 11
    ins.append((addi('t4','x0', 1),      "addi t4, x0, 1"))
    ins.append((slli('t4','t4', 11),     "slli t4, t4, 11      # t4 = 0x800 (MEIP mask)"))
    ins.append((and_('t5','t6','t4'),    "and t5, t6, t4       # bit 11 = MEIP"))
    # Se MEIP nao set, FAIL via salto distante
    ins.append((beqz('t5', 0x100),       "beqz t5, +256        # FAIL se MEIP=0"))
    # tohost
    ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
    ins.append((sw  ('t1','s0', 0),      f"sw t1, 0(s0)         # TOHOST {label}"))
    ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

# Hart 0: PLIC enable @0xFFF1102000, delay 700 iter (~3500 cyc)
emit_hart(plic_off_byte=0, delay_iters=700, label="hart 0")
print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1: PLIC enable @0xFFF1102080, delay 700 iter
emit_hart(plic_off_byte=0x80, delay_iters=700, label="hart 1")
print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}")

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_e3.hex', 'w') as f:
    f.write("// boot_e3.hex - External interrupt via PLIC mock (mip.MEIP)\n")
    f.write("// Hart 0: SW @0xFFF1102000, delay, single check MEIP, tohost\n")
    f.write("// Hart 1: SW @0xFFF1102080, delay, single check MEIP, tohost\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
