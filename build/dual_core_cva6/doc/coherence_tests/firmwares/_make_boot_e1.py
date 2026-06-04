"""
Gera boot_e1.hex - Timer interrupt (CLINT mtimecmp).

Cada hart programa seu proprio mtimecmp[hart] = pequeno valor (que sera
ultrapassado pelo contador mtime no mock tb v2), depois faz polling em
csrr mip aguardando o bit MTIP (7) ser setado. Quando observa, escreve
tohost.

Endereços CLINT (NC, fora da janela cacheavel):
  mtimecmp[0] = 0xFFF1024000
  mtimecmp[1] = 0xFFF1024008

Para construir 0xFFF1024000 em registrador, usamos a tecnica de
addi+slli+lui+slli+srli+or (mesma de E2).

mip.MTIP = bit 7 (mascara 0x80).

Validacao: GOOD TRAP AMBOS TILES com mock_timer_irq elevando-se
quando mtime do mock supera o mtimecmp gravado por cada hart.
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
HART1_ADDR = 0x80000060

ins = []
def addr_of(idx): return BASE + idx*4

# Setup
ins.append((auipc('s0', 0x10),       "auipc s0, 0x10       # s0 = 0x80010000"))
ins.append((addi ('s0','s0',-176),   "addi s0, s0, -176    # s0 = 0x8000FF50 (tohost)"))
ins.append((csrr ('t0', MHARTID),    "csrr t0, mhartid"))
H1_OFF = HART1_ADDR - addr_of(len(ins))
ins.append((bnez ('t0', H1_OFF),     f"bnez t0, +{H1_OFF} -> 0x{HART1_ADDR:08X}"))

assert addr_of(len(ins)) == HART0_ADDR

def emit_hart(mtimecmp_low_imm, mtimecmp_addr_low_byte, delay_iters, label):
    """Programa mtimecmp[hart], delay aritmetico longo, single check MTIP, tohost.

    Evitamos polling apertado csrr/andi/beqz por suspeita de que loops
    longos com csrr saturam o pipeline ou kernel xsim. Estrategia:
    grava mtimecmp pequeno, espera tempo suficiente via ADDI loop
    (sem CSR access), depois faz UM csrr mip + andi + bne para
    validar que MTIP virou 1 nesse intervalo. Se nao virou, FAIL.
    """
    # Construir endereco mtimecmp em t2
    ins.append((addi('t2','x0', 0xFF),   "addi t2, x0, 0xFF    # high byte 39:32"))
    ins.append((slli('t2','t2', 32),     "slli t2, t2, 32      # t2 = 0xFF_00000000"))
    ins.append((lui ('t3', 0xF1024),     "lui t3, 0xF1024      # t3 (sign-ext)"))
    ins.append((slli('t3','t3', 32),     "slli t3, t3, 32"))
    ins.append((srli('t3','t3', 32),     "srli t3, t3, 32      # t3 = 0x00000000_F1024000"))
    ins.append((or_ ('t2','t2','t3'),    f"or t2, t2, t3        # t2 = mtimecmp base"))
    if mtimecmp_addr_low_byte != 0:
        ins.append((addi('t2','t2', mtimecmp_addr_low_byte),
                                         f"addi t2, t2, {mtimecmp_addr_low_byte}      # t2 += offset"))
    # Programar mtimecmp[hart]
    ins.append((addi('t3','x0', mtimecmp_low_imm),
                                         f"addi t3, x0, {mtimecmp_low_imm}      # mtimecmp valor"))
    ins.append((sw  ('t3','t2', 0),      f"sw t3, 0(t2)         # mtimecmp[{label}] = {mtimecmp_low_imm}"))
    # Delay aritmetico longo (so ADDI, sem CSR ou memoria)
    ins.append((addi('t5','x0', delay_iters),
                                         f"addi t5, x0, {delay_iters}      # delay arit longo"))
    ins.append((addi('t5','t5', -1),     "addi t5, t5, -1"))
    ins.append((bnez('t5', -4),          "bnez t5, -4          # delay loop"))
    # Apos delay, mtime deve ja ter superado mtimecmp -> MTIP=1
    # UM unico csrr + check (sem loop)
    ins.append((csrr('t6', MIP),         "csrr t6, mip"))
    # debug: gravar mip lido em 0x8000FF60+offset
    debug_off = 0x10 if label.endswith("0") else 0x18
    ins.append((sw  ('t6','s0', debug_off), f"sw t6, 0x{debug_off:X}(s0)      # debug mip lido"))
    ins.append((andi('t5','t6', 0x80),   "andi t5, t6, 0x80    # bit 7 = MTIP"))
    # Se MTIP nao set (t5==0), FAIL via salto distante
    ins.append((beqz('t5', 0x100),       "beqz t5, +256        # FAIL se MTIP=0"))
    # tohost
    ins.append((addi('t1','x0', 1),      "addi t1, x0, 1"))
    ins.append((sw  ('t1','s0', 0),      f"sw t1, 0(s0)         # TOHOST {label}"))
    ins.append((jal ('x0', 0),           "jal x0, 0            # spin success"))

# Hart 0: programa mtimecmp[0]=300, espera 500 iter (~2500 ciclos)
emit_hart(mtimecmp_low_imm=300, mtimecmp_addr_low_byte=0, delay_iters=500, label="hart 0")
print(f"Hart 0 termina em 0x{addr_of(len(ins)):08X}, hart 1 esperado em 0x{HART1_ADDR:08X}")
while addr_of(len(ins)) < HART1_ADDR:
    ins.append((jal('x0', 0), "jal x0, 0  # padding"))
assert addr_of(len(ins)) == HART1_ADDR

# Hart 1: programa mtimecmp[1]=400, espera 500 iter
emit_hart(mtimecmp_low_imm=400, mtimecmp_addr_low_byte=8, delay_iters=500, label="hart 1")
print(f"Hart 1 termina em 0x{addr_of(len(ins)):08X}")

with open(r'C:\Users\rafae\Documents\SoC_dual_core\openpiton\build\dual_core_cva6\tb\boot_e1.hex', 'w') as f:
    f.write("// boot_e1.hex - Timer interrupt via mtimecmp (polling MTIP)\n")
    f.write("// Hart 0: mtimecmp[0]=600, polling MTIP, tohost\n")
    f.write("// Hart 1: mtimecmp[1]=900, polling MTIP, tohost\n")
    f.write("//\n")
    addr = BASE
    for code, asm in ins:
        f.write(f"// {addr:08X}  {code:08X}  {asm}\n")
        addr += 4
    f.write("//\n")
    for code, _ in ins:
        f.write(f"{code:08X}\n")

print(f"\nOK - {len(ins)} instrucoes total")
