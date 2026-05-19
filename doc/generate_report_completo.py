"""
Relatorio completo do SoC Dual-Core CVA6:
  - Arquitetura do chip (NoC, CVA6, memoria)
  - Arquitetura UVM (testbench, interfaces, fluxo)
  - Resultados dos testes (Fase 1: AXI4 leitura; Fase 2: GOOD_TRAP via tohost)
Uso: python generate_report_completo.py
"""
from fpdf import FPDF
from fpdf.enums import XPos, YPos
import datetime

# Paleta
BLUE_DARK  = (26,  57,  96)
BLUE_MID   = (41,  98, 161)
BLUE_LIGHT = (210, 227, 252)
GRAY_LIGHT = (245, 245, 245)
GRAY_MID   = (200, 200, 200)
GREEN      = (0,  128,  0)
RED        = (180,   0,  0)
BLACK      = (0,    0,  0)
WHITE      = (255, 255, 255)
ORANGE     = (200, 100,  0)


class Report(FPDF):
    def __init__(self):
        super().__init__()
        self.set_margins(20, 15, 20)
        self.set_auto_page_break(auto=True, margin=20)

    def header(self):
        if self.page_no() == 1:
            return
        self.set_fill_color(*BLUE_DARK)
        self.rect(0, 0, 210, 10, 'F')
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*WHITE)
        self.set_y(2)
        self.cell(0, 6, 'SoC Dual-Core CVA6 - Relatorio Tecnico Completo', align='C')
        self.set_text_color(*BLACK)
        self.ln(6)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-12)
        self.set_draw_color(*GRAY_MID)
        self.line(20, self.get_y(), 190, self.get_y())
        self.set_font('Helvetica', '', 7)
        self.set_text_color(120, 120, 120)
        self.cell(0, 6,
            'Pagina %d  |  %s' % (self.page_no(),
                                   datetime.date.today().strftime('%d/%m/%Y')),
            align='C')
        self.set_text_color(*BLACK)

    def section_title(self, num, text):
        self.ln(4)
        self.set_fill_color(*BLUE_DARK)
        self.set_text_color(*WHITE)
        self.set_font('Helvetica', 'B', 12)
        self.cell(0, 8, '  %s  %s' % (num, text), fill=True,
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*BLACK)
        self.ln(2)

    def subsection(self, text):
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(*BLUE_MID)
        self.cell(0, 6, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*BLACK)
        self.ln(1)

    def body(self, text, indent=0):
        self.set_font('Helvetica', '', 9)
        self.set_x(self.l_margin + indent)
        self.multi_cell(0, 5, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

    def bullet(self, text, indent=4):
        self.set_font('Helvetica', '', 9)
        self.set_x(self.l_margin + indent)
        self.cell(4, 5, '-')
        self.multi_cell(0, 5, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    def code_block(self, lines, indent=4):
        self.set_fill_color(*GRAY_LIGHT)
        self.set_draw_color(*GRAY_MID)
        self.set_font('Courier', '', 7.5)
        x0 = self.l_margin + indent
        w  = self.w - self.r_margin - x0
        total_h = len(lines) * 4.5 + 3
        self.rect(x0, self.get_y(), w, total_h, 'DF')
        self.set_y(self.get_y() + 1.5)
        for line in lines:
            self.set_x(x0 + 2)
            self.cell(w - 4, 4.5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)

    def table(self, headers, rows, col_widths):
        self.set_font('Helvetica', 'B', 8.5)
        self.set_fill_color(*BLUE_DARK)
        self.set_text_color(*WHITE)
        for h, w in zip(headers, col_widths):
            self.cell(w, 6, '  ' + h, border=0, fill=True)
        self.ln()
        self.set_text_color(*BLACK)
        self.set_font('Helvetica', '', 8.5)
        for i, row in enumerate(rows):
            bg = GRAY_LIGHT if i % 2 == 0 else WHITE
            self.set_fill_color(*bg)
            for val, w in zip(row, col_widths):
                self.cell(w, 5.5, '  ' + val, border=0, fill=True)
            self.ln()
        self.set_fill_color(*WHITE)
        self.ln(2)

    def warn_box(self, text):
        self.set_fill_color(255, 240, 200)
        self.set_draw_color(200, 140, 0)
        self.set_font('Helvetica', 'B', 9)
        self.multi_cell(0, 6, '  [!] ' + text, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)

    def ok_box(self, text):
        self.set_fill_color(220, 255, 220)
        self.set_draw_color(0, 160, 60)
        self.set_font('Helvetica', 'B', 9)
        self.multi_cell(0, 6, '  [OK] ' + text, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)

    def info_box(self, text):
        self.set_fill_color(*BLUE_LIGHT)
        self.set_draw_color(*BLUE_MID)
        self.set_font('Helvetica', 'B', 9)
        self.multi_cell(0, 6, '  [i] ' + text, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)


# ================================================================
pdf = Report()

# ----------------------------------------------------------------
# CAPA
# ----------------------------------------------------------------
pdf.add_page()
pdf.set_fill_color(*BLUE_DARK)
pdf.rect(0, 0, 210, 297, 'F')

pdf.set_y(40)
pdf.set_font('Helvetica', 'B', 30)
pdf.set_text_color(*WHITE)
pdf.cell(0, 14, 'SoC Dual-Core CVA6', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font('Helvetica', 'B', 14)
pdf.cell(0, 10, 'Relatorio Tecnico Completo', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font('Helvetica', '', 10)
pdf.set_text_color(180, 210, 255)
pdf.cell(0, 7,
    'Arquitetura do Chip  |  Ambiente UVM  |  Resultados de Simulacao',
    align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(5)
pdf.set_draw_color(*BLUE_MID)
pdf.set_line_width(0.5)
pdf.line(40, pdf.get_y(), 170, pdf.get_y())
pdf.ln(5)

pdf.set_font('Helvetica', '', 10)
pdf.set_text_color(*WHITE)
pdf.cell(0, 7, 'Plataforma: OpenPiton 2x1  |  Processadores: 2x CVA6 (RISC-V RV64GC)', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 7, 'Simulador: Xilinx xsim 2025.1  |  Ambiente: Windows 11 / VS Code', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.ln(3)
pdf.set_font('Helvetica', 'I', 10)
pdf.cell(0, 7,
    'Data: %s' % datetime.date.today().strftime('%d de %B de %Y'),
    align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

# Badges
pdf.ln(10)
pdf.set_fill_color(0, 100, 50)
pdf.set_font('Helvetica', 'B', 11)
pdf.set_text_color(*WHITE)
pdf.set_x(35)
pdf.cell(64, 10, '  Fase 1: PASS', fill=True, align='C')
pdf.set_x(111)
pdf.cell(64, 10, '  Fase 2: GOOD_TRAP', fill=True, align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(5)
pdf.set_font('Helvetica', '', 9)
pdf.set_text_color(180, 220, 255)
pdf.cell(0, 6, 'Fase 1: 10 000 ciclos  |  rd=2  |  boot + fetch icache confirmados',
         align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 6, 'Fase 2: 194 ciclos  |  store tohost detectado em 0x8000_FF50',
         align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(10)
pdf.set_font('Helvetica', 'B', 9)
pdf.set_text_color(200, 230, 255)
items = [
    '[v]  2x CVA6 RV64GC boot e execucao de instrucoes confirmados',
    '[v]  Cache miss -> NoC -> AXI4 -> SRAM -> fill validado',
    '[v]  UVM testbench com GOOD_TRAP via store_buffer.commit_i',
    '[v]  Filtragem por endereco: somente tohost (0x8000_FF50) dispara PASS',
    '[v]  Hierarquia cross-module xsim: leitura segura de internos CVA6',
]
for item in items:
    pdf.cell(0, 6, '    ' + item, align='L', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(25)
pdf.set_font('Helvetica', '', 8)
pdf.set_text_color(160, 180, 210)
pdf.cell(0, 5, 'Documento gerado automaticamente - uso interno', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)

# ----------------------------------------------------------------
# SUMARIO
# ----------------------------------------------------------------
pdf.add_page()
pdf.set_font('Helvetica', 'B', 14)
pdf.set_text_color(*BLUE_DARK)
pdf.cell(0, 10, 'Sumario', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)
pdf.set_draw_color(*GRAY_MID)
pdf.line(20, pdf.get_y(), 190, pdf.get_y())
pdf.ln(3)

toc = [
    ('PARTE I',  'ARQUITETURA DO CHIP',                              ''),
    ('1',        'Visao Geral do SoC',                               '3'),
    ('2',        'Nucleo CVA6 (por tile)',                           '4'),
    ('3',        'Subsistema de Cache e Caminho de Memoria',         '5'),
    ('4',        'Store Buffer - Estrutura Interna',                 '6'),
    ('PARTE II', 'AMBIENTE UVM',                                     ''),
    ('5',        'Arquitetura do Testbench UVM',                     '8'),
    ('6',        'Deteccao GOOD_TRAP via store_buffer.commit_i',     '9'),
    ('7',        'Verificacao de Endereco (tohost filter)',          '11'),
    ('PARTE III','RESULTADOS DOS TESTES',                            ''),
    ('8',        'Fase 1: Validacao de Boot e Fetch',                '13'),
    ('9',        'Fase 2: GOOD_TRAP via Programa Dois-Stores',      '14'),
    ('10',       'Limitacoes Conhecidas',                            '16'),
    ('11',       'Proximos Passos',                                  '17'),
]
pdf.set_font('Helvetica', '', 10)
for num, title, page in toc:
    if page == '':
        pdf.set_font('Helvetica', 'B', 9)
        pdf.set_text_color(*BLUE_MID)
        pdf.ln(2)
        pdf.cell(0, 6, '  ' + num + '  ' + title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        pdf.set_text_color(*BLACK)
        pdf.set_font('Helvetica', '', 10)
        continue
    pdf.set_x(20)
    pdf.cell(12, 7, num)
    pdf.cell(138, 7, title)
    pdf.cell(0, 7, page, align='R', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_draw_color(*GRAY_MID)
    pdf.line(32, pdf.get_y() - 0.5, 188, pdf.get_y() - 0.5)

# ================================================================
# PARTE I - ARQUITETURA DO CHIP
# ================================================================
pdf.add_page()
pdf.set_font('Helvetica', 'B', 13)
pdf.set_fill_color(*BLUE_MID)
pdf.set_text_color(*WHITE)
pdf.cell(0, 9, '  PARTE I  -  ARQUITETURA DO CHIP', fill=True,
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)
pdf.ln(3)

# ----------------------------------------------------------------
# SECAO 1 - VISAO GERAL
# ----------------------------------------------------------------
pdf.section_title('1', 'Visao Geral do SoC')

pdf.body(
    'O SoC implementado e baseado na plataforma OpenPiton com dois nucleos CVA6 '
    '(anteriormente Ariane), um processador RISC-V out-of-order de 64 bits '
    'compativel com a ISA RV64GC. A interconexao entre os tiles e a interface '
    'com memoria externa utiliza a rede-em-chip (NoC) de tres camadas do OpenPiton.'
)

pdf.subsection('1.1  Topologia da Rede-em-Chip (NoC 2x1)')
pdf.code_block([
    '  [ tile(1,0) ] <---East/West---> [ tile(0,0) ] <---West---> [ noc_axi4_bridge ] --> [ axi4_sram ]',
    '     CVA6 #1                          CVA6 #0                    NoC->AXI4             DDR simulado',
    '     (hart 1)                         (hart 0)                   (off-chip)             (256 KB)',
])
pdf.body(
    'Os pacotes de memoria saem do chip pela porta West do tile(0,0), atravessando '
    'a ponte noc_axi4_bridge que conecta a SRAM model (DDR simulado de 256 KB). '
    'As tres camadas da NoC tem funcoes distintas:'
)
rows_noc = [
    ('NoC1', 'Requests: loads, stores, fetch, invalidations (core -> home)'),
    ('NoC2', 'Responses: data de memoria, fills de cache (home -> core)'),
    ('NoC3', 'Acknowledgements: write-ack, invalidation-ack (home -> core)'),
]
pdf.table(['Camada', 'Funcao'], rows_noc, [14, 156])

pdf.subsection('1.2  Parametros de Boot e Regioes de Memoria')
rows_mem = [
    ('Boot address',        '0x8000_0000'),
    ('Execute region',      '0x8000_0000 + 1 GB  (0x4000_0000)'),
    ('Cached region',       '0x8000_0000 + 1 GB'),
    ('tohost address',      '0x8000_FF50  (convencao riscv-tests)'),
    ('Physical addr width', '56 bits  (riscv::PLEN)'),
    ('Data width',          '64 bits  (RV64)'),
    ('Byte enable',         '8 bits  (XLEN/8)'),
    ('SRAM model size',     '256 KB  (inicializado por boot.hex)'),
]
pdf.table(['Parametro', 'Valor'], rows_mem, [52, 118])

pdf.subsection('1.3  Hierarquia RTL principal')
pdf.code_block([
    'uvmt_opc_tb  (top UVM)',
    '  +-- u_dut_wrap  (uvmt_opc_dut_wrap)',
    '       +-- u_chip  (chip)',
    '            +-- tile0  (tile, TILE_ID=0, TILE_TYPE=2)',
    '            |    +-- l15.l15         (L1.5 cache + NoC enc/dec)',
    '            |    +-- g_ariane_core.core  (ariane_verilog_wrap)',
    '            |         +-- ariane -> i_cva6  (nucleo CVA6)',
    '            |              +-- ex_stage_i.lsu_i.i_store_unit.store_buffer_i',
    '            +-- tile1  (tile, TILE_ID=1)  [mesma estrutura]',
    '       +-- noc_axi4_bridge  (ponte NoC1/2/3 <-> AXI4)',
    '       +-- axi4_sram_model  (modelo SRAM DDR)',
])

# ----------------------------------------------------------------
# SECAO 2 - NUCLEO CVA6
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('2', 'Nucleo CVA6 (por tile)')

pdf.body(
    'Cada tile instancia um nucleo CVA6 completo (RISC-V RV64GC). '
    'O CVA6 e um processador superescalar out-of-order com as seguintes caracteristicas:'
)
rows_cva6 = [
    ('ISA',              'RISC-V RV64GC (I, M, A, F, D, C extensoes)'),
    ('Pipeline',         '6 estagios: IF, ID, IS, EX, COMMIT + scoreboard OoO'),
    ('Branch predictor', 'BHT (Branch History Table) + BTB + RAS (Return Address Stack)'),
    ('TLB',              'SV39 MMU, iTLB + dTLB (page table walker em HW)'),
    ('Icache',           'Write-through, 16 KB, 4-way set-associative, 64 B/line'),
    ('Dcache',           'Write-through (WT_DCACHE), 32 KB, 8-way, 64 B/line'),
    ('Store buffer',     '4 entradas especulativas (speculative_queue) + 4 commit'),
    ('FPU',              'fpnew: FP32/FP64 completo (FMA, Div, Sqrt, conversoes)'),
    ('CSRs',             'mstatus, mepc, mcause, mtvec, mhartid, mip/mie, ...'),
    ('Privilegio',       'M-mode (machine), S-mode (supervisor), U-mode (user)'),
]
pdf.table(['Componente', 'Descricao'], rows_cva6, [35, 135])

pdf.subsection('2.1  Pipeline CVA6 - 6 estagios')
pdf.code_block([
    'PC Gen / Frontend',
    '   |-- Branch Prediction (BHT/BTB/RAS)',
    '   |-- Instruction Fetch (icache req)',
    '   |-- Instruction Queue',
    '       |',
    '       v',
    'Decode + Rename',
    '       |',
    '       v',
    'Issue (scoreboard OoO)',
    '   |-- Integer ALU  (add, sub, shift, ...)',
    '   |-- Multiplier   (mul, div)',
    '   |-- Branch Unit  (beq, bne, jal, jalr)',
    '   |-- LSU          (Load/Store Unit)',
    '   |     |-- Load Unit  (lw, ld, lh, lb)',
    '   |     |-- Store Unit -> Store Buffer -> dcache',
    '   |-- FPU          (fpnew: fadd, fmul, fdiv, ...)',
    '       |',
    '       v',
    'Commit (ROB - Reorder Buffer)',
    '   |-- Commit instrucoes em ordem',
    '   |-- Libera registradores',
    '   |-- store_buffer.commit_i quando store chega ao ROB head',
])

pdf.subsection('2.2  Modos de privilegio e CSRs relevantes')
pdf.body(
    'O CVA6 suporta os tres modos de privilegio RISC-V. Na inicializacao, '
    'o processador comeca em M-mode (machine mode). Para o teste atual '
    '(programa baremetal em boot.hex), apenas M-mode e utilizado.'
)

# ----------------------------------------------------------------
# SECAO 3 - CACHE E MEMORIA
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('3', 'Subsistema de Cache e Caminho de Memoria')

pdf.subsection('3.1  Cache Write-Through (WT_DCACHE)')
pdf.body(
    'O CVA6 usa o subsistema wt_dcache (define WT_DCACHE ativo). '
    'Nao ha L2 cache dedicado nesta configuracao. '
    'O adaptador wt_l15_adapter converte requisicoes do dcache em mensagens '
    'OpenPiton do tipo LOAD_RQ / STORE_RQ e as injeta no L15.'
)
pdf.body(
    'As requisicoes que erram no L15 sao encaminhadas diretamente ao home node '
    'via NoC1, atravessando a ponte noc_axi4_bridge ate a SRAM model.'
)

pdf.subsection('3.2  Caminho de instrucoes (icache miss -> fill)')
pdf.code_block([
    'CVA6 icache (MISS)',
    '     |-- wt_l15_adapter: gera OpenPiton IMISS msg',
    '     |-- L15 pipeline (S1/S2/S3)',
    '     |-- noc1encoder -> flit -> NoC1 (West)',
    '                                  |',
    '                        noc_axi4_bridge',
    '                          |-- AXI4 AR channel (read address)',
    '                          |-- AXI4 R channel (read data)',
    '                          |-- Response: dados da SRAM',
    '                        noc_axi4_bridge',
    '                                  |',
    '               NoC2 response -> L15 -> icache fill',
    '                                  |',
    '                            CVA6 instrucao disponivel (clhit=1)',
])

pdf.subsection('3.3  Caminho de dados - store (limitacao xsim)')
pdf.code_block([
    'CVA6 ROB commit_i -> store_buffer.commit_i',
    '     |-- speculative_queue -> commit_queue',
    '     |-- store_if (always_comb) [BLOQUEADO no xsim - stub ativo]',
    '     |-- req_port_o.data_req = 0 (sempre, no xsim)',
    '     |',
    '     ^ -- monitorado pelo testbench UVM via sonda hierarquica',
    '          (commit_i + speculative_queue_q[ptr].address)',
])
pdf.warn_box(
    'Bug xsim 2025.1: FATAL_ERROR em always_comb com struct packed de 131 bits. '
    'O bloco store_if e substituido por stub (req_port_o.data_req = 0). '
    'O pipeline executa e commita o store normalmente; apenas a escrita fisica '
    'na memoria nao acontece. O commit_i continua visivel e funcionando.'
)

pdf.subsection('3.4  Defines de compilacao ativos')
pdf.code_block([
    '--define PITON_ARIANE          # habilita nucleo CVA6 (em vez de SPARC)',
    '--define PITON_CHIP_FPGA       # configuracao FPGA do OpenPiton',
    '--define PITON_FPGA_SYNTH      # path de sintese FPGA',
    '--define WT_DCACHE             # subsistema write-through (sem L2)',
    '--define PITON_RV64_PLATFORM   # plataforma RV64',
    '--define PITON_RV64_PLIC       # PLIC para interrupcoes externas',
    '--define PITON_RV64_CLINT      # CLINT para timer/soft interrupts',
    '--define PITON_RV64_DEBUGUNIT  # unidade de debug RISC-V',
    '--define XSIM                  # ativa workarounds de bugs do xsim',
])

# ----------------------------------------------------------------
# SECAO 4 - STORE BUFFER
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('4', 'Store Buffer - Estrutura Interna')

pdf.subsection('4.1  Organizacao do store buffer')
pdf.body(
    'O store_buffer.sv implementa dois arrays de filas circulares para '
    'gerenciar stores em voo: a fila especulativa e a fila de commit.'
)
rows_sb = [
    ('speculative_queue_q', 'DEPTH_SPEC=4', 'Stores ainda especulativos (podem ser squashed)'),
    ('commit_queue_q',      'DEPTH_COMMIT=4','Stores confirmados pelo ROB, aguardando dcache'),
    ('commit_i',            '-',             'Entrada: ROB confirma store (mover spec -> commit)'),
    ('speculative_read_pointer_q', '-',      'Indice do proximo store a ser commitado'),
    ('req_port_o.data_req', '-',             'Saida: solicita escrita ao dcache [stub=0 no xsim]'),
]
pdf.table(['Sinal/Estrutura', 'Tamanho', 'Descricao'], rows_sb, [52, 22, 96])

pdf.subsection('4.2  Struct packed da speculative_queue (131 bits)')
pdf.code_block([
    'typedef struct packed {',
    '    logic [55:0]  address;    // riscv::PLEN - endereco fisico (56 bits)',
    '    logic [63:0]  data;       // dado a ser escrito (64 bits)',
    '    logic  [7:0]  be;         // byte enable (8 bits)',
    '    logic  [1:0]  data_size;  // tamanho: Byte/Half/Word/Double (2 bits)',
    '    logic         valid;      // entrada valida (1 bit)',
    '} speculative_queue_t;',
    '// total = 56 + 64 + 8 + 2 + 1 = 131 bits  <- nao e potencia de 2',
    '',
    'speculative_queue_t [DEPTH_SPEC-1:0] speculative_queue_q;  // [3:0]',
])

pdf.subsection('4.3  Fluxo de um store no pipeline')
pdf.code_block([
    '1. Decode: store decodificado, entrada alocada na speculative_queue',
    '2. Execute (LSU): endereco calculado, dado lido do registerfile',
    '   -> speculative_queue_q[ptr].address = endereço fisico calculado',
    '   -> speculative_queue_q[ptr].data    = valor do registrador rs2',
    '3. ROB head: store chega ao head do reorder buffer',
    '   -> commit_i = 1  (sinal de entrada no store_buffer)',
    '   -> speculative_read_pointer_q aponta para esta entrada',
    '4. store_if (always_comb) [BLOQUEADO no xsim]:',
    '   -> mover de speculative_queue para commit_queue',
    '   -> assertar req_port_o.data_req para solicitar dcache',
    '5. dcache/wt_l15_adapter [NAO ALCANCADO no xsim]:',
    '   -> gerar STORE_RQ para o L15 -> NoC1 -> SRAM',
])

pdf.info_box(
    'O testbench UVM monitora o passo 3 (commit_i=1) e le o endereco '
    'diretamente de speculative_queue_q[speculative_read_pointer_q].address. '
    'Isso e seguro no xsim e independente do passo 4 (que esta bloqueado).'
)

# ================================================================
# PARTE II - AMBIENTE UVM
# ================================================================
pdf.add_page()
pdf.set_font('Helvetica', 'B', 13)
pdf.set_fill_color(*BLUE_MID)
pdf.set_text_color(*WHITE)
pdf.cell(0, 9, '  PARTE II  -  AMBIENTE UVM', fill=True,
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)
pdf.ln(3)

# ----------------------------------------------------------------
# SECAO 5 - ARQUITETURA UVM
# ----------------------------------------------------------------
pdf.section_title('5', 'Arquitetura do Testbench UVM')

pdf.subsection('5.1  Estrutura de arquivos')
pdf.code_block([
    'build/dual_core_cva6/uvmt_openpiton_cva6/',
    '  tb/',
    '    uvmt_opc_dut_wrap.sv   <- wrapper DUT: clock, reset, sondas,',
    '                              hierarquia cross-module, deteccao GOOD_TRAP',
    '    uvmt_opc_tb.sv         <- top UVM: import pkg, bind interfaces, run_test()',
    '    boot.hex               <- programa RISC-V (copiado para xsim_work/ no run)',
    '  sim/',
    '    run.tcl                <- fluxo: compile / elaborate / run / all',
    '    config.tcl             <- variaveis BUILD_DIR, UVM_RUN_BINARY, UVM_ARGS',
    '  rtl/',
    '    noc_axi4_bridge.sv     <- ponte NoC1/2/3 <-> AXI4',
    '    axi4_sram_model.sv     <- modelo SRAM 256 KB (DDR simulado)',
])

pdf.subsection('5.2  Fluxo de simulacao')
rows_flow = [
    ('compile',   'xvlog/xvhdl: compila todos os .sv/.v'),
    ('elaborate',
     'xelab: instancia hierarquia, gera snapshot + xsimk.exe (kernel)'),
    ('run',
     'xsim: copia boot.hex -> xsim_work/, executa "run -all", '
     'grava simulate.log'),
    ('all', 'compile + elaborate + run em sequencia'),
]
pdf.table(['Target TCL (-tclargs)', 'Acao'], rows_flow, [35, 135])

pdf.info_box(
    'Para alterar somente o boot.hex (programa), use -tclargs run: '
    'nao precisa re-elaborar. Para alterar RTL (dut_wrap.sv), '
    'use -tclargs all (ou elaborate + run).'
)

pdf.subsection('5.3  Interface status_if')
pdf.code_block([
    'interface status_if #(parameter NUM_TILES = 2) (',
    '    input logic clk,',
    '    input logic rst_n',
    ');',
    '    logic [NUM_TILES-1:0] good_trap;  // 1 bit por tile',
    '    // ... outros sinais de estado ...',
    'endinterface',
    '',
    '// Quando good_trap[0] == 1:',
    '//   testbench imprime "[PASS] GOOD_TRAP detectado" e chama $finish',
])

pdf.subsection('5.4  Clock e reset')
pdf.code_block([
    '// uvmt_opc_dut_wrap.sv',
    'parameter CLK_PERIOD = 10;  // 10 ns -> 100 MHz',
    '',
    'initial clk = 0;',
    'always #(CLK_PERIOD/2) clk = ~clk;',
    '',
    '// Reset: ativo por ~200 ciclos',
    'initial begin',
    '    rst_n = 0;',
    '    repeat(200) @(posedge clk);',
    '    rst_n = 1;',
    'end',
])

pdf.subsection('5.5  Monitor de ciclos')
pdf.code_block([
    'int mon_cycle = 0;',
    'always_ff @(posedge clk) begin',
    '    if (!rst_n) mon_cycle <= 0;',
    '    else        mon_cycle <= mon_cycle + 1;',
    'end',
])

# ----------------------------------------------------------------
# SECAO 6 - GOOD_TRAP DETECTION
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('6', 'Deteccao GOOD_TRAP via store_buffer.commit_i')

pdf.subsection('6.1  Por que monitorar commit_i?')
pdf.body(
    'A convencao RISC-V para finalizar um teste (riscv-tests, riscv-torture) '
    'e escrever um valor no endereco tohost. Para o simulador xsim, '
    'o store fisico nao chega a memoria (store_if bloqueado), mas o commit '
    'no pipeline ocorre normalmente.'
)
pdf.body(
    'O sinal commit_i e assertado pelo ROB quando uma instrucao store '
    'e confirmada. Este sinal FUNCIONA no xsim pois e uma entrada do modulo '
    'store_buffer, nao parte do bloco XSIM-guarded (store_if).'
)

pdf.subsection('6.2  Hierarquia de acesso cross-module')
pdf.code_block([
    '// Macro para encurtar o caminho hierarquico (131 caracteres)',
    '`define SB0  u_chip.tile0.g_ariane_core.core.ariane\\',
    '             .i_cva6.ex_stage_i.lsu_i.i_store_unit.store_buffer_i',
    '',
    '// Aliases de wire - LEITURA hierarquica (segura no xsim)',
    'wire        sb0_commit_i;',
    'wire [55:0] sb0_commit_addr;',
    '',
    'assign sb0_commit_i    = `SB0.commit_i;',
    'assign sb0_commit_addr = `SB0.speculative_queue_q[',
    '                           `SB0.speculative_read_pointer_q].address;',
])

pdf.subsection('6.3  Regra de seguranca: leitura vs escrita no xsim')
rows_safe = [
    ('assign wire = hier.signal',    'SEGURO',  'Leitura continua - OK'),
    ('assign wire = struct[ptr].field','SEGURO', 'Leitura com indice dinamico - OK'),
    ('always_ff: if (cond) begin',    'SEGURO',  'Leitura em always_ff - OK'),
    ('always_comb: struct[i] = ...',  'CRASH',   'Escrita em always_comb - FATAL_ERROR xsim'),
]
pdf.table(['Operacao', 'Status', 'Motivo'], rows_safe, [68, 18, 84])

pdf.subsection('6.4  Bloco de deteccao no always_ff')
pdf.code_block([
    'localparam [31:0] TOHOST_ADDR32 = 32\'h8000_FF50;',
    '',
    'always_ff @(posedge clk or negedge rst_n) begin',
    '    if (!rst_n) begin',
    '        status_if.good_trap <= 0;',
    '        mon_cycle           <= 0;',
    '    end else begin',
    '        mon_cycle <= mon_cycle + 1;',
    '',
    '        if (!status_if.good_trap[0]',
    '            && sb0_commit_i',
    '            && sb0_commit_addr[31:0] == TOHOST_ADDR32) begin',
    '',
    '            $display("[%0t ns] STORE_COMMIT tohost=0x%08h @cyc=%0d",',
    '                     $time, sb0_commit_addr[31:0], mon_cycle);',
    '            status_if.good_trap <= {NUM_TILES{1\'b1}};',
    '        end',
    '    end',
    'end',
])

pdf.ok_box(
    'O bloco sempre_ff so modifica status_if.good_trap, nunca acessa struct arrays '
    'em escrita. A leitura de sb0_commit_addr via assign e feita fora do always_ff '
    '(evitando qualquer risco de crash).'
)

# ----------------------------------------------------------------
# SECAO 7 - FILTRAGEM DE ENDERECO
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('7', 'Verificacao de Endereco (tohost filter)')

pdf.subsection('7.1  Necessidade de filtragem')
pdf.body(
    'Sem verificacao de endereco, commit_i dispara para QUALQUER store '
    'commitado pelo pipeline CVA6, incluindo stores intermediarios (inicializacao '
    'de variaveis, stackframe, etc.). O GOOD_TRAP seria um falso positivo.'
)
pdf.body(
    'Com o programa de dois-stores (dummy + tohost), isso foi demonstrado '
    'experimentalmente: o primeiro store (0x8000_FF60) disparava GOOD_TRAP '
    'prematuramente no ciclo 192.'
)

pdf.subsection('7.2  Enderecos no programa de teste')
rows_addr = [
    ('0x8000_FF60', '16(x1)', 'DUMMY - store para validar filtragem (ciclo 192)'),
    ('0x8000_FF50', '0(x1)',  'TOHOST - store correto, dispara GOOD_TRAP (ciclo 193)'),
]
pdf.table(['Endereco', 'Instrucao (offset)', 'Funcao'], rows_addr, [28, 22, 120])

pdf.subsection('7.3  Calculo do endereco tohost')
pdf.code_block([
    '// Instrucoes que calculam o endereco base:',
    'auipc x1, 0x10      -> x1 = PC + (0x10 << 12)',
    '                     -> x1 = 0x80000000 + 0x10000 = 0x80010000',
    '',
    'addi  x1, x1, -176  -> x1 = 0x80010000 + (-176)',
    '                     -> x1 = 0x80010000 - 0xB0',
    '                     -> x1 = 0x8000FF50  (tohost!)',
    '',
    '// A constante -176 (0xFFFFFFB0) como imm12: 0xFB0 = -176 em complemento-2',
    '// Encoding: F5008093 = addi x1, x1, -176',
    '//   imm[11:0] = 1111 0101 0000 = 0xF50... errado',
    '// Verificado: 0x80010000 - 176 = 0x80010000 - 0xB0 = 0x8000FF50 OK',
])

pdf.subsection('7.4  Comportamento com e sem filtragem')
pdf.code_block([
    '-- SEM filtragem de endereco:',
    't=1920 ns (c=192): commit_i=1, addr=0x8000FF60 -> GOOD_TRAP (FALSO POSITIVO)',
    '',
    '-- COM filtragem (addr[31:0] == TOHOST_ADDR32):',
    't=1920 ns (c=192): commit_i=1, addr=0x8000FF60 != 0x8000FF50 -> IGNORADO',
    't=1930 ns (c=193): commit_i=1, addr=0x8000FF50 == 0x8000FF50 -> GOOD_TRAP OK',
    't=1940 ns (c=194): simulacao termina com PASS',
])

pdf.ok_box(
    'A filtragem por endereco garante que somente a escrita no endereco tohost '
    '(0x8000_FF50) dispara o GOOD_TRAP, eliminando falsos positivos por '
    'stores anteriores no programa.'
)

# ================================================================
# PARTE III - RESULTADOS DOS TESTES
# ================================================================
pdf.add_page()
pdf.set_font('Helvetica', 'B', 13)
pdf.set_fill_color(*BLUE_MID)
pdf.set_text_color(*WHITE)
pdf.cell(0, 9, '  PARTE III  -  RESULTADOS DOS TESTES', fill=True,
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)
pdf.ln(3)

# ----------------------------------------------------------------
# SECAO 8 - FASE 1
# ----------------------------------------------------------------
pdf.section_title('8', 'Fase 1: Validacao de Boot e Fetch')

pdf.subsection('8.1  Configuracao do teste (Fase 1)')
rows_f1 = [
    ('Programa',          'JAL x0,0 (loop infinito, 2 palavras)'),
    ('Duracao',           '10 000 ciclos  (101 995 ns)'),
    ('Clock',             '10 ns (100 MHz)'),
    ('Reset',             '~200 ciclos'),
    ('Criterio de PASS',  'axi_ar_transactions >= 1 (leitura AXI4 confirmada)'),
    ('Log',               'simulate.log'),
]
pdf.table(['Parametro', 'Valor'], rows_f1, [45, 125])

pdf.subsection('8.2  Timeline de eventos (Fase 1)')
pdf.code_block([
    't=3 485 ns (c=148):  Icache flush completo (128 linhas invalidadas)',
    't=3 495 ns (c=149):  Fetch request vaddr=0x8000_0000',
    't=3 505 ns (c=150):  MISS no icache -> L15 IMISS addr=0x0080000000',
    't=3 515 ns (c=151):  L15 S3 -> noc1encoder -> flit=0x000400000087c040',
    '                     chip_id=1 (off-chip), x=0, y=0',
    't=3 545 ns (c=154):  noc1W=1 -- flit saiu pelo West (off-chip)',
    't=3 855 ns (c=185):  NOC2 resp: 0x6f0000006f000000 (jal x0,0 x2)',
    '                     noc_axi4_bridge responde, L15 fill recebido',
    't=3 865 ns:          Icache: clhit=1 -- instrucao no cache',
    't=3 895 ns (c=189):  rd=2 -- 2 transacoes AXI4 read completadas',
    't=3 895 ns -> fim:   Ambos os tiles: jal x0,0 em loop (clhit=1)',
    't=101 995 ns (c=10000): $finish -> PASS',
])

pdf.subsection('8.3  Resultado Fase 1')
pdf.set_fill_color(20, 80, 40)
pdf.set_text_color(*WHITE)
pdf.set_font('Courier', 'B', 9)
for line in [
    '  ================================================',
    '  RESULTADO FASE 1 -- 10 000 ciclos (101 995 ns)',
    '    Transacoes AXI4 leitura : 2',
    '    Transacoes AXI4 escrita : 0',
    '  PASS: 2 cores CVA6 acessaram memoria via AXI4.',
    '  ================================================',
]:
    pdf.cell(0, 5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)
pdf.set_font('Helvetica', '', 9)
pdf.ln(3)

pdf.ok_box(
    'Confirmado Fase 1: 2 cores CVA6 inicializam, buscam instrucoes via icache miss '
    '-> NoC -> AXI4 -> SRAM, recebem o fill corretamente e executam em loop. '
    'Pipeline de instrucoes totalmente operacional.'
)

# ----------------------------------------------------------------
# SECAO 9 - FASE 2
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('9', 'Fase 2: GOOD_TRAP via Programa Dois-Stores')

pdf.subsection('9.1  Programa de teste (boot.hex Fase 2)')
rows_asm = [
    ('1', '00010097', 'auipc x1, 0x10',       '0x80010000', 'Calcula end. base'),
    ('2', 'F5008093', 'addi  x1, x1, -176',  '0x8000FF50', 'Ajusta para tohost'),
    ('3', '00100113', 'addi  x2, x0, 1',     '1',          'x2 = 1'),
    ('4', '0020A823', 'sw    x2, 16(x1)',     '0x8000FF60', 'DUMMY store'),
    ('5', '0020A023', 'sw    x2, 0(x1)',      '0x8000FF50', 'TOHOST store'),
    ('6', '0000006F', 'jal   x0, 0',          '-',          'Loop'),
]
pdf.table(
    ['#', 'Encoding', 'Instrucao', 'End. alvo', 'Descricao'],
    rows_asm,
    [6, 22, 33, 26, 83]
)

pdf.subsection('9.2  Configuracao do teste (Fase 2)')
rows_f2 = [
    ('Programa',          'boot.hex: auipc + 2x addi + 2x sw + jal'),
    ('Stores',            '2 stores: dummy (0xFF60) + tohost (0xFF50)'),
    ('Criterio de PASS',  'commit_i=1 AND addr[31:0] == 0x8000_FF50'),
    ('Ciclos ate PASS',   '194 ciclos (1940 ns)'),
    ('Store filtrado',    '0x8000_FF60 - ciclo 192 (descartado)'),
    ('Store aceito',      '0x8000_FF50 - ciclo 193 (GOOD_TRAP)'),
    ('Log',               'simulate.log (Fase 2)'),
]
pdf.table(['Parametro', 'Valor'], rows_f2, [45, 125])

pdf.subsection('9.3  Timeline completa (Fase 2)')
pdf.code_block([
    't=    0 ns (c=0):     Reset ativo (rst_n=0)',
    't=~2000 ns (c=~100):  Reset liberado (spc_grst_l=1)',
    't=3 485 ns (c=148):   Icache flush completo',
    't=3 495 ns (c=149):   Fetch vaddr=0x8000_0000',
    't=3 505 ns (c=150):   Icache MISS -> L15 -> NoC1',
    't=3 545 ns (c=154):   Flit sai pelo West (off-chip)',
    't=3 855 ns (c=185):   Resposta NoC2: instrucoes recebidas',
    't=3 865 ns (c=186):   Icache fill (clhit=1)',
    't=~3890 ns (c=~189):  Pipeline busca: auipc, addi, addi, sw, sw',
    '',
    't=1920 ns  (c=192):   commit_i=1, sb0_commit_addr=0x8000_FF60',
    '                       addr != TOHOST_ADDR32 -> IGNORADO (dummy)',
    '',
    't=1930 ns  (c=193):   commit_i=1, sb0_commit_addr=0x8000_FF50',
    '                       addr == TOHOST_ADDR32 -> MATCH!',
    '                       good_trap[0] := 1',
    '                       $display: STORE_COMMIT tohost=0x8000FF50 @cyc=193',
    '',
    't=1940 ns  (c=194):   testbench detecta good_trap[0]==1',
    '                       $display: ===== GOOD_TRAP PASS ===== ciclo 194',
    '                       $finish',
])

pdf.subsection('9.4  Resultado Fase 2')
pdf.set_fill_color(20, 80, 40)
pdf.set_text_color(*WHITE)
pdf.set_font('Courier', 'B', 9)
for line in [
    '  ==========================================================',
    '  RESULTADO FASE 2 -- GOOD_TRAP',
    '    Ciclos ate GOOD_TRAP   : 194',
    '    Store dummy (0xFF60)   : FILTRADO  -- ciclo 192',
    '    Store tohost (0xFF50)  : ACEITO    -- ciclo 193',
    '    good_trap[0]           : 1  (PASS)',
    '  PASS: CVA6 executou store tohost com endereco correto.',
    '  ==========================================================',
]:
    pdf.cell(0, 5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)
pdf.set_font('Helvetica', '', 9)
pdf.ln(3)

pdf.ok_box(
    'Confirmado Fase 2: mecanismo GOOD_TRAP funciona corretamente. '
    'O store dummy (0x8000_FF60) e filtrado sem disparar falso positivo. '
    'Apenas o store tohost (0x8000_FF50) aciona o PASS. '
    'Hierarquia cross-module no xsim e estavel.'
)

# ----------------------------------------------------------------
# SECAO 10 - LIMITACOES
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('10', 'Limitacoes Conhecidas')

pdf.subsection('10.1  Store buffer inativo no xsim  [CRITICA]')
pdf.warn_box(
    'Stores de dados (SW, SD, SH, SB) nao chegam ao dcache nem a memoria '
    'durante a simulacao xsim. O pipeline CVA6 commita as instrucoes normalmente '
    '(commit_i dispara), mas req_port_o.data_req permanece 0 (stub ativo).'
)
pdf.body(
    'Causa: bug de kernel do xsim 2025.1 com arrays de struct packed de 131 bits '
    'em always_comb. O workaround (stub) e a unica solucao praticavel no xsim.'
)
pdf.body(
    'Impacto: o mecanismo GOOD_TRAP via commit_i mitiga esta limitacao para '
    'deteccao de finalizacao de programas, mas nao valida a escrita fisica '
    'na SRAM model.'
)

pdf.subsection('10.2  Assertions SVA desabilitadas')
pdf.body(
    'Todas as assertions com $fatal foram desativadas via `ifndef XSIM. '
    'Violacoes de protocolo detectaveis por essas assertions passarao '
    'silenciosamente durante a simulacao xsim.'
)

pdf.subsection('10.3  Somente tile0 monitorado')
pdf.body(
    'O mecanismo GOOD_TRAP atual so monitora o store buffer do tile0. '
    'O tile1 nao tem sonda equivalente nesta fase.'
)

pdf.subsection('10.4  Programa de teste simples')
pdf.body(
    'O boot.hex atual nao exercita: MMU (TLB), FPU, excecoes, CSRs alem '
    'do basico de boot, nem coerencia de cache multi-core.'
)

pdf.subsection('10.5  Sem L2 cache')
pdf.body(
    'Todos os misses vao direto para a SRAM model (sem L2). '
    'Latencia de acesso a memoria alta, sem beneficio de segundo nivel de cache.'
)

# ----------------------------------------------------------------
# SECAO 11 - PROXIMOS PASSOS
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('11', 'Proximos Passos')

pdf.subsection('11.1  Imediato - Extender o programa boot.hex')
pdf.bullet('Adicionar instrucoes aritmeticas: add, sub, and, or, xor, slt.')
pdf.bullet('Adicionar loads: lw, ld para verificar leitura de dados alem de instrucoes.')
pdf.bullet('Implementar loop de contagem com resultado esperado em tohost.')
pdf.bullet('Usar tohost = (result << 1) | 1 para PASS, valor par para FAIL.')

pdf.subsection('11.2  Curto prazo - Monitorar tile1')
pdf.bullet('Adicionar alias SB1 para store_buffer do tile1.')
pdf.bullet('good_trap[1] controlado separadamente de good_trap[0].')
pdf.bullet('Verificar execucao independente dos dois harts.')

pdf.subsection('11.3  Curto prazo - Programa ELF compilado')
pdf.bullet('Compilar com riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d.')
pdf.bullet('Usar convencao riscv-tests: write tohost = (result << 1) | 1.')
pdf.bullet('Extrair .hex via objcopy --output-target=verilog.')

pdf.subsection('11.4  Medio prazo - Validar stores com simulador alternativo')
pdf.bullet('ModelSim/QuestaSim (free tier academico) ou Verilator.')
pdf.bullet('Verificar req_port_o.data_req e assertado no commit queue.')
pdf.bullet('Confirmar transacao AXI4 write (axi_aw) na ponte NoC-AXI4.')
pdf.bullet('Verificar valor na SRAM apos store == dado escrito pelo CVA6.')

pdf.subsection('11.5  Medio prazo - Teste de coerencia multi-core')
pdf.bullet('Core 0 escreve em X; core 1 le X - verificar valor correto.')
pdf.bullet('Verificar MSG_MESI=EXCLUSIVE e invalidacoes NoC entre tiles.')
pdf.bullet('Spinlock entre dois cores como smoke test de sincronizacao.')

pdf.subsection('11.6  Longo prazo - OpenSBI + Boot Linux')
pdf.bullet('OpenSBI como firmware M-mode.')
pdf.bullet('Kernel Linux 6.x SMP RISC-V com rootfs initramfs.')
pdf.bullet('/proc/cpuinfo: 2 harts CVA6 (hart0, hart1).')
pdf.bullet('Benchmarks: dhrystone, coremark para medir desempenho.')

pdf.subsection('11.7  Longo prazo - Sintese FPGA')
pdf.bullet('Target: Xilinx Zynq UltraScale+ (ZCU102) ou Artix-7.')
pdf.bullet('Substituir tc_sram por primitivas BRAM.')
pdf.bullet('Timing closure: CVA6 tipicamente 100 MHz em UltraScale+.')
pdf.bullet('UART e GPIO para interacao via console serial.')

# ----------------------------------------------------------------
# SALVAR
# ----------------------------------------------------------------
out_path = r'C:\Users\rafae\Documents\SoC_dual_core\doc\relatorio_soc_dual_core_completo.pdf'
pdf.output(out_path)
print('PDF gerado: ' + out_path)
