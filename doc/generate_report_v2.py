"""
Gera o relatorio de avancos (Fase 2) do SoC Dual-Core CVA6 em PDF.
Documenta: UVM testbench, deteccao GOOD_TRAP via commit_i, verificacao
de endereco no store buffer, teste de validacao dois-stores.
Uso: python generate_report_v2.py
"""
from fpdf import FPDF
from fpdf.enums import XPos, YPos
import datetime

# Paleta de cores
BLUE_DARK  = (26,  57,  96)
BLUE_MID   = (41,  98, 161)
BLUE_LIGHT = (210, 227, 252)
GRAY_LIGHT = (245, 245, 245)
GRAY_MID   = (200, 200, 200)
GREEN      = (0,  128,  0)
RED        = (180,  0,  0)
BLACK      = (0,   0,  0)
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
        self.cell(0, 6, 'SoC Dual-Core CVA6 - Relatorio de Avancos (Fase 2)', align='C')
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

pdf.set_y(45)
pdf.set_font('Helvetica', 'B', 28)
pdf.set_text_color(*WHITE)
pdf.cell(0, 14, 'SoC Dual-Core CVA6', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font('Helvetica', 'B', 14)
pdf.cell(0, 10, 'Relatorio de Avancos - Fase 2', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font('Helvetica', '', 11)
pdf.set_text_color(180, 210, 255)
pdf.cell(0, 8, 'UVM Testbench  |  GOOD_TRAP Detection  |  Store Buffer Verification',
         align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(6)
pdf.set_draw_color(*BLUE_MID)
pdf.set_line_width(0.5)
pdf.line(40, pdf.get_y(), 170, pdf.get_y())
pdf.ln(6)

pdf.set_font('Helvetica', '', 10)
pdf.set_text_color(*WHITE)
pdf.cell(0, 7, 'Plataforma: OpenPiton 2x1  |  Processadores: 2x CVA6 (RISC-V RV64GC)', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.cell(0, 7, 'Simulador: Xilinx xsim 2025.1  |  Ambiente: Windows 11 / VS Code', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.ln(4)
pdf.set_font('Helvetica', 'I', 10)
pdf.cell(0, 7,
    'Data: %s' % datetime.date.today().strftime('%d de %B de %Y'),
    align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

# Badge PASS
pdf.ln(14)
pdf.set_fill_color(0, 160, 80)
pdf.set_font('Helvetica', 'B', 18)
pdf.set_x(55)
pdf.cell(100, 14, '  GOOD_TRAP: PASS  ', fill=True, align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(5)
pdf.set_font('Helvetica', '', 10)
pdf.set_text_color(180, 220, 255)
pdf.cell(0, 7, 'Ciclo de deteccao: 194  |  Instrucoes store: 2  |  tohost: 0x8000_FF50',
         align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

# Conquistas em caixas
pdf.ln(12)
pdf.set_font('Helvetica', 'B', 9)
pdf.set_text_color(200, 230, 255)
conquistas = [
    '[v]  Deteccao GOOD_TRAP via store_buffer.commit_i',
    '[v]  Verificacao de endereco: so aceita escrita em tohost (0x8000_FF50)',
    '[v]  Hierarquia cross-modulo segura no xsim (sem crash)',
    '[v]  Teste dois-stores: dummy (0xFF60) filtrado, correto (0xFF50) aceito',
]
for c in conquistas:
    pdf.cell(0, 6, '    ' + c, align='L', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(30)
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
    ('1', 'Contexto e Ponto de Partida',                     '3'),
    ('2', 'Ambiente UVM e Testbench',                        '4'),
    ('3', 'Deteccao GOOD_TRAP via store_buffer.commit_i',    '5'),
    ('4', 'Verificacao de Endereco no Store Buffer',         '7'),
    ('5', 'Programa de Teste: Dois Stores (boot.hex)',       '9'),
    ('6', 'Resultados de Simulacao',                         '10'),
    ('7', 'Analise dos Obstaculos e Solucoes',               '11'),
    ('8', 'Proximos Passos',                                 '12'),
]
pdf.set_font('Helvetica', '', 10)
for num, title, page in toc:
    pdf.set_x(20)
    pdf.cell(10, 7, num)
    pdf.cell(140, 7, title)
    pdf.cell(0, 7, page, align='R', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_draw_color(*GRAY_MID)
    pdf.line(30, pdf.get_y() - 0.5, 188, pdf.get_y() - 0.5)

# ----------------------------------------------------------------
# SECAO 1 - CONTEXTO
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('1', 'Contexto e Ponto de Partida')

pdf.body(
    'Este relatorio documenta os avancos realizados na Fase 2 do projeto SoC Dual-Core CVA6. '
    'O relatorio anterior (Fase 1) estabeleceu que os dois cores CVA6 inicializam, '
    'executam instrucoes via icache miss -> NoC -> AXI4 -> SRAM e recebem fill '
    'corretamente. O criterio de PASS era simplesmente "axi_ar_transactions >= 1".'
)

pdf.subsection('1.1  Limitacao da Fase 1')
pdf.body(
    'A Fase 1 utilizava um testbench simples (tb_soc_dual_core) com o programa '
    '"JAL x0,0" (loop infinito). O criterio de PASS baseado em contadores AXI4 '
    'de leitura nao validava a execucao de stores nem garantia que um programa '
    'real terminou com resultado correto.'
)
pdf.warn_box(
    'Problema em aberto: stores nao chegavam ao dcache (store buffer stub no xsim). '
    'Precisavamos de um mecanismo para detectar quando o programa "finaliza" '
    'sem depender da escrita fisica na SRAM.'
)

pdf.subsection('1.2  Objetivo da Fase 2')
pdf.body('Implementar deteccao de GOOD_TRAP via monitoramento do store buffer interno do CVA6:')
pdf.bullet(
    'O programa escreve 1 no endereco tohost (0x8000_FF50), convencao RISC-V para '
    'sinalizar fim com sucesso (usado em riscv-tests e riscv-torture).'
)
pdf.bullet(
    'O testbench UVM monitora o store buffer commit: quando commit_i=1 e o endereco '
    'commitado == 0x8000_FF50, o GOOD_TRAP e acionado.'
)
pdf.bullet(
    'Este mecanismo funciona mesmo com o store buffer stub do xsim, pois o '
    'commit_i dispara no pipeline CVA6 antes de passar pelo bloco XSIM-guarded.'
)

pdf.subsection('1.3  Arquivo Base: boot.hex (Fase 1)')
pdf.code_block([
    '00010097   # auipc x1, 0x10  -> x1 = PC + 0x10000 = 0x80010000',
    'F5008093   # addi  x1, x1, -176  -> x1 = 0x8000FF50  (endereco tohost)',
    '00100113   # addi  x2, x0, 1    -> x2 = 1',
    '0020A023   # sw    x2, 0(x1)    -> tohost = 1  (STORE original)',
    '0000006F   # jal   x0, 0        -> loop infinito',
    '(restante: 0x6F repetidos)',
])
pdf.body(
    'Na Fase 1 este programa nao era testado com criterio de store. '
    'A Fase 2 adicionou um store extra (dummy) para validar a filtragem por endereco.'
)

# ----------------------------------------------------------------
# SECAO 2 - UVM TESTBENCH
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('2', 'Ambiente UVM e Testbench')

pdf.subsection('2.1  Estrutura do Projeto UVM')
pdf.body(
    'O projeto utiliza o ambiente UVM (Universal Verification Methodology) '
    'para estruturar o testbench. Os arquivos principais estao em:'
)
pdf.code_block([
    'build/dual_core_cva6/uvmt_openpiton_cva6/',
    '  tb/',
    '    uvmt_opc_dut_wrap.sv     <- wrapper principal: sinais, clock, reset,',
    '                                hierarquias cross-module, deteccao GOOD_TRAP',
    '    uvmt_opc_tb.sv           <- top-level UVM (importa pacotes, cria env)',
    '    boot.hex                 <- programa carregado na SRAM no inicio',
    '  sim/',
    '    run.tcl                  <- script TCL: compile / elaborate / run',
    '    config.tcl               <- variaveis: BUILD_DIR, UVM_RUN_BINARY, etc.',
    '  rtl/',
    '    noc_axi4_bridge.sv       <- ponte NoC -> AXI4',
    '    axi4_sram_model.sv       <- modelo SRAM (256 KB DDR simulado)',
])

pdf.subsection('2.2  Fluxo de Simulacao UVM')
pdf.body('O script run.tcl aceita os seguintes targets via -tclargs:')
rows_flow = [
    ('compile',   'xvlog/xvhdl: compila todos os .sv/.v listados em config.tcl'),
    ('elaborate', 'xelab: instancia hierarquia, gera snapshot work.uvmt_opc_tb + xsimk.exe'),
    ('run',       'xsim: copia boot.hex para xsim_work/ e executa a simulacao'),
    ('all',       'Executa compile + elaborate + run em sequencia'),
]
pdf.table(['Target', 'Acao'], rows_flow, [22, 148])

pdf.info_box(
    'Para alterar apenas o programa (boot.hex) sem re-elaborar, use "-tclargs run". '
    'Para alterar RTL (uvmt_opc_dut_wrap.sv), e necessario "-tclargs all" '
    '(ou ao menos elaborate + run).'
)

pdf.subsection('2.3  Interface de Status: status_if')
pdf.body(
    'O testbench define uma interface SystemVerilog "status_if" que carrega '
    'os sinais de estado da simulacao. O sinal principal para esta fase:'
)
pdf.code_block([
    'interface status_if #(parameter NUM_TILES = 2) (',
    '    input logic clk,',
    '    input logic rst_n',
    ');',
    '    logic [NUM_TILES-1:0] good_trap;  // 1 bit por tile',
    '    ...',
    'endinterface',
])
pdf.body(
    'Quando good_trap[0] e assertado, o testbench imprime "PASS" e termina a simulacao. '
    'O modulo uvmt_opc_dut_wrap.sv e responsavel por monitorar o DUT e '
    'escrever em status_if.good_trap.'
)

pdf.subsection('2.4  Hierarquia DUT no xsim')
pdf.body(
    'O testbench acessa internos do DUT via hierarquia cross-module. '
    'O caminho completo ate o store_buffer do tile 0 e:'
)
pdf.code_block([
    'u_chip                    <- instancia chip no dut_wrap',
    '  .tile0                  <- tile 0 (TILE_ID=0)',
    '    .g_ariane_core.core   <- generate block + ariane_verilog_wrap',
    '      .ariane             <- instancia do modulo ariane',
    '        .i_cva6           <- nucleo CVA6',
    '          .ex_stage_i     <- execution stage',
    '            .lsu_i        <- load/store unit',
    '              .i_store_unit   <- store unit',
    '                .store_buffer_i  <- store buffer (alvo da sonda)',
])

# ----------------------------------------------------------------
# SECAO 3 - DETECCAO GOOD_TRAP
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('3', 'Deteccao GOOD_TRAP via store_buffer.commit_i')

pdf.subsection('3.1  Por que monitorar o store buffer?')
pdf.body(
    'O store buffer do CVA6 tem dois caminhos de propagacao de um store:'
)
rows_sb = [
    ('Especulativo', 'speculative_queue_q', 'Stores aguardando commit (podem ser descartados)'),
    ('Commit',       'commit_queue_q',      'Stores confirmados pelo ROB, prontos para escrita'),
    ('Saida dcache', 'req_port_o.data_req', 'Acesso fisico ao dcache/memoria (BLOQUEADO no xsim)'),
]
pdf.table(['Caminho', 'Estrutura', 'Descricao'], rows_sb, [22, 36, 112])

pdf.body(
    'O sinal commit_i (entrada do modulo store_buffer) e assertado pelo ROB '
    'quando uma instrucao store e oficialmente commitada, antes de ser enviada '
    'ao dcache. Este sinal FUNCIONA no xsim pois nao envolve o bloco XSIM-guarded.'
)

pdf.ok_box(
    'commit_i dispara no lado do pipeline CVA6, antes do always_comb store_if. '
    'Portanto, mesmo com o stub req_port_o.data_req=0, o commit_i e visivel.'
)

pdf.subsection('3.2  Implementacao inicial (sem verificacao de endereco)')
pdf.body(
    'A primeira implementacao simplesmente monitorava commit_i, sem verificar '
    'qual store estava sendo commitado:'
)
pdf.code_block([
    '// uvmt_opc_dut_wrap.sv - versao inicial',
    'wire sb0_commit_i;',
    'assign sb0_commit_i = u_chip.tile0.g_ariane_core.core.ariane',
    '                        .i_cva6.ex_stage_i.lsu_i.i_store_unit',
    '                        .store_buffer_i.commit_i;',
    '',
    'always_ff @(posedge clk or negedge rst_n) begin',
    '    if (!status_if.good_trap[0] && sb0_commit_i) begin',
    '        status_if.good_trap <= {NUM_TILES{1\'b1}};  // QUALQUER store!',
    '    end',
    'end',
])

pdf.warn_box(
    'Problema: esta implementacao disparava GOOD_TRAP no PRIMEIRO store commitado, '
    'independentemente do endereco. Com o programa de dois-stores, o dummy store '
    '(0x8000_FF60) acionava o GOOD_TRAP prematuramente.'
)

pdf.subsection('3.3  Diagnostico: dois commits distintos')
pdf.body(
    'Adicionando o store dummy antes do store tohost ao boot.hex e monitorando '
    'os ciclos de commit, foi possivel distinguir as duas operacoes:'
)
pdf.code_block([
    '// boot.hex (dois stores)',
    '00010097  auipc x1, 0x10       -> x1 = 0x80010000',
    'F5008093  addi  x1, x1, -176  -> x1 = 0x8000FF50 (tohost)',
    '00100113  addi  x2, x0, 1     -> x2 = 1',
    '0020A823  sw    x2, 16(x1)    -> store para 0x8000FF60  (DUMMY - ciclo 192)',
    '0020A023  sw    x2, 0(x1)     -> store para 0x8000FF50  (TOHOST - ciclo 193)',
    '0000006F  jal   x0, 0         -> loop',
])
pdf.code_block([
    '[1920 ns] commit_i=1 -- ciclo 192: store dummy  0x8000FF60  (falso positivo!)',
    '[1930 ns] commit_i=1 -- ciclo 193: store tohost 0x8000FF50  (correto)',
    '[1940 ns] GOOD_TRAP detectado em ciclo 194',
])

# ----------------------------------------------------------------
# SECAO 4 - VERIFICACAO DE ENDERECO
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('4', 'Verificacao de Endereco no Store Buffer')

pdf.subsection('4.1  Estrutura interna do store buffer')
pdf.body(
    'O store_buffer.sv do CVA6 possui dois arrays de struct packed. '
    'O array relevante para rastrear o endereco de commit e o speculative_queue_q:'
)
pdf.code_block([
    '// store_buffer.sv (piton/design/chip/tile/ariane/core/store_buffer.sv)',
    'typedef struct packed {',
    '    logic [55:0]  address;   // riscv::PLEN = 56 bits (ende. fisico)',
    '    logic [63:0]  data;      // dado a ser escrito',
    '    logic [7:0]   be;        // byte enable',
    '    logic [1:0]   data_size; // tamanho (Byte/HalfW/Word/DoubleW)',
    '    logic         valid;     // entrada valida',
    '} speculative_queue_t;  // total = 131 bits',
    '',
    'speculative_queue_t [DEPTH_SPEC-1:0] speculative_queue_q; // [3:0]',
    'logic [2:0] speculative_read_pointer_q;  // aponta pro proximo commit',
])

pdf.body(
    'Quando commit_i e assertado, o store que esta sendo commitado e o que '
    'esta na posicao speculative_read_pointer_q do array speculative_queue_q. '
    'O campo address[31:0] contem os 32 bits baixos do endereco fisico.'
)

pdf.subsection('4.2  Seguranca no xsim: leitura vs escrita')
pdf.info_box(
    'O crash FATAL_ERROR do xsim 2025.1 ocorre somente em always_comb com ESCRITA '
    'procedural em arrays de struct packed de 131 bits. LEITURA hierarquica '
    '(via assign ou always_ff) e segura.'
)
pdf.body('Consequencias para a implementacao:')
rows_safe = [
    ('assign wire = struct_array[ptr].field', 'SEGURO',   'Leitura hierarquica - OK no xsim'),
    ('always_comb: struct_array[i] = ...',    'CRASH',    'Escrita em always_comb - FATAL_ERROR'),
    ('always_ff: if (cond) begin ... end',    'SEGURO',   'Leitura em always_ff sequencial - OK'),
]
pdf.table(['Operacao', 'Status', 'Motivo'], rows_safe, [75, 18, 77])

pdf.subsection('4.3  Implementacao da verificacao de endereco')
pdf.body(
    'A solucao final define aliases de wire para os sinais internos e faz a '
    'comparacao de endereco dentro de um always_ff, usando apenas leituras:'
)
pdf.code_block([
    '// uvmt_opc_dut_wrap.sv - implementacao final',
    '',
    '`define SB0 u_chip.tile0.g_ariane_core.core.ariane\\',
    '            .i_cva6.ex_stage_i.lsu_i.i_store_unit.store_buffer_i',
    '',
    'wire        sb0_commit_i;',
    'wire [55:0] sb0_commit_addr;',
    '',
    '// leituras hierarquicas - seguras no xsim',
    'assign sb0_commit_i    = `SB0.commit_i;',
    'assign sb0_commit_addr = `SB0.speculative_queue_q[',
    '                           `SB0.speculative_read_pointer_q].address;',
    '',
    'localparam [31:0] TOHOST_ADDR32 = 32\'h8000_FF50;',
])
pdf.code_block([
    '// dentro de always_ff @(posedge clk or negedge rst_n):',
    'if (!status_if.good_trap[0]',
    '    && sb0_commit_i',
    '    && sb0_commit_addr[31:0] == TOHOST_ADDR32) begin',
    '',
    '    $display("[%0t ns] STORE_COMMIT tohost=0x%08h @cyc=%0d",',
    '             $time, sb0_commit_addr[31:0], mon_cycle);',
    '    status_if.good_trap <= {NUM_TILES{1\'b1}};',
    'end',
])

pdf.ok_box(
    'O `define SB0 encapsula o caminho hierarquico longo. '
    'Os dois assigns criam "espelhos" de wire que o xsim trata como '
    'leituras cross-module seguras. A comparacao ocorre so em always_ff.'
)

pdf.subsection('4.4  Analise da expressao de indexacao dinamica')
pdf.body(
    'A expressao speculative_queue_q[speculative_read_pointer_q].address usa '
    'indice dinamico (nao-constante) em um array de struct. '
    'Isso e suportado no xsim como LEITURA hierarquica via assign, '
    'mas causaria crash se fosse uma ESCRITA em always_comb.'
)
pdf.body(
    'O ponteiro speculative_read_pointer_q e um registrador de 3 bits (0-3) '
    'que avanca circularlamente a cada commit. No ciclo de commit, ele aponta '
    'exatamente para a entrada sendo retirada da fila especulativa.'
)

# ----------------------------------------------------------------
# SECAO 5 - PROGRAMA DE TESTE
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('5', 'Programa de Teste: Dois Stores (boot.hex)')

pdf.subsection('5.1  Motivacao: por que dois stores?')
pdf.body(
    'Um unico store no boot.hex nao e suficiente para validar a filtragem por '
    'endereco: nao teria como distinguir se o GOOD_TRAP disparou por causa do '
    'endereco correto ou simplesmente pelo primeiro store. '
    'O segundo store (dummy) serve como prova de que a filtragem funciona.'
)

pdf.subsection('5.2  Assembly e codificacao do programa')
rows_asm = [
    ('1', '00010097', 'auipc x1, 0x10',      '0x80010000', 'Calcula end. base'),
    ('2', 'F5008093', 'addi  x1, x1, -176', '0x8000FF50', 'Ajusta p/ tohost'),
    ('3', '00100113', 'addi  x2, x0, 1',    '1',          'x2 = valor 1'),
    ('4', '0020A823', 'sw    x2, 16(x1)',    '0x8000FF60', 'DUMMY store'),
    ('5', '0020A023', 'sw    x2, 0(x1)',     '0x8000FF50', 'TOHOST store'),
    ('6', '0000006F', 'jal   x0, 0',         '-',          'Loop infinito'),
]
pdf.table(
    ['#', 'Encoding', 'Instrucao', 'Endereco alvo', 'Descricao'],
    rows_asm,
    [6, 22, 33, 26, 83]
)

pdf.subsection('5.3  Codificacao S-type do RISC-V')
pdf.body(
    'As instrucoes SW usam o formato S-type do RISC-V. '
    'O imediato de 12 bits e dividido em dois campos no encoding:'
)
pdf.code_block([
    'Formato S-type: [imm[11:5]] [rs2] [rs1] [funct3] [imm[4:0]] [opcode]',
    '  sw x2, 0(x1):  imm=0    -> 0020A023',
    '    imm[11:5]=0000000  rs2=00010  rs1=00001  funct3=010  imm[4:0]=00000  op=0100011',
    '',
    '  sw x2, 16(x1): imm=16   -> 0020A823',
    '    imm[11:5]=0000000  rs2=00010  rs1=00001  funct3=010  imm[4:0]=10000  op=0100011',
    '                                                                   ^',
    '                                                    bit imm[4]=1 -> offset += 16',
])

pdf.subsection('5.4  Conteudo final do boot.hex')
pdf.code_block([
    '00010097   <- linha 1',
    'F5008093   <- linha 2',
    '00100113   <- linha 3',
    '0020A823   <- linha 4  (DUMMY: sw x2, 16(x1)  -> 0x8000FF60)',
    '0020A023   <- linha 5  (TOHOST: sw x2, 0(x1)  -> 0x8000FF50)',
    '0000006F   <- linhas 6-256  (jal x0, 0 - preenchimento)',
])

# ----------------------------------------------------------------
# SECAO 6 - RESULTADOS
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('6', 'Resultados de Simulacao')

pdf.subsection('6.1  Configuracao do teste final')
rows_cfg = [
    ('Programa',           'boot.hex com 2 stores (dummy + tohost)'),
    ('Ciclos ate GOOD_TRAP','194 ciclos'),
    ('Tempo de simulacao', '1940 ns'),
    ('Boot address',       '0x8000_0000'),
    ('Endereco tohost',    '0x8000_FF50'),
    ('Valor escrito',      '1 (x2=1, sw x2, 0(x1))'),
    ('Store filtrado',     '0x8000_FF60 (dummy) - ciclo 192'),
    ('Store aceito',       '0x8000_FF50 (tohost) - ciclo 193'),
    ('Ciclo de GOOD_TRAP', '194 (ciclo apos o commit tohost)'),
    ('Ferramenta',         'Vivado xsim 2025.1, simulate.log'),
]
pdf.table(['Parametro', 'Valor'], rows_cfg, [48, 122])

pdf.subsection('6.2  Timeline de eventos (Fase 2)')
pdf.code_block([
    't=    0 ns  (c=0):    Reset ativo (rst_n=0)',
    't=~2000 ns  (c=~100): Reset liberado (spc_grst_l=1)',
    't=3485 ns  (c=148):   Icache flush completo (128 linhas invalidadas)',
    't=3495 ns  (c=149):   Fetch request vaddr=0x8000_0000',
    't=3505 ns  (c=150):   MISS no icache -> L15 IMISS addr=0x0080000000',
    't=3545 ns  (c=154):   noc1W=1 -- flit saiu pelo West (off-chip)',
    't=3855 ns  (c=185):   NOC2 resp: instrucoes recebidas pela SRAM model',
    't=3865 ns  (c=186):   Icache fill: instrucoes no cache (clhit=1)',
    't=~3890 ns (c=~189):  Pipeline busca/decodifica/executa auipc, addi, addi',
    't=1920 ns  (c=192):   commit_i=1, addr=0x8000FF60 -- DUMMY store',
    '                      Filtrado: endereco != 0x8000FF50, GOOD_TRAP nao dispara',
    't=1930 ns  (c=193):   commit_i=1, addr=0x8000FF50 -- TOHOST store',
    '                      MATCH! good_trap[0] := 1',
    't=1940 ns  (c=194):   $display: GOOD_TRAP detectado, simulacao termina',
    '                      ==== PASS ====',
])

pdf.subsection('6.3  Resultado final')
pdf.set_fill_color(20, 80, 40)
pdf.set_text_color(*WHITE)
pdf.set_font('Courier', 'B', 9)
for line in [
    '  ==========================================================',
    '  RESULTADO FINAL -- Fase 2',
    '    Ciclos ate GOOD_TRAP   : 194',
    '    Store dummy (0xFF60)   : FILTRADO corretamente no ciclo 192',
    '    Store tohost (0xFF50)  : ACEITO corretamente no ciclo 193',
    '    good_trap[0]           : 1  (PASS)',
    '  GOOD_TRAP: Dual-Core CVA6 executou programa com store tohost.',
    '  ==========================================================',
]:
    pdf.cell(0, 5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)
pdf.set_font('Helvetica', '', 9)
pdf.ln(3)

pdf.ok_box(
    'Confirmado: o mecanismo de deteccao GOOD_TRAP filtra corretamente por endereco. '
    'O store dummy (0xFF60) nao dispara o GOOD_TRAP; apenas o store tohost (0xFF50) '
    'o faz. A hierarquia cross-module no xsim e estavel e sem crashes.'
)

# ----------------------------------------------------------------
# SECAO 7 - OBSTACULOS E SOLUCOES
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('7', 'Analise dos Obstaculos e Solucoes')

pdf.subsection('7.1  Tabela de obstaculos encontrados')
rows_obs = [
    ('Invocacao do simulador',
     'Tentativa de xsim.bat -mode tcl falhou (exit 1)',
     'Usar vivado.bat -mode batch -source run.tcl -tclargs <target>'),
    ('DLL nao encontrada',
     'xsim.exe direto: exit 53 + 0xC0000135',
     'xsim.exe precisa das DLLs do Vivado; usar vivado.bat como wrapper'),
    ('xsimk.exe apagado',
     'Erro "snapshot does not exist" - kernel de sim apagado por engano',
     'Rodar -tclargs elaborate para regenerar o snapshot'),
    ('Falso positivo GOOD_TRAP',
     'commit_i disparou no store dummy (0xFF60) em vez do tohost',
     'Implementar verificacao de endereco: comparar addr[31:0] com TOHOST_ADDR32'),
    ('Indexacao dinamica em struct',
     'Risco de crash xsim em assign com indice variavel',
     'Confirmado seguro: LEITURA hierarquica via assign nao causa crash'),
    ('Erro TerosHDL vlog-19',
     'IDE exibiu erro de parsing apos editar dut_wrap.sv',
     'Erro apenas no plugin IDE (parser limitado); simulacao compilou sem erros'),
]
for obs, prob, sol in rows_obs:
    pdf.set_font('Helvetica', 'B', 9)
    pdf.set_text_color(*BLUE_MID)
    pdf.cell(0, 5, obs, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_text_color(*BLACK)
    pdf.set_font('Helvetica', '', 9)
    pdf.body('Problema: ' + prob, indent=4)
    pdf.body('Solucao: ' + sol, indent=4)

pdf.subsection('7.2  Licao aprendida: leitura hierarquica no xsim')
pdf.body(
    'O crash FATAL_ERROR do xsim 2025.1 e especifico de ESCRITA procedural '
    'em always_comb sobre arrays de struct packed de tamanho nao-potencia-de-2 (131 bits). '
    'Leituras hierarquicas (assigns, always_ff) sao completamente seguras, '
    'incluindo indexacao dinamica. Isso abre caminho para monitoramento '
    'rico do estado interno do CVA6 sem modificar o RTL.'
)

pdf.subsection('7.3  Alternativa ao workaround de store buffer')
pdf.body(
    'A deteccao via commit_i e o monitor de tohost sao uma alternativa robusta '
    'ao workaround do store buffer stub. Em vez de tentar "consertar" o store '
    'buffer para o xsim (o que causaria crash), monitoramos o commit no pipeline '
    'antes do store chegar ao dcache. O resultado e equivalente para fins de '
    'verificacao funcional.'
)

# ----------------------------------------------------------------
# SECAO 8 - PROXIMOS PASSOS
# ----------------------------------------------------------------
pdf.add_page()
pdf.section_title('8', 'Proximos Passos')

pdf.subsection('8.1  Imediato - Extender o programa de boot')
pdf.body('Com o mecanismo GOOD_TRAP validado, o boot.hex pode ser estendido:')
pdf.bullet('Adicionar mais instrucoes aritmeticas e logicas (add, sub, and, or, xor, slt).')
pdf.bullet('Incluir loads (lw, ld) para verificar leitura de dados alem de instrucoes.')
pdf.bullet('Implementar um loop de contagem: auipc -> addi -> sw -> beq -> loop.')
pdf.bullet('Calcular resultado esperado e comparar via store tohost com valor != 1.')

pdf.subsection('8.2  Curto prazo - Monitorar tile 1 tambem')
pdf.body(
    'O mecanismo atual monitora apenas tile0 (sb0_commit_i, sb0_commit_addr). '
    'Para verificar o tile 1:'
)
pdf.bullet('Adicionar alias SB1 apontando para tile1 na hierarquia.')
pdf.bullet('good_trap[1] controlado separadamente.')
pdf.bullet('Verificar que ambos os cores terminam independentemente.')

pdf.subsection('8.3  Curto prazo - Programa ELF compilado')
pdf.body('Substituir boot.hex manual por ELF compilado:')
pdf.bullet('Compilar com riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d -O0.')
pdf.bullet(
    'Usar tohost/fromhost da convencao riscv-tests: '
    'write tohost = (result << 1) | 1 para PASS, ou valor par para FAIL.'
)
pdf.bullet('Extrair .hex via objcopy --output-target=verilog.')
pdf.bullet('Atualizar criterio de PASS: verificar tohost[0]=1 (bit de sucesso).')

pdf.subsection('8.4  Medio prazo - Verificacao completa de stores')
pdf.body(
    'Embora commit_i seja suficiente para deteccao de tohost, o caminho completo '
    'store -> dcache -> NoC -> SRAM nao e verificado no xsim. Opcoes:'
)
pdf.bullet('Usar ModelSim/QuestaSim (isim free tier) para validar o store buffer sem stub.')
pdf.bullet('Investigar se o crash do xsim e reproduzivel em Vivado 2024.x (versao anterior).')
pdf.bullet('Considerar VERILATOR como alternativa open-source para o caminho de stores.')

pdf.subsection('8.5  Medio prazo - Teste de coerencia multi-core')
pdf.body('Com dois cores funcionando, testar protocolos de coerencia:')
pdf.bullet('Core 0 escreve em endereco X; core 1 le X - verificar valor correto.')
pdf.bullet('Verificar MSG_MESI=EXCLUSIVE e invalidacoes via NoC entre tiles.')
pdf.bullet('Implementar spinlock entre os dois cores como smoke test de sincronizacao.')

pdf.subsection('8.6  Longo prazo - OpenSBI + Boot Linux')
pdf.body(
    'Com o pipeline de dados e coerencia validados, tentar boot de firmware real:'
)
pdf.bullet('OpenSBI como firmware M-mode (Supervisor Binary Interface).')
pdf.bullet('U-Boot ou coreboot minimo para inicializacao de plataforma.')
pdf.bullet('Kernel Linux 6.x (RISC-V SMP) com rootfs initramfs.')
pdf.bullet('/proc/cpuinfo deve mostrar os 2 harts CVA6 (hart0, hart1).')

pdf.subsection('8.7  Longo prazo - Sintese FPGA')
pdf.bullet('Target: Xilinx Zynq UltraScale+ (ZCU102) ou Artix-7.')
pdf.bullet('Substituir tc_sram por primitivas BRAM (wrapper ja existe).')
pdf.bullet('Timing closure: CVA6 tipicamente 100 MHz em UltraScale+.')
pdf.bullet('UART e GPIO para interacao via console serial.')

# ----------------------------------------------------------------
# SALVAR
# ----------------------------------------------------------------
out_path = r'C:\Users\rafae\Documents\SoC_dual_core\doc\relatorio_avancos_fase2.pdf'
pdf.output(out_path)
print('PDF gerado: ' + out_path)
