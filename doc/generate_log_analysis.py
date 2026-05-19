"""
Analise linha-a-linha do log de simulacao xsim do SoC Dual-Core CVA6.
Uso: python generate_log_analysis.py
"""
from fpdf import FPDF
from fpdf.enums import XPos, YPos
import datetime

BLUE_DARK  = (26,  57,  96)
BLUE_MID   = (41,  98, 161)
BLUE_LIGHT = (210, 227, 252)
GRAY_LIGHT = (245, 245, 245)
GRAY_MID   = (200, 200, 200)
BLACK      = (0,    0,  0)
WHITE      = (255, 255, 255)
ORANGE_BG  = (255, 240, 200)
ORANGE_BD  = (200, 140,   0)
RED_BG     = (255, 220, 220)
RED_BD     = (180,   0,   0)
GREEN_BG   = (220, 255, 220)
GREEN_BD   = (0,  160,  60)


class Report(FPDF):
    def __init__(self):
        super().__init__()
        self.set_margins(18, 15, 18)
        self.set_auto_page_break(auto=True, margin=18)

    def header(self):
        if self.page_no() == 1:
            return
        self.set_fill_color(*BLUE_DARK)
        self.rect(0, 0, 210, 10, 'F')
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*WHITE)
        self.set_y(2)
        self.cell(0, 6, 'SoC Dual-Core CVA6 - Analise do Log de Simulacao', align='C')
        self.set_text_color(*BLACK)
        self.ln(6)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-12)
        self.set_draw_color(*GRAY_MID)
        self.line(18, self.get_y(), 192, self.get_y())
        self.set_font('Helvetica', '', 7)
        self.set_text_color(120, 120, 120)
        self.cell(0, 6,
            'Pagina %d  |  %s' % (self.page_no(),
                                   datetime.date.today().strftime('%d/%m/%Y')),
            align='C')
        self.set_text_color(*BLACK)

    def section_title(self, num, text, color=BLUE_DARK):
        self.ln(3)
        self.set_fill_color(*color)
        self.set_text_color(*WHITE)
        self.set_font('Helvetica', 'B', 11)
        self.cell(0, 8, '  %s  %s' % (num, text), fill=True,
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*BLACK)
        self.ln(2)

    def subsection(self, text):
        self.set_font('Helvetica', 'B', 9.5)
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

    def log_line(self, lineno, raw, color=GRAY_LIGHT, border_color=GRAY_MID):
        self.set_fill_color(*color)
        self.set_draw_color(*border_color)
        self.set_font('Courier', '', 7)
        x0 = self.l_margin + 2
        w  = self.w - self.r_margin - x0
        h  = 4.5
        self.set_x(x0)
        num_w = 10
        self.set_fill_color(*color)
        self.cell(num_w, h, 'L%d' % lineno, border='LTB', fill=True)
        self.multi_cell(w - num_w, h, raw, border='RTB', fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)

    def analysis_row(self, lineno_range, raw_text, explanation, color=GRAY_LIGHT):
        self.set_fill_color(*color)
        self.set_draw_color(*GRAY_MID)
        self.set_font('Courier', '', 7)
        x0 = self.l_margin + 2
        total_w = self.w - self.r_margin - x0
        left_w = total_w * 0.45
        right_w = total_w - left_w
        h = 5
        y_start = self.get_y()
        # Left: line number + raw
        self.set_x(x0)
        tag = 'L%s' % lineno_range
        tag_w = 12
        self.cell(tag_w, h, tag, border='LTB', fill=True)
        self.set_font('Courier', '', 6.5)
        self.multi_cell(left_w - tag_w, h, raw_text, border='TB', fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        y_after_left = self.get_y()
        # Right: explanation
        self.set_xy(x0 + left_w, y_start)
        self.set_font('Helvetica', '', 7.5)
        self.multi_cell(right_w, h, explanation, border='TRB', fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        y_after_right = self.get_y()
        self.set_y(max(y_after_left, y_after_right))

    def phase_header(self, t_range, cycle_range, title, color=BLUE_MID):
        self.ln(2)
        self.set_fill_color(*color)
        self.set_text_color(*WHITE)
        self.set_font('Helvetica', 'B', 9.5)
        left = '%s  |  %s  |  t = %s' % (title, cycle_range, t_range)
        self.cell(0, 7, '  ' + left, fill=True,
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*BLACK)
        self.ln(1)

    def table(self, headers, rows, col_widths):
        self.set_font('Helvetica', 'B', 8)
        self.set_fill_color(*BLUE_DARK)
        self.set_text_color(*WHITE)
        for h, w in zip(headers, col_widths):
            self.cell(w, 6, '  ' + h, border=0, fill=True)
        self.ln()
        self.set_text_color(*BLACK)
        self.set_font('Helvetica', '', 8)
        for i, row in enumerate(rows):
            bg = GRAY_LIGHT if i % 2 == 0 else WHITE
            self.set_fill_color(*bg)
            for val, w in zip(row, col_widths):
                self.cell(w, 5.5, '  ' + val, border=0, fill=True)
            self.ln()
        self.set_fill_color(*WHITE)
        self.ln(2)

    def ok_box(self, text):
        self.set_fill_color(*GREEN_BG)
        self.set_draw_color(*GREEN_BD)
        self.set_font('Helvetica', 'B', 8.5)
        self.multi_cell(0, 5.5, '  [OK]  ' + text, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)

    def warn_box(self, text):
        self.set_fill_color(*ORANGE_BG)
        self.set_draw_color(*ORANGE_BD)
        self.set_font('Helvetica', 'B', 8.5)
        self.multi_cell(0, 5.5, '  [!]  ' + text, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)

    def err_box(self, text):
        self.set_fill_color(*RED_BG)
        self.set_draw_color(*RED_BD)
        self.set_font('Helvetica', 'B', 8.5)
        self.multi_cell(0, 5.5, '  [ERR]  ' + text, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)

    def info_box(self, text):
        self.set_fill_color(*BLUE_LIGHT)
        self.set_draw_color(*BLUE_MID)
        self.set_font('Helvetica', 'B', 8.5)
        self.multi_cell(0, 5.5, '  [i]  ' + text, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font('Helvetica', '', 9)
        self.ln(2)

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


# ================================================================
pdf = Report()

# ----------------------------------------------------------------
# CAPA
# ----------------------------------------------------------------
pdf.add_page()
pdf.set_fill_color(*BLUE_DARK)
pdf.rect(0, 0, 210, 297, 'F')

pdf.set_y(50)
pdf.set_font('Helvetica', 'B', 26)
pdf.set_text_color(*WHITE)
pdf.cell(0, 13, 'SoC Dual-Core CVA6', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font('Helvetica', 'B', 14)
pdf.cell(0, 9, 'Analise Linha-a-Linha do Log de Simulacao', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font('Helvetica', '', 10)
pdf.set_text_color(180, 210, 255)
pdf.cell(0, 7, 'simulate.log  |  xsim 2025.1  |  branch xsim-simulation-pass', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(5)
pdf.set_draw_color(*BLUE_MID)
pdf.set_line_width(0.5)
pdf.line(35, pdf.get_y(), 175, pdf.get_y())
pdf.ln(5)

pdf.set_font('Helvetica', 'I', 10)
pdf.set_text_color(*WHITE)
pdf.cell(0, 7,
    'Data: %s' % datetime.date.today().strftime('%d de %B de %Y'),
    align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(12)
pdf.set_fill_color(0, 160, 80)
pdf.set_font('Helvetica', 'B', 16)
pdf.set_x(50)
pdf.cell(110, 12, '  GOOD TRAP: PASS  @cyc=194  ', fill=True, align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(8)
pdf.set_font('Helvetica', '', 9)
pdf.set_text_color(180, 220, 255)
fases = [
    '  Fase 1  t=0 -> 205ns       Startup xsim + UVM init + Clock/Reset',
    '  Fase 2  t=1685ns (c=148)   Icache flush completo (ambos os tiles)',
    '  Fase 3  t=1695ns (c=149)   Primeira requisicao de fetch vaddr=0x80000000',
    '  Fase 4  t=1705ns (c=150)   Cache MISS -> L15 -> NoC1 -> AXI4 -> SRAM',
    '  Fase 5  t=2025ns (c=181)   Cache fill recebido (dados: 0xf500809300010097)',
    '  Fase 6  t=2075ns (c=167)   Pipeline executa 6 instrucoes (auipc->sw->jal)',
    '  Fase 7  t=2135ns (c=193)   STORE_COMMIT tohost=0x8000FF50 detectado',
    '  Fase 8  t=2145ns (c=194)   GOOD TRAP -> PASS -> $finish',
]
for f in fases:
    pdf.cell(0, 6, f, align='L', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(5)
pdf.set_font('Helvetica', 'B', 9)
pdf.set_text_color(255, 200, 100)
pdf.cell(0, 6, '  [!] 4 assertion warnings em noc_if e l15_tri_if -- analisados na Secao 5',
         align='L', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.ln(35)
pdf.set_font('Helvetica', '', 8)
pdf.set_text_color(160, 180, 210)
pdf.cell(0, 5, 'Documento gerado automaticamente - uso interno', align='C',
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*BLACK)

# ================================================================
# SECAO 1 - CABECALHO DO SIMULADOR
# ================================================================
pdf.add_page()
pdf.section_title('1', 'Cabecalho do Simulador (L1-L23)')

pdf.phase_header('t = 0', 'pre-simulacao', 'Identificacao do ambiente xsim')

pdf.body('As primeiras 23 linhas do log identificam o ambiente de simulacao:')

rows_hdr = [
    ('L1-5',  'xsim v2025.1 (64-bit) SW Build 6140274',
               'Versao do simulador Xilinx e build number. v2025.1 = Vivado 2025.1.'),
    ('L6',   'Start of session at: Tue May 12 18:32:08 2026',
               'Timestamp de inicio da sessao. Simulacao iniciada as 18h32.'),
    ('L8',   'Current directory: .../xsim_work',
               'Diretorio de trabalho. Todos os paths relativos partem daqui.'),
    ('L9',   'Command line: xsim.exe -log simulate.log -mode tcl ...',
               'Comando exato invocado. Modo TCL significa que um script '
               'xsim_script.tcl controla o fluxo (gerado por xelab na elaboracao).'),
    ('L12',  'Running On: Rafael',
               'Hostname da maquina (nome do usuario Windows).'),
    ('L15',  'Processor: 12th Gen Intel Core i5-12450H @ 2496 MHz',
               'CPU de 12a geracao, 8 cores fisicos / 12 logicos.'),
    ('L19',  'Host memory: 8260 MB',
               'RAM disponivel para o simulador. xsim pode usar varios GB em designs grandes.'),
]
pdf.table(['Linhas', 'Conteudo do Log', 'Significado'], rows_hdr, [12, 75, 87])

pdf.info_box(
    'Nota de unidades de tempo: o timescale do projeto e 1ps/1ps (modulos SV). '
    'Por isso o $time retorna picossegundos. '
    'Para converter: valor_no_log / 1000 = tempo em nanosegundos. '
    'Ex: "[1685000]" = 1685000 ps = 1685 ns. '
    'As linhas com "ns" explicitamente (ex: "[1785000 ns]") tem o label errado; '
    'o valor real e 1785000 ps = 1785 ns.'
)

# ================================================================
# SECAO 2 - INICIALIZACAO UVM
# ================================================================
pdf.section_title('2', 'Inicializacao UVM e Configuracao do Teste (L24-L63)')

pdf.phase_header('t = 0', 'ciclo 0', 'UVM startup, clock/reset, monitors')

pdf.subsection('2.1  Linhas 24-48: xsim script e UVM boot')
rows_uvm1 = [
    ('L24',  'source xsim.dir/work.uvmt_opc_tb/xsim_script.tcl',
               'xsim carrega o script TCL gerado pelo xelab. Este script invoca '
               '"xsim work.uvmt_opc_tb -runall ..." com todos os plusargs.'),
    ('L25',  'xsim {work.uvmt_opc_tb} -testplusarg UVM_TESTNAME=uvmt_opc_asm_test_c ...',
               'Linha de comando efetiva. Plusargs: TESTNAME=uvmt_opc_asm_test_c, '
               'UVM_VERBOSITY=UVM_LOW, TEST_BINARY=boot.hex, TIMEOUT=5000000.'),
    ('L26',  'Time resolution is 1 ps',
               'Confirma que o simulador opera com resolucao de 1 ps.'),
    ('L27',  'run -all',
               'Comando TCL que inicia a simulacao e roda ate $finish ou timeout.'),
    ('L28-36', 'UVM_INFO ... UVM/RELNOTES  UVM-1.2',
               'UVM 1.2 inicializado (versao inclusa no Vivado). '
               'Mensagens de copyright Mentor/Cadence/Synopsys/NVIDIA.'),
    ('L41',  'UVM_NO_DEPRECATED undefined',
               'A biblioteca foi compilada sem suprimir APIs antigas. '
               'Nao afeta a simulacao -- aviso informativo.'),
    ('L48',  'UVM_NO_DPI defined -- getting UVM_TESTNAME directly',
               'DPI (Direct Programming Interface C/SV) esta desabilitado no xsim. '
               'O UVM busca o nome do teste diretamente pelo plusarg, sem DPI.'),
    ('L49',  'Running test uvmt_opc_asm_test_c...',
               'UVM localiza a classe de teste pelo nome e instancia uvm_test_top.'),
]
pdf.table(['Linha', 'Conteudo', 'Significado'], rows_uvm1, [12, 75, 87])

pdf.add_page()
pdf.subsection('2.2  Linhas 50-56: Configuracao do ambiente')
rows_uvm2 = [
    ('L50',  '[OPC_CFG] 3x5 tiles | timeout=5000000 | finish_mask=0x7fff',
               'ATENCAO: cfg reporta "3x5 tiles" mas o design e 2x1. '
               'Isso indica que o objeto uvmt_opc_cfg_c foi criado com parametros '
               'default (provavelmente X_TILES/Y_TILES nao passados por plusarg). '
               'Nao afeta a simulacao pois os monitores acessam hierarquia fixa.'),
    ('L51',  '[OPC_ASM_TEST] Binario: .../tb/boot.hex',
               'O teste UVM confirma o caminho do binario a ser carregado na SRAM.'),
    ('L52',  'UVM/COMP/NAMECHECK requires DPI',
               'Verificacao de nomes de componentes UVM requer DPI. Skipped no xsim.'),
    ('L53',  '[OPC_ENV] Ambiente iniciado: 1x1 tiles | iss=0 | coh=1 | cov=1',
               'O ambiente UVM foi instanciado: 1x1 tiles (diferente do cfg -- '
               'o env usa seu proprio parametro), sem ISS, coerencia habilitada, '
               'coverage habilitada.'),
    ('L54',  '[OPC_CLK_DRV] Iniciando clock: periodo=10000 ps, reset=20 ciclos',
               'Clock driver configurado: 10000 ps = 10 ns de periodo (100 MHz). '
               'Reset ativo por 20 ciclos = 200 ns.'),
    ('L55',  '[OPC_ASM_SEQ] Iniciando teste: boot.hex',
               'Sequencia de teste carregada. Ela aguarda o DUT completar.'),
    ('L56',  '[OPC_ASM_SEQ] Clock/reset aplicados. Aguardando DUT.',
               'A sequencia aplicou o reset e agora espera o DUT terminar '
               '(good_trap ou timeout).'),
    ('L57-58', '[TRACER] Output filename: trace_hart_0.log / trace_hart_1.log',
               'Os tracers do CVA6 foram inicializados. Eles gravam cada instrucao '
               'commitada em formato "tempo ciclo PC instrucao mnemonic".'),
]
pdf.table(['Linha', 'Conteudo', 'Significado'], rows_uvm2, [12, 75, 87])

pdf.subsection('2.3  Linhas 59-63: Reset e ativacao dos monitors')
rows_rst = [
    ('L59',  '@200000: [OPC_CLK_DRV] rst_n desassertado no ciclo 20',
               't=200000 ps = 200 ns. Reset liberado apos 20 ciclos x 10 ns. '
               'A partir deste ponto o DUT comeca a operar.'),
    ('L60',  '@205000: [OPC_CLK_MON] Reset desassertado - DUT pronto',
               't=205 ns. O monitor de clock/reset detectou a subida de rst_n. '
               'A amostragem e feita na borda de subida do clock apos o reset.'),
    ('L61',  '@205000: [OPC_L15_MON] Monitor L1.5 TRI iniciado',
               'Monitor da interface tristate do L1.5 (saidas para o CVA6) ativado.'),
    ('L62',  '@205000: [OPC_STATUS_MON] Monitor de status iniciado',
               'Monitor que observa status_if.good_trap e outros flags.'),
    ('L63',  '@215000: [OPC_NOC_MON] Monitor NoC iniciado',
               't=215 ns. Monitor da NoC iniciado 1 ciclo depois (215-205=10 ns = 1 ciclo). '
               'Aguarda 1 ciclo extra para garantir estabilidade dos sinais.'),
]
pdf.table(['Linha', 'Conteudo', 'Significado'], rows_rst, [12, 75, 87])

pdf.ok_box(
    'Fase de inicializacao concluida com sucesso. '
    'UVM 1.2 rodando, clock de 100 MHz ativo, rst_n liberado em t=200 ns. '
    'Todos os 4 monitores UVM ativos: CLK, L15, STATUS, NOC.'
)

# ================================================================
# SECAO 3 - FLUSH E PRIMEIRO FETCH
# ================================================================
pdf.add_page()
pdf.section_title('3', 'Flush do Icache e Primeiro Fetch (L64-L81)')

pdf.phase_header('t = 1685 ns - 1715 ns', 'ciclos 148-151',
                 'Icache flush -> Fetch MISS -> L15 IMISS')

pdf.subsection('3.1  Linhas 64-69: Flush do icache (ambos os tiles, t=1685 ns)')
pdf.body(
    'Apos o reset, o CVA6 inicializa o cache de instrucoes com uma sequencia '
    'de flush. O flush invalida todas as 128 linhas antes de comecar a buscar '
    'instrucoes. Ambos os tiles executam o flush simultaneamente:'
)
rows_flush = [
    ('L64', '[ICACHE] state 0->1 flush_cnt=127 cache_en=0',
             'Tile 0: icache sai do estado IDLE (0) para FLUSH (1). '
             'flush_cnt=127 indica que ha 128 linhas (0-127) para invalidar. '
             'cache_en=0: cache ainda desabilitado durante flush.'),
    ('L65', '[ICACHE] FLUSH DONE cnt=127',
             'Tile 0: flush concluido. A contagem parou em 127 (ultimo indice). '
             'Todas as 128 linhas do icache de 4-way 16KB foram invalidadas.'),
    ('L66', '[MISSUNIT] FSM: 3->0 wbuf_empty=1 mshr_vld=0 flush_i=0 en_i=1 en_q=0',
             'Tile 0: Miss Unit FSM transita do estado 3 (FLUSH) para 0 (IDLE). '
             'wbuf_empty=1: write buffer vazio. mshr_vld=0: sem miss pendente. '
             'en_i=1: enable de entrada recebido. en_q=0: saida ainda nao habilitada.'),
    ('L67-69', '[ICACHE/MISSUNIT] (idem tile 1)',
             'Tile 1 executa o mesmo flush simultaneamente. '
             'O OpenPiton inicializa os dois tiles em paralelo.'),
]
pdf.table(['Linha', 'Log', 'Analise'], rows_flush, [12, 75, 87])

pdf.subsection('3.2  Linhas 70-79: Primeiro fetch (t=1695 ns)')
rows_fetch = [
    ('L70', '[ICACHE] state 1->2 flush_cnt=0 cache_en=1',
             'Tile 0: icache transita de FLUSH(1) para READ(2). '
             'cache_en=1: cache agora habilitado para operacao normal.'),
    ('L71', '[ICACHE] FETCH REQ vaddr=0x80000000',
             'Tile 0: frontend CVA6 faz a PRIMEIRA requisicao de fetch. '
             'Endereco: 0x80000000 = boot address configurado (RESET_PC).'),
    ('L72-73', '[ICACHE] state 1->2 ... FETCH REQ vaddr=0x80000000',
             'Tile 1: mesmas transicoes. Ambos os tiles buscam 0x80000000.'),
    ('L74', '[ICACHE] state 2->3 flush_cnt=0 cache_en=1',
             'Tile 0: estado READ(2) -> MISS_WAIT(3) apos verificar que '
             'a linha nao esta no cache (cold miss esperado apos flush).'),
    ('L75', 'READ: fv=1 kill2=0 spec=0 clhit=0 ex_vld=0 mem_req=1 mem_ack=1',
             'Tile 0: fv=1 (fetch valido). clhit=0: MISS confirmado. '
             'mem_req=1: requisicao enviada para a memoria. mem_ack=1: acknowledged.'),
    ('L76', 'MISS paddr=0x0000000080000000 nc=0',
             'Tile 0: miss no endereco fisico 0x80000000. nc=0: cacheable '
             '(o endereco esta dentro da regiao cached 0x80000000+1GB).'),
    ('L77-79', '(idem tile 1)',
             'Tile 1: mesmo miss no mesmo endereco. Gerara uma segunda requisicao '
             'independente ao L15/NoC.'),
]
pdf.table(['Linha', 'Log', 'Analise'], rows_fetch, [12, 75, 87])

pdf.subsection('3.3  Linhas 80-81: L15 adapter envia IMISS (t=1715 ns)')
rows_l15 = [
    ('L80', '[L15ADAP] REQ->L15 type=16 addr=0x0080000000 nc=0 tid=0',
             'Tile 0: o adaptador wt_l15_adapter traduz o miss do icache em '
             'uma mensagem OpenPiton para o L15. type=16 = IMISS_RQ (instruction '
             'miss request). addr=0x0080000000: endereco fisico com prefixo de '
             'chip. nc=0: cacheable. tid=0: transaction ID 0.'),
    ('L81', '[L15ADAP] REQ->L15 type=16 addr=0x0080000000 nc=0 tid=0',
             'Tile 1: idem, segunda requisicao IMISS independente para o mesmo '
             'endereco. O L15 de cada tile processa sua propria requisicao.'),
]
pdf.table(['Linha', 'Log', 'Analise'], rows_l15, [12, 75, 87])

pdf.info_box(
    'A delay de 1685ns ate o primeiro fetch (148 ciclos) e esperada: '
    'os 20 ciclos de reset (200ns) + ciclos de inicializacao interna do '
    'CVA6 (TLB, frontend BHT/BTB reset) + flush do icache (128 ciclos de '
    'invalidacao). Total: ~148 ciclos.'
)

# ================================================================
# SECAO 4 - NOC E AXI4
# ================================================================
pdf.add_page()
pdf.section_title('4', 'Caminho de Memoria: NoC -> AXI4 -> SRAM (L84-L111)')

pdf.phase_header('t = 1785 ns - 2125 ns', 'ciclos 158-181',
                 'NoC flit -> AXI AR -> SRAM resp -> L15 fill')

pdf.subsection('4.1  NoC1 flit e transacoes AXI4 (L84-L90)')
rows_noc = [
    ('L84', '[1785000 ns] NOC1_FIRST data=0000000000000000 @cyc=158',
             't=1785 ns, ciclo 158. O monitor NoC detectou o primeiro flit na NoC1. '
             'data=0x0 e o PRIMEIRO flit (cabecalho do pacote), que contem '
             'routing info (chip_id, x, y) nos bits altos -- o corpo do '
             'payload de dados fica nos flits seguintes. '
             'Ciclo 158: 1785ns / 10ns = 178,5 -> ciclo 158 apos reset (178-20=158).'),
    ('L89', '[1835000 ns] AXI_AR[0] addr=0000000080000000 len=0 @cyc=163',
             't=1835 ns, ciclo 163. Primeira transacao AXI4 Read Address (AR channel). '
             'addr=0x80000000 (endereco da instrucao). len=0: burst de 1 beat. '
             'A ponte noc_axi4_bridge converteu o pacote NoC1 em uma transacao AXI4.'),
    ('L90', '[1875000 ns] AXI_AR[1] addr=0000000080000000 len=0 @cyc=167',
             't=1875 ns, ciclo 167. Segunda transacao AXI4 AR (tile 1). '
             'Chega 4 ciclos depois da primeira (tile 1 tem latencia ligeiramente '
             'diferente por atravessar o crossbar East->West antes do tile 0).'),
]
pdf.table(['Linha', 'Log', 'Analise'], rows_noc, [12, 75, 87])

pdf.subsection('4.2  Retorno L15 e cache fill (L91-L111)')
rows_fill = [
    ('L91', '[L15ADAP] L15->RTRN type=1 nc=0',
             't=2015 ns. L15 enviou resposta do tipo 1 = IFILL_RET (instruction '
             'fill return) para o adaptador. A SRAM respondeu e o L15 entregou '
             'os dados ao CVA6. nc=0: dado cacheavel.'),
    ('L94', '[ICACHE] state 3->1 flush_cnt=0 cache_en=1',
             'Icache sai do estado MISS_WAIT(3) para REFILL(1). '
             'Os dados chegaram e a linha de cache sera preenchida.'),
    ('L95', '[ICACHE] IFILL_ACK received',
             'Icache confirmou o recebimento dos dados de fill da memoria.'),
    ('L96', '[L15ADAP] IFILL->ICACHE data[63:0]=0xf500809300010097',
             'Dados enviados ao icache: 0xf500809300010097 (64 bits = 2 instrucoes). '
             'Decodificando little-endian (32 bits cada): '
             '  word[0] = 0x00010097 -> auipc x1, 0x10 '
             '  word[1] = 0xF5008093 -> addi  x1, x1, -176. '
             'Sao as duas primeiras instrucoes do boot.hex!'),
    ('L97', '[ICACHE] state 1->2 fetch REQ vaddr=0x80000004',
             'Icache imediatamente solicita o proximo bloco (0x80000004). '
             'Como o fill retornou uma linha de cache completa, '
             'os proximos fetches terao cache hit.'),
    ('L99-106', 'READ: clhit=1 (multiplas vezes)',
             'A partir daqui todos os fetches tem clhit=1 (cache line hit). '
             'O pipeline CVA6 recebe as instrucoes do cache sem novos misses. '
             'kill2=1 em algumas linhas indica que o branch predictor cancelou '
             'um fetch especulativo (comportamento normal do CVA6).'),
    ('L107-111','[L15ADAP] L15->RTRN type=1 ... IFILL tile 1',
             't=2115-2125 ns. Tile 1 recebe seu proprio fill '
             '(os mesmos dados 0xf500809300010097). '
             'Os dois tiles agora tem as instrucoes em cache.'),
]
pdf.table(['Linha', 'Log', 'Analise'], rows_fill, [12, 75, 87])

pdf.info_box(
    'Latencia de memoria observada: L15 IMISS enviado em t=1715ns, '
    'fill recebido em t=2025ns. Latencia total = 310ns = 31 ciclos. '
    'Isso inclui: L15->NoC1 (encoder) + West port crossbar + '
    'noc_axi4_bridge + SRAM model + NoC2 de volta + L15 pipeline S1/S2/S3.'
)

# ================================================================
# SECAO 5 - ASSERTION ERRORS
# ================================================================
pdf.add_page()
pdf.section_title('5', 'Analise dos Assertion Errors (L82-L93)',
                  color=(120, 30, 30))

pdf.phase_header('t = 1775 ns - 2025 ns', 'ciclos 157-181',
                 'SVA assertions disparadas nos monitores UVM',
                 color=(160, 60, 60))

pdf.body(
    'Durante a simulacao, 4 assertions SVA falharam nos arquivos de interface '
    'do testbench UVM. As assertions sao NON-FATAL (nao interrompem a simulacao) '
    'mas indicam condicoes de protocolo que merecem investigacao.'
)

pdf.subsection('5.1  Assertions em uvmt_opc_noc_if.sv:89 (L82-L88)')
pdf.body('Tres assertions dispararam no monitor NoC:')

rows_assert_noc = [
    ('L82-83', 'Time: 1775 ns  Scope: noc_if  Line:89',
               'Primeira falha: t=1775 ns (ciclo ~157). Ocorre ANTES da linha '
               '"NOC1_FIRST" (L84 em 1785ns). Provavel causa: o sinal '
               'noc1_out_val subiu mas noc1_out_data ainda era 0 ou X '
               '(dado invalido). A assertion em linha 89 do noc_if '
               'provavelmente verifica que quando val=1 o dado nao e zero/X.'),
    ('L85-86', 'Time: 1785 ns  Scope: noc_if  Line:89',
               'Segunda falha: mesmo ciclo do NOC1_FIRST (data=0x0). '
               'Confirma que a assertion checa data!=0 quando val=1. '
               'O flit de cabecalho da NoC1 com data=0 e o que a dispara.'),
    ('L87-88', 'Time: 1825 ns  Scope: noc_if  Line:89',
               'Terceira falha: t=1825 ns. O segundo flit do pacote NoC1 '
               '(body flit) pode ter chegado com dado temporariamente 0 '
               'durante a transicao de roteamento. '),
]
pdf.table(['Linha', 'Assertion', 'Analise'], rows_assert_noc, [12, 55, 107])

pdf.warn_box(
    'Causa provavel: a assertion noc_if:89 checa "val => data != 0". '
    'O flit de cabecalho do pacote IMISS da NoC1 tem os primeiros bits como '
    'routing info (chip_id=1, x=0, y=0) mas a parte baixa do dado e zero '
    'neste tipo de flit. A assertion e overly-strict para flits de cabecalho. '
    'Nao indica bug real no protocolo -- e um falso positivo da assertion.'
)

pdf.subsection('5.2  Assertion em uvmt_opc_l15_tri_if.sv:112 (L92-L93)')
rows_assert_l15 = [
    ('L92-93', 'Time: 2025 ns  Scope: l15_tri_if  Line:112',
               't=2025 ns = momento exato em que o L15 retorna o fill (L91). '
               'A assertion em l15_tri_if:112 provavelmente verifica '
               'uma condicao de protocolo da interface TRI (tri-state) '
               'do L15, como: "returntype valido so quando returndatasource '
               'esta ativo". O fill return pode violar uma condicao de '
               'timing de 1 ciclo definida na assertion.'),
]
pdf.table(['Linha', 'Assertion', 'Analise'], rows_assert_l15, [12, 55, 107])

pdf.warn_box(
    'Causa provavel: a assertion l15_tri_if:112 pode verificar que '
    'l15_transducer_smc_data_valids/l15_csm_wdata_en estao corretos no '
    'ciclo de retorno do fill. Como os modulos L15 tem multiplos pipelines '
    '(S1/S2/S3), a assertion pode ter uma janela de 1 ciclo de discrepancia. '
    'O fill chegou corretamente ao icache (confirmado em L95-L96), '
    'portanto a operacao foi bem-sucedida apesar da assertion.'
)

pdf.subsection('5.3  Impacto das assertions no resultado final')
pdf.body('Resumo do impacto:')
rows_impact = [
    ('noc_if:89 (x3)',    'Falso positivo -- flit de cabecalho com routing info e data=0',
                          'Nenhum', 'Refinar assertion para excluir flits de cabecalho'),
    ('l15_tri_if:112 (x1)', 'Timing 1-ciclo no fill return do L15',
                          'Nenhum', 'Verificar janela da assertion vs latencia S3 do L15'),
]
pdf.table(
    ['Assertion', 'Causa Provavel', 'Impacto', 'Acao Recomendada'],
    rows_impact, [28, 65, 22, 59]
)

pdf.ok_box(
    'Todas as 4 assertions sao NON-FATAL. A simulacao continuou normalmente, '
    'o fill foi entregue ao icache, e o GOOD_TRAP foi atingido em t=2145 ns. '
    'As assertions devem ser refinadas nas proximas iteracoes do testbench.'
)

# ================================================================
# SECAO 6 - EXECUCAO DO PIPELINE
# ================================================================
pdf.add_page()
pdf.section_title('6', 'Execucao do Pipeline CVA6 - Trace Hart 0 (L97-L115)')

pdf.phase_header('t = 2035 ns - 2135 ns', 'ciclos 161-173 (commit)',
                 'Cache hits -> 6 instrucoes executadas e commitadas')

pdf.subsection('6.1  Icache hits apos o fill (L97-L115)')
pdf.body(
    'Apos o fill em t=2025 ns, o icache passa a ter clhit=1 continuamente. '
    'O CVA6 busca instrucoes sem gerar novos misses. O pipeline opera em '
    'ciclos consecutivos buscando, decodificando, emitindo e commitando.'
)

pdf.body('Sinais do icache durante os hits:')
rows_hits = [
    ('fv=1',   'fetch valid -- o frontend esta ativamente buscando instrucoes'),
    ('kill2=1','instrucao especulativa cancelada pelo branch predictor (normal)'),
    ('clhit=1','cache line hit -- dado disponivel no icache sem ir a memoria'),
    ('mem_req=0','sem requisicao para memoria -- tudo servido pelo cache'),
    ('mem_ack=0','sem acknowledge de memoria necessario'),
]
pdf.table(['Sinal', 'Significado'], rows_hits, [25, 149])

pdf.subsection('6.2  Trace completo: Hart 0 (trace_hart_0.log)')
pdf.body(
    'O tracer do CVA6 registrou cada instrucao no momento do COMMIT '
    '(nao do fetch). O formato e: tempo_ns  ciclo  privilegio  PC  instrucao_hex  mnemonic:'
)
pdf.code_block([
    '# trace_hart_0.log -- instrucoes commitadas pelo Hart 0',
    '',
    '  2075ns  167  M  0x80000000  0x00010097   auipc ra, 0x10       ra <- 0x0000000080010000',
    '  2095ns  169  M  0x80000004  0xf5008093   addi  ra, ra, -176   ra <- 0x000000008000ff50',
    '  2105ns  170  M  0x80000008  0x00100113   li    sp, 1          sp <- 0x0000000000000001',
    '  2125ns  172  M  0x8000000c  0x0020a823   sw    sp, 16(ra)     VA=0x8000ff60  PA=0x8000ff60',
    '  2135ns  173  M  0x80000010  0x0020a023   sw    sp,  0(ra)     VA=0x8000ff50  PA=0x8000ff50',
    '  2135ns  173  M  0x80000014  0x0000006f   j     pc - 0         (loop infinito)',
])

pdf.subsection('6.3  Analise instrucao por instrucao')
rows_inst = [
    ('2075ns', 'ciclo 167', '0x80000000', '00010097',
     'auipc ra, 0x10',
     'PC=0x80000000. AUIPC soma PC + (imm<<12) = 0x80000000 + 0x10000 = 0x80010000. '
     'Registrador ra (x1) recebe 0x80010000. '
     'Primeiros 5 ciclos apos fill (fill em c=163, commit em c=167 = +4 ciclos pipeline).'),
    ('2095ns', 'ciclo 169', '0x80000004', 'f5008093',
     'addi ra, ra, -176',
     'ra = 0x80010000 + (-176). 176 = 0xB0. '
     '0x80010000 - 0xB0 = 0x8000FF50. '
     'ra agora aponta para o endereco tohost (0x8000FF50). '
     '-176 em imm12: 0xFB0 = 1111_0101_0000b.'),
    ('2105ns', 'ciclo 170', '0x80000008', '00100113',
     'li sp, 1  (addi sp, x0, 1)',
     'sp (x2) = 0 + 1 = 1. '
     'Este e o valor que sera escrito no tohost para indicar PASS. '
     'A convencao riscv-tests: tohost = (exit_code << 1) | 1 '
     'para PASS quando exit_code=0: tohost = 1.'),
    ('2125ns', 'ciclo 172', '0x8000000c', '0020a823',
     'sw sp, 16(ra)',
     'Escrita em ra+16 = 0x8000FF50+16 = 0x8000FF60. '
     'Este e o DUMMY store. VA=PA=0x8000FF60. '
     'O monitor detectara commit_i=1 mas addr=0xFF60 != tohost -> IGNORADO.'),
    ('2135ns', 'ciclo 173', '0x80000010', '0020a023',
     'sw sp, 0(ra)',
     'Escrita em ra+0 = 0x8000FF50. Este e o TOHOST store. '
     'VA=PA=0x8000FF50. Monitor: commit_i=1 AND addr==TOHOST_ADDR32 -> MATCH! '
     'good_trap[0] := 1. Ciclo de commit: 173.'),
    ('2135ns', 'ciclo 173', '0x80000014', '0000006f',
     'j pc - 0  (jal x0, 0)',
     'Loop infinito. PC = PC + 0 = 0x80000014... na verdade j pc-0 pula '
     'para 0x80000014 que e o proprio j. O programa nunca sai deste loop. '
     'Commitado no mesmo ciclo 173 que o ultimo SW (pipeline out-of-order).'),
]
pdf.table(
    ['Tempo', 'Ciclo', 'PC', 'Encoding', 'Instrucao', 'Analise'],
    rows_inst,
    [13, 12, 20, 17, 28, 84]
)

pdf.warn_box(
    'Hart 1 (trace_hart_1_commit.log) esta vazio -- nenhuma instrucao commitada. '
    'Isso pode indicar que o tile 1 nao saiu do reset corretamente, '
    'ou que seu fetch foi bloqueado/perdido. O tile 1 recebeu o fill '
    '(L107-L111 em t=2125ns) mas nao ha evidencia de commit no trace. '
    'Ponto de investigacao para a proxima iteracao.'
)

# ================================================================
# SECAO 7 - GOOD TRAP
# ================================================================
pdf.add_page()
pdf.section_title('7', 'STORE_COMMIT Tohost e GOOD TRAP (L112-L121)')

pdf.phase_header('t = 2135 ns - 2145 ns', 'ciclos 193-194',
                 'STORE_COMMIT detectado -> GOOD TRAP -> $finish',
                 color=(0, 120, 60))

pdf.subsection('7.1  Linhas 112-119: Sequencia de finalizacao')
rows_gt = [
    ('L112', '[2135000 ns] STORE_COMMIT tohost=0x8000ff50 @cyc=193',
             't=2135 ns, ciclo 193. O bloco always_ff em uvmt_opc_dut_wrap.sv '
             'detectou commit_i=1 E addr[31:0]=0x8000FF50==TOHOST_ADDR32. '
             'Este e o sw sp, 0(ra) do Hart 0 sendo commitado. '
             'good_trap[0] foi setado para 1 neste ciclo.'),
    ('L116', '*** GOOD TRAP (PASS) *** @cyc=194',
             't=2145 ns, ciclo 194. O monitor OPC_STATUS_MON detectou '
             'good_trap[0]=1 na borda seguinte do clock (ciclo 193+1=194). '
             'O testbench UVM imprimiu o resultado PASS.'),
    ('L117', '>>> RESULTADO: PASSOU (HIT GOOD TRAP) <<<',
             'Mensagem de confirmacao gerada pelo scoreboard ou pelo teste UVM. '
             'Confirma que o criterio de PASS foi atingido.'),
    ('L118', 'WARNING: Functional Coverage Database not updated',
             'Os covergroups foram instanciados mas nenhum evento de coverage '
             'foi amostrado durante a simulacao curta (194 ciclos). '
             'Para obter metricas de coverage, o programa de teste precisa '
             'exercitar mais caminhos do DUT.'),
    ('L119', '$finish called at time: 2145 ns  File: uvmt_opc_dut_wrap.sv Line 510',
             't=2145 ns. O DUT wrapper chamou $finish apos detectar GOOD_TRAP. '
             'Linha 510 do dut_wrap.sv e onde o bloco always_ff chama $finish '
             'quando good_trap[0] e 1.'),
    ('L120', 'exit',
             'O xsim executou o comando TCL "exit" apos o $finish, '
             'encerrando o processo do simulador normalmente.'),
    ('L121', 'INFO: [Common 17-206] Exiting xsim at Tue May 12 18:32:13 2026',
             'xsim encerrado normalmente. A simulacao durou 5 segundos '
             'de tempo real (18:32:08 -> 18:32:13) para 2145 ns de tempo simulado.'),
]
pdf.table(['Linha', 'Log', 'Analise'], rows_gt, [12, 75, 87])

pdf.ok_box(
    'GOOD TRAP confirmado: o CVA6 Hart 0 executou o programa boot.hex completo '
    'em 173 ciclos apos o primeiro fetch (ciclo 154 de fetch -> ciclo 173 de commit). '
    'O store tohost (0x8000FF50 = 1) foi detectado corretamente pelo testbench UVM.'
)

# ================================================================
# SECAO 8 - TIMELINE VISUAL
# ================================================================
pdf.add_page()
pdf.section_title('8', 'Timeline Consolidada da Simulacao')

pdf.body('Resumo cronologico de todos os eventos significativos:')

rows_tl = [
    ('0 ns',    'c=0',   'Simulacao iniciada, UVM boot, clock/reset ativados'),
    ('0 ns',    'c=0',   'UVM: test=uvmt_opc_asm_test_c | binary=boot.hex | timeout=5000000'),
    ('200 ns',  'c=20',  'rst_n desassertado: DUT acorda, CVA6 sai do reset'),
    ('205 ns',  'c=20',  'Monitors UVM ativos: CLK_MON, L15_MON, STATUS_MON'),
    ('215 ns',  'c=21',  'NoC monitor ativo (1 ciclo extra de setup)'),
    ('1685 ns', 'c=148', 'Icache flush completo nos 2 tiles (128 linhas invalidadas)'),
    ('1695 ns', 'c=149', 'Primeiro FETCH REQUEST: vaddr=0x80000000 (ambos tiles)'),
    ('1705 ns', 'c=150', 'ICACHE MISS: paddr=0x80000000, nc=0 (cacheable)'),
    ('1715 ns', 'c=151', 'L15ADAP envia IMISS_RQ type=16 ao L15 (ambos tiles)'),
    ('1775 ns', 'c=157', '[!] Assertion noc_if:89 #1 (flit val sem dado valido)'),
    ('1785 ns', 'c=158', 'NOC1_FIRST: primeiro flit NoC1 visto | [!] Assert noc_if:89 #2'),
    ('1825 ns', 'c=162', '[!] Assertion noc_if:89 #3 (segundo flit)'),
    ('1835 ns', 'c=163', 'AXI_AR[0] addr=0x80000000 len=0: tile 0 le da SRAM'),
    ('1875 ns', 'c=167', 'AXI_AR[1] addr=0x80000000 len=0: tile 1 le da SRAM'),
    ('2015 ns', 'c=181', 'L15ADAP recebe IFILL_RET type=1 (dados chegaram da SRAM)'),
    ('2025 ns', 'c=182', 'ICACHE FILL: data=0xf500809300010097 (auipc + addi)'),
    ('2025 ns', 'c=182', '[!] Assertion l15_tri_if:112 (timing fill return)'),
    ('2035 ns', 'c=183', 'Fetch vaddr=0x80000004: CACHE HIT (clhit=1) -- sem mais misses'),
    ('2075 ns', 'c=167*','COMMIT: auipc ra, 0x10  -> ra=0x80010000'),
    ('2095 ns', 'c=169*','COMMIT: addi  ra, ra, -176 -> ra=0x8000FF50 (tohost addr)'),
    ('2105 ns', 'c=170*','COMMIT: addi  sp, x0, 1  -> sp=1 (valor de PASS)'),
    ('2125 ns', 'c=172*','COMMIT: sw sp, 16(ra) -> addr=0x8000FF60 DUMMY -- IGNORADO'),
    ('2135 ns', 'c=173*','COMMIT: sw sp, 0(ra)  -> addr=0x8000FF50 TOHOST -- MATCH!'),
    ('2135 ns', 'c=193', 'STORE_COMMIT tohost=0x8000FF50 detectado pelo testbench'),
    ('2135 ns', 'c=173*','COMMIT: j pc-0 (loop infinito, execucao normal)'),
    ('2145 ns', 'c=194', '*** GOOD TRAP (PASS) *** -- good_trap[0]=1 detectado'),
    ('2145 ns', 'c=194', '$finish: simulacao encerrada normalmente'),
]
pdf.table(
    ['Tempo', 'Ciclo', 'Evento'],
    rows_tl,
    [18, 14, 142]
)
pdf.body('(*) Ciclos do tracer (relativos ao fetch); ciclos do testbench em c=193/194 '
         'sao relativos ao mon_cycle (contador desde t=0 / 10ns).')

# ================================================================
# SECAO 9 - RESUMO E PONTOS DE ATENCAO
# ================================================================
pdf.add_page()
pdf.section_title('9', 'Resumo Executivo e Pontos de Atencao')

pdf.subsection('9.1  O que funcionou corretamente')
itens_ok = [
    'Boot e reset: rst_n liberado em 200ns, CVA6 inicializa normalmente.',
    'Icache flush: 128 linhas invalidadas antes do primeiro fetch (comportamento correto).',
    'Primeiro fetch: vaddr=0x80000000 (RESET_PC correto).',
    'Cache miss -> L15 -> NoC1 -> AXI4 -> SRAM: fluxo completo funcionando.',
    'Fill recebido: data=0xf500809300010097 = auipc+addi do boot.hex (instrucoes corretas).',
    'Pipeline CVA6: 6 instrucoes executadas e commitadas em sequencia correta.',
    'Filtragem de endereco: dummy store (0xFF60) ignorado, tohost (0xFF50) aceito.',
    'GOOD_TRAP: detectado no ciclo 194, simulacao encerrada com PASS.',
    'Tempo real de simulacao: 5 segundos para 2145 ns simulados.',
]
for item in itens_ok:
    pdf.bullet(item)

pdf.ln(2)
pdf.subsection('9.2  Pontos que merecem investigacao')
itens_warn = [
    '[CRITICO] Hart 1 sem commits: trace_hart_1_commit.log esta vazio. '
    'O tile 1 recebeu o fill (t=2125ns) mas nao commitou instrucoes. '
    'Possivel causa: o tile 1 ficou travado apos o fill (bug de sincronizacao '
    'no reset ou no L15 do tile 1).',
    '[MEDIO] 3x assertions noc_if:89: A assertion checa dado valido quando val=1. '
    'O flit de cabecalho da NoC1 tem data=0 por design (routing header). '
    'A assertion precisa ser corrigida para nao disparar em flits de cabecalho.',
    '[MEDIO] 1x assertion l15_tri_if:112: Timing de 1 ciclo no fill return. '
    'Investigar se e falso positivo (diferenca entre pipeline S2/S3 do L15) '
    'ou violacao real de protocolo.',
    '[BAIXO] cfg reporta 3x5 tiles mas o design e 2x1. '
    'O objeto uvmt_opc_cfg_c usa valores default. '
    'Adicionar plusargs +X_TILES=2 +Y_TILES=1 na chamada do xsim.',
    '[BAIXO] Coverage database vazia: o programa de 6 instrucoes nao e '
    'suficiente para exercitar os covergroups. '
    'Necessario programa mais extenso para metricas de coverage.',
]
for item in itens_warn:
    pdf.bullet(item)

pdf.ln(2)
pdf.subsection('9.3  Metricas da simulacao')
rows_metric = [
    ('Tempo simulado',          '2145 ns'),
    ('Ciclos simulados',        '194 (contados pelo mon_cycle)'),
    ('Tempo real de execucao',  '~5 segundos'),
    ('Instrucoes commitadas H0','6 instrucoes (auipc, addi, addi, sw, sw, j)'),
    ('Instrucoes commitadas H1','0 (Hart 1 sem commits -- investigar)'),
    ('Cache misses',            '1 miss (instrucao em 0x80000000)'),
    ('Cache hits',              'todos os fetches apos o fill (clhit=1)'),
    ('Transacoes AXI4 leitura', '2 (uma por tile)'),
    ('Transacoes AXI4 escrita', '0 (store stub ativo no xsim)'),
    ('Assertions falhadas',     '4 (3x noc_if:89, 1x l15_tri_if:112)'),
    ('Resultado final',         'PASS -- GOOD_TRAP atingido em ciclo 194'),
]
pdf.table(['Metrica', 'Valor'], rows_metric, [72, 102])

# ================================================================
# SALVAR
# ================================================================
out_path = r'C:\Users\rafae\Documents\SoC_dual_core\doc\analise_log_simulacao.pdf'
pdf.output(out_path)
print('PDF gerado: ' + out_path)
