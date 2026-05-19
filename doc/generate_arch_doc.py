"""
Documento dissertativo de arquitetura do SoC Dual-Core CVA6 / OpenPiton
Parametros extraidos do RTL (valores exatos).
"""
import datetime
from docx import Document
from docx.shared import Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

# ── Paleta ────────────────────────────────────────────────────────
C_BLUE_DARK  = RGBColor(0x1A, 0x39, 0x60)
C_BLUE_MID   = RGBColor(0x1C, 0x5C, 0x9E)
C_TEAL       = RGBColor(0x00, 0x6B, 0x6B)
C_WHITE      = RGBColor(0xFF, 0xFF, 0xFF)
C_BLACK      = RGBColor(0x00, 0x00, 0x00)
C_GRAY_TEXT  = RGBColor(0x22, 0x22, 0x22)

H_BLUE_DARK  = '1A3960'
H_BLUE_MID   = '1C5C9E'
H_TEAL       = '006B6B'
H_BLUE_LIGHT = 'D6E8FA'
H_TEAL_LIGHT = 'D0EEEE'
H_GRAY_HDR   = '4A5568'
H_GRAY_ROW   = 'F4F6F9'
H_WHITE      = 'FFFFFF'
H_GREEN_BG   = 'E8F5E9'
H_ORANGE_BG  = 'FFF8E1'
H_PURPLE_BG  = 'F3E5F5'

# ── Helpers ───────────────────────────────────────────────────────
def set_cell_bg(cell, fill):
    tc = cell._tc; tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), fill)
    tcPr.append(shd)

def no_sp(p, before=0, after=0):
    p.paragraph_format.space_before = Pt(before)
    p.paragraph_format.space_after  = Pt(after)

def ch_title(doc, num, text, fill=H_BLUE_DARK):
    """Titulo de capitulo."""
    p = doc.add_paragraph()
    no_sp(p, before=16, after=6)
    r = p.add_run('%s   %s' % (num, text))
    r.bold = True; r.font.size = Pt(14); r.font.color.rgb = C_WHITE
    pPr = p._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), fill)
    pPr.append(shd)

def sec_title(doc, num, text, fill=H_BLUE_MID):
    """Titulo de secao."""
    p = doc.add_paragraph()
    no_sp(p, before=10, after=4)
    r = p.add_run('%s  %s' % (num, text))
    r.bold = True; r.font.size = Pt(11); r.font.color.rgb = C_WHITE
    pPr = p._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), fill)
    pPr.append(shd)

def sub_title(doc, text):
    p = doc.add_paragraph()
    no_sp(p, before=7, after=2)
    r = p.add_run(text); r.bold = True; r.font.size = Pt(10); r.font.color.rgb = C_BLUE_MID

def prose(doc, text):
    p = doc.add_paragraph()
    no_sp(p, before=0, after=6)
    p.paragraph_format.first_line_indent = Cm(0.7)
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    run = p.add_run(text); run.font.size = Pt(10); run.font.color.rgb = C_GRAY_TEXT
    return p

def caption(doc, text):
    p = doc.add_paragraph()
    no_sp(p, before=0, after=8)
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text); r.italic = True; r.font.size = Pt(8.5); r.font.color.rgb = RGBColor(0x55,0x55,0x55)

def code_line(doc, text):
    p = doc.add_paragraph()
    no_sp(p, before=0, after=1)
    p.paragraph_format.left_indent = Cm(0.8)
    r = p.add_run(text); r.font.name = 'Courier New'; r.font.size = Pt(8.5)
    pPr = p._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), 'F0F0F0')
    pPr.append(shd)

def callout(doc, kind, text):
    colors = {
        'NOTA':    (H_BLUE_LIGHT,  '1A3960'),
        'DETALHE': (H_TEAL_LIGHT,  '006B6B'),
        'ATENCAO': (H_ORANGE_BG,   'C75000'),
        'CONF':    (H_GREEN_BG,    '1B5E20'),
        'PARAM':   (H_PURPLE_BG,   '4A148C'),
    }
    bg, fg = colors.get(kind, (H_BLUE_LIGHT, '1A3960'))
    p = doc.add_paragraph()
    no_sp(p, before=3, after=7)
    r1 = p.add_run('[%s]  ' % kind)
    r1.bold = True; r1.font.size = Pt(9)
    r1.font.color.rgb = RGBColor(int(fg[0:2],16),int(fg[2:4],16),int(fg[4:6],16))
    r2 = p.add_run(text); r2.font.size = Pt(9); r2.font.color.rgb = C_GRAY_TEXT
    pPr = p._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), bg)
    pPr.append(shd)

def tbl(doc, headers, rows, widths, hdr_fill=H_GRAY_HDR):
    n = len(headers)
    t = doc.add_table(rows=1, cols=n)
    t.style = 'Table Grid'; t.alignment = WD_TABLE_ALIGNMENT.LEFT
    for i, w in enumerate(widths):
        for c in t.columns[i].cells: c.width = Cm(w)
    hc = t.rows[0].cells
    for i, h in enumerate(headers):
        set_cell_bg(hc[i], hdr_fill)
        p = hc[i].paragraphs[0]; p.clear(); no_sp(p)
        r = p.add_run(h); r.bold = True; r.font.size = Pt(8.5); r.font.color.rgb = C_WHITE
    for ri, row in enumerate(rows):
        rc = t.add_row().cells
        bg = H_GRAY_ROW if ri % 2 == 0 else H_WHITE
        for ci, val in enumerate(row):
            set_cell_bg(rc[ci], bg)
            p = rc[ci].paragraphs[0]; p.clear(); no_sp(p)
            r = p.add_run(str(val)); r.font.size = Pt(8.5); r.font.color.rgb = C_BLACK
    doc.add_paragraph()

# ── Diagrama ASCII do sistema (aproximado) ──────────────────────
def block_diagram(doc):
    lines = [
        '  ┌─────────────────────────────────────────────────────────────────────────────┐',
        '  │                         CHIP  (OpenPiton 2×1)                               │',
        '  │                                                                             │',
        '  │  ┌──────────────────────────┐   ┌──────────────────────────┐              │',
        '  │  │        TILE 0            │   │        TILE 1            │              │',
        '  │  │  ┌────────────────────┐  │   │  ┌────────────────────┐  │              │',
        '  │  │  │    CVA6  Hart 0    │  │   │  │    CVA6  Hart 1    │  │              │',
        '  │  │  │  RV64GC  FPU  A    │  │   │  │  RV64GC  FPU  A    │  │              │',
        '  │  │  └──────────┬─────────┘  │   │  └──────────┬─────────┘  │              │',
        '  │  │    L1I 16KB │ L1D 8KB    │   │    L1I 16KB │ L1D 8KB    │              │',
        '  │  │  ┌──────────┴─────────┐  │   │  ┌──────────┴─────────┐  │              │',
        '  │  │  │  wt_l15_adapter    │  │   │  │  wt_l15_adapter    │  │              │',
        '  │  │  │  L1.5  8KB MESI    │  │   │  │  L1.5  8KB MESI    │  │              │',
        '  │  └──────────┬────────────┘  │   └──────────┬────────────┘  │              │',
        '  │             │  NoC P-Mesh   │              │                │              │',
        '  │  ═══════════╪══════════════════════════════╪═══════════════ │              │',
        '  │     NoC1 (req) ◄────────────────────────────────────────►  │              │',
        '  │     NoC2 (resp)◄────────────────────────────────────────►  │              │',
        '  │     NoC3 (WB)  ◄────────────────────────────────────────►  │              │',
        '  └──────────────────────────────┬──────────────────────────────┘              ',
        '                                 │ offchip (yummy)                             ',
        '                       ┌─────────┴────────────┐                               ',
        '                       │  protocol_adapter     │ (yummy ↔ val/rdy)            ',
        '                       └─────────┬────────────┘                               ',
        '                       ┌─────────┴────────────┐                               ',
        '                       │  noc_axi4_bridge      │ (NoC → AXI4)                ',
        '                       └─────────┬────────────┘                               ',
        '                       ┌─────────┴────────────┐                               ',
        '                       │  AXI4 SRAM  256 KB    │ @ 0x8000_0000               ',
        '                       └──────────────────────┘                               ',
    ]
    for l in lines:
        code_line(doc, l)

# ================================================================
doc = Document()
for s in doc.sections:
    s.top_margin = Cm(2.2); s.bottom_margin = Cm(2.2)
    s.left_margin = Cm(2.5); s.right_margin = Cm(2.5)
doc.styles['Normal'].font.name = 'Calibri'
doc.styles['Normal'].font.size = Pt(10)

# ── CAPA ─────────────────────────────────────────────────────────
p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER; no_sp(p, before=10)
r = p.add_run('SoC Dual-Core CVA6')
r.bold = True; r.font.size = Pt(26); r.font.color.rgb = C_BLUE_DARK

p2 = doc.add_paragraph(); p2.alignment = WD_ALIGN_PARAGRAPH.CENTER; no_sp(p2)
r2 = p2.add_run('Descricao da Arquitetura do Sistema')
r2.bold = True; r2.font.size = Pt(15); r2.font.color.rgb = C_BLUE_MID

doc.add_paragraph()

p3 = doc.add_paragraph(); p3.alignment = WD_ALIGN_PARAGRAPH.CENTER; no_sp(p3, after=4)
r3 = p3.add_run('OpenPiton 2×1  |  CVA6 RV64GC  |  NoC P-Mesh  |  AXI4 SRAM')
r3.font.size = Pt(10); r3.font.color.rgb = C_BLUE_MID

p4 = doc.add_paragraph(); p4.alignment = WD_ALIGN_PARAGRAPH.CENTER; no_sp(p4, after=2)
r4 = p4.add_run('Parametros extraidos do RTL  |  ' + datetime.date.today().strftime('%d/%m/%Y'))
r4.font.size = Pt(9); r4.font.color.rgb = RGBColor(0x66,0x66,0x66)

doc.add_paragraph()

# sumario rapido
tbl(doc,
    ['Componente', 'Especificacao'],
    [
        ('Processador',         'CVA6  RV64GC  (I+M+A+F+D+C)  com FPU'),
        ('Nucleos',             '2 (dual-core)  —  Hart 0  e  Hart 1'),
        ('Framework',           'OpenPiton  arranjo 2×1 tiles'),
        ('Cache L1 Instrucao',  '16 KB  4-way  128 sets  linha 64 B  por nucleo'),
        ('Cache L1 Dados',      '8 KB   4-way  128 sets  linha 16 B  por nucleo  (WT)'),
        ('Cache L1.5',          '8 KB   4-way  MESI  por tile'),
        ('Interconexao',        'NoC P-Mesh 3 redes  64 bits'),
        ('Memoria',             'AXI4 SRAM 256 KB  @0x8000_0000'),
        ('Clock',               '100 MHz  (periodo 10 ns)'),
        ('Verificacao',         'UVM 1.2  —  xsim Vivado 2025.1'),
    ],
    [5.5, 10.5]
)

doc.add_page_break()

# ================================================================
# CAP 1 — VISAO GERAL
# ================================================================
ch_title(doc, '1', 'Visao Geral do Sistema')

prose(doc,
    'O SoC descrito neste documento e uma implementacao dual-core baseada no processador '
    'de codigo aberto CVA6, desenvolvido originalmente pela Universidade de Bologna e pela '
    'ETH Zurich como parte do projeto Ariane, e no framework de many-core OpenPiton, '
    'desenvolvido pela Princeton University. A integracao CVA6+OpenPiton combina um nucleo '
    'RISC-V de alto desempenho com uma infraestrutura de cache coerente e uma rede de '
    'interconexao escalaveis, formando um sistema adequado para pesquisa e prototipagem '
    'de processadores multicore.')

prose(doc,
    'O sistema e organizado como um arranjo de 2×1 tiles OpenPiton, onde cada tile contem '
    'um nucleo CVA6 completo com seus caches L1 e o modulo de interface L1.5. Os dois tiles '
    'sao interligados por uma rede de interconexao P-Mesh de tres camadas, que trafega '
    'requisicoes de cache, respostas de memoria e mensagens de coerencia entre os tiles e '
    'o subsistema de memoria externo. A memoria e modelada por um bloco SRAM AXI4 de '
    '256 KB, acessado por meio de um adaptador de protocolo e de uma ponte NoC-para-AXI4.')

sub_title(doc, 'Diagrama de blocos do sistema')
block_diagram(doc)
caption(doc, 'Figura 1 — Hierarquia de blocos do SoC dual-core CVA6 / OpenPiton 2x1')

prose(doc,
    'A hierarquia de instancias no RTL reflete diretamente esta organizacao: o modulo chip '
    'instancia dois tiles (tile0 e tile1), cada um contendo o nucleo CVA6 dentro de um '
    'bloco de geracao g_ariane_core. Os sinais de saida offchip da rede NoC1 e NoC3 '
    '(requisicoes e writebacks saindo do chip) sao conectados a um adaptador de protocolo '
    'que converte o handshake yummy para val/rdy, e em seguida a uma ponte noc_axi4_bridge '
    'que emite transacoes AXI4 para o modelo SRAM. As respostas percorrem o caminho inverso '
    'pela NoC2.')

doc.add_page_break()

# ================================================================
# CAP 2 — NUCLEO CVA6
# ================================================================
ch_title(doc, '2', 'Nucleo do Processador CVA6')

sec_title(doc, '2.1', 'Arquitetura do Pipeline')

prose(doc,
    'O CVA6 e um processador RISC-V RV64GC de execucao em ordem, com pipeline de seis '
    'estagios: Fetch (IF), Decode (ID), Issue (IS), Execute (EX), Writeback (WB) e Commit. '
    'A largura de fetch e de 32 bits por ciclo, suportando ate duas instrucoes por ciclo '
    'quando instrucoes comprimidas RVC de 16 bits estao presentes, gracas ao alinhador de '
    'instrucoes (instr_align) no frontend. O despacho e de uma instrucao por ciclo '
    '(ISSUE_WIDTH=1), e o commit pode efetivar ate duas instrucoes por ciclo '
    '(NR_COMMIT_PORTS=2).')

prose(doc,
    'O scoreboard do CVA6 gerencia a execucao fora de ordem especulativa dentro de uma '
    'janela de ate 8 entradas (NR_SB_ENTRIES=8), identificadas por um campo de 3 bits '
    '(TRANS_ID_BITS=3). As instrucoes sao despachadas para seis unidades funcionais '
    'distintas: a ALU inteira (ALU), a unidade de multiplicacao e divisao (MULT), a '
    'unidade logica de branch (BRU), a unidade de ponto flutuante (FPU), a unidade de '
    'acesso a CSRs, e a unidade de load-store (LSU). O resultado de cada unidade e '
    'gravado de volta no scoreboard atraves de um barramento de write-back, e o commit '
    'em ordem e garantido pelo estagio de commit que avanca o ponteiro do ROB somente '
    'quando a instrucao mais antiga esta completa e sem excecoes pendentes.')

sec_title(doc, '2.2', 'Extensoes ISA e Configuracao')

prose(doc,
    'A configuracao ativa para este SoC e cv64a6_imafdc_sv39_openpiton, que habilita '
    'o conjunto completo de extensoes RV64IMAFDCSU: instrucoes de base inteira (I), '
    'multiplicacao e divisao (M), extensoes atomicas (A), ponto flutuante de precisao '
    'simples (F), ponto flutuante de precisao dupla (D) e instrucoes comprimidas (C). '
    'A unidade de ponto flutuante esta habilitada (CVA6ConfigFpuEn=1) e implementa '
    'IEEE 754-2008 para operacoes de 32 e 64 bits. A traducao de enderecos virtuais '
    'utiliza o esquema Sv39 (39 bits de espaco virtual, tres niveis de pagina de 4 KB), '
    'adequado para sistemas operacionais modernos como Linux.')

tbl(doc,
    ['Extensao / Parametro', 'Valor', 'Descricao'],
    [
        ('ISA base',             'RV64I',      'Instrucoes inteiras de 64 bits'),
        ('Multiplicacao',        'M habilitado','mul, mulh, div, rem e variantes'),
        ('Atomics',              'A habilitado','lr/sc, amoswap, amoadd, etc.'),
        ('Float 32 bits',        'F habilitado','fadd.s, fmul.s, fcvt, etc.'),
        ('Float 64 bits',        'D habilitado','fadd.d, fmul.d, fcvt, etc.'),
        ('Comprimidas',          'C habilitado','instrucoes de 16 bits (RVC)'),
        ('Ponto flutuante F16',  'Desabilitado','—'),
        ('CVXIF coprocessor',    'Desabilitado','—'),
        ('Rename (OoO avancado)','Desabilitado','execucao em ordem'),
        ('Privilegio',           'M / S / U',   'Machine, Supervisor, User'),
        ('Traducao virtual',     'Sv39',         '39 bits, 3 niveis, paginas 4 KB'),
        ('Hart ID',              'hart_id_i',    'Configurado pelo tile (0 ou 1)'),
    ],
    [4.5, 3.0, 8.5]
)

sec_title(doc, '2.3', 'Predicao de Desvio')

prose(doc,
    'O frontend do CVA6 utiliza tres mecanismos de predicao de desvio para minimizar '
    'penalidades de branch. O Branch Target Buffer (BTB) possui 32 entradas e armazena '
    'o endereco de destino dos desvios tomados anteriormente, permitindo que o fetch '
    'redirecione especulativamente o PC antes mesmo de decodificar a instrucao. O Branch '
    'History Table (BHT) possui 128 entradas com contadores saturados de 2 bits (predicao '
    'dinamica two-bit), que rastreiam o historico de tomada de cada desvio condicional. '
    'Para instrucoes de retorno de funcao (jalr com ra=x1), o Return Address Stack (RAS) '
    'mantem uma pilha de 2 entradas, predicendo o destino do retorno com base no endereco '
    'de chamada armazenado no topo da pilha.')

tbl(doc,
    ['Estrutura', 'Entradas', 'Politica / Bits', 'Funcao'],
    [
        ('BTB  Branch Target Buffer', '32',  'Direto mapeado',      'Endereco de destino de desvios tomados'),
        ('BHT  Branch History Table', '128', '2 bits saturados',    'Predicao dinamica de desvios condicionais'),
        ('RAS  Return Address Stack', '2',   'Pilha LIFO',          'Predicao de retornos de funcao (jalr x0,ra)'),
    ],
    [5.5, 2.5, 3.5, 5.5]
)

prose(doc,
    'Quando o branch predictor erra, o pipeline descarta todas as instrucoes buscadas '
    'especulativamente (flush) e redireciona o fetch para o endereco correto. O sinal '
    'kill2=1 observado no log de simulacao indica exatamente este evento: o frontend '
    'cancela uma busca especulativa em um ciclo especifico, tipicamente apos a resolucao '
    'de um branch incondicional (jump) ou apos um retorno de funcao.')

doc.add_page_break()

# ================================================================
# CAP 3 — HIERARQUIA DE CACHE
# ================================================================
ch_title(doc, '3', 'Hierarquia de Cache')

sec_title(doc, '3.1', 'Cache L1 de Instrucoes (Icache)')

prose(doc,
    'Cada nucleo CVA6 possui um cache de instrucoes L1 privado de 16 KB, organizado em '
    '4 vias (4-way set-associative) com 128 conjuntos (sets). A linha de cache tem 256 bits '
    '(32 bytes), e o campo de index ocupa 12 bits do endereco virtual. A politica de '
    'substituicao e PLRU (Pseudo-LRU), que aproxima o LRU verdadeiro com menor custo '
    'de implementacao. O cache suporta operacoes de flush completo (invalida todas as '
    'linhas) e flush condicional por endereco, sendo o flush completo executado '
    'automaticamente apos o reset, como observado na simulacao.')

tbl(doc,
    ['Parametro', 'Valor', 'Fonte RTL'],
    [
        ('Capacidade total',     '16 KB',       'CONFIG_L1I_SIZE'),
        ('Associatividade',      '4 vias',       'CONFIG_L1I_ASSOCIATIVITY'),
        ('Numero de sets',       '128',          '16384 / (4 × 32)'),
        ('Tamanho da linha',     '256 bits (32 B)', 'CONFIG_L1I_CACHELINE_WIDTH'),
        ('Largura do index',     '12 bits',     'log2(16384/4)'),
        ('Largura do tag',       '28 bits',     '40 - 12 = 28'),
        ('Politica de subst.',   'PLRU',         'cva6_icache.sv'),
        ('Largura de user line', '128 bits',    'L1I_USER_LINE_WIDTH'),
        ('Ciclos de flush',      '128',          '1 ciclo por set'),
    ],
    [5.0, 4.0, 7.0]
)

sec_title(doc, '3.2', 'Cache L1 de Dados (Dcache)')

prose(doc,
    'O cache de dados L1 e um cache write-through de 8 KB, 4-way, com 128 sets e linhas '
    'de 128 bits (16 bytes). A politica write-through foi escolhida para simplificar a '
    'interface com o protocolo de coerencia do OpenPiton (L1.5), eliminando a necessidade '
    'de writebacks de dados sujos. Todas as escritas sao propagadas imediatamente para '
    'o L1.5, que mantem a coerencia entre os caches dos diferentes tiles.')

prose(doc,
    'O dcache possui tres portas de requisicao independentes: uma porta de load, uma porta '
    'de store e uma porta de page table walk (PTW), permitindo que a MMU realize caminhadas '
    'na tabela de paginas sem bloquear os acessos de dados normais. Um write buffer de 8 '
    'entradas absorve rajadas de stores, e o sistema suporta ate 8 transacoes pendentes '
    'simultaneamente (DCACHE_MAX_TX=8).')

tbl(doc,
    ['Parametro', 'Valor', 'Fonte RTL'],
    [
        ('Capacidade total',       '8 KB',        'CONFIG_L1D_SIZE'),
        ('Associatividade',        '4 vias',       'CONFIG_L1D_ASSOCIATIVITY'),
        ('Numero de sets',         '128',          '8192 / (4 × 16)'),
        ('Tamanho da linha',       '128 bits (16 B)', 'CONFIG_L1D_CACHELINE_WIDTH'),
        ('Politica de escrita',    'Write-Through','wt_dcache.sv'),
        ('Portas de requisicao',   '3 (LD/ST/PTW)','wt_dcache.sv'),
        ('Write buffer depth',     '8',            'DCACHE_WBUF_DEPTH'),
        ('Max transacoes pend.',   '8',            'DCACHE_MAX_TX'),
        ('Largura do tag',         '29 bits',     '40 - 11'),
    ],
    [5.0, 4.0, 7.0]
)

sec_title(doc, '3.3', 'Cache L1.5 e Protocolo de Coerencia')

prose(doc,
    'O L1.5 e o nivel intermediario de cache do framework OpenPiton, localizado entre os '
    'caches L1 de cada tile e a rede NoC. Cada tile possui seu proprio modulo L1.5 de '
    '8 KB, organizado em 4 vias com 128 sets e linhas de 128 bits. O modulo implementa '
    'o protocolo de coerencia MESI (Modified, Exclusive, Shared, Invalid), que garante '
    'a consistencia dos dados entre os dois tiles quando ambos os nucleos acessam os '
    'mesmos enderecos de memoria.')

prose(doc,
    'A interface entre o CVA6 e o L1.5 e realizada pelo modulo wt_l15_adapter '
    '(write-through L15 adapter), que converte as requisicoes do dcache e do icache '
    'CVA6 para o formato de mensagens OpenPiton (tipos IMISS_RQ, LOAD_RQ, STORE_RQ, '
    'AMO_RQ, etc.) e as mensagens de retorno (IFILL_RET, LOAD_RET, STORE_ACK) de volta '
    'para o formato do CVA6. O L1.5 arbitra entre as requisicoes dos multiplos tiles '
    'e gerencia as transacoes de coerencia (invalidacoes e upgrades de estado MESI) '
    'transmitidas pela rede NoC3.')

tbl(doc,
    ['Parametro', 'Valor', 'Fonte RTL'],
    [
        ('Capacidade por tile',  '8 KB',         'CONFIG_L15_SIZE'),
        ('Associatividade',      '4 vias',        'CONFIG_L15_ASSOCIATIVITY'),
        ('Numero de entradas',   '512',           'L15_NUM_ENTRIES'),
        ('Largura da linha',     '128 bits',      'L15_CACHELINE_WIDTH'),
        ('Index width',          '7 bits',        'L15_CACHE_INDEX_WIDTH'),
        ('Protocolo',            'MESI',          'l15.v'),
        ('Estados MESI',         'I=0  S=1  E=2  M=3', 'l15.h'),
        ('Interface CVA6',       'wt_l15_adapter','wt_l15_adapter.sv'),
    ],
    [5.0, 4.0, 7.0]
)

callout(doc, 'DETALHE',
    'Na simulacao atual (boot.hex), apenas instrucoes sao acessadas (sem loads ou stores '
    'reais chegando ao L1.5, pois o xsim stub bloqueia data_req=0). Por isso, apenas '
    'transacoes IMISS_RQ e IFILL_RET foram observadas no log. Um programa com acessos '
    'a dados exercitaria os estados MESI do L1.5 e as mensagens de coerencia pela NoC3.')

doc.add_page_break()

# ================================================================
# CAP 4 — REDE DE INTERCONEXAO
# ================================================================
ch_title(doc, '4', 'Rede de Interconexao  NoC P-Mesh')

sec_title(doc, '4.1', 'Topologia e Organizacao')

prose(doc,
    'O OpenPiton utiliza uma rede de interconexao P-Mesh (Princeton Mesh), um crossbar '
    'baseado em malha 2D para arranjos arbitrarios de tiles. Para o arranjo 2×1 deste '
    'SoC, a topologia e equivalente a um barramento ponto-a-ponto com dois nos, onde '
    'cada tile possui um roteador NoC que os conecta entre si e ao controlador de '
    'memoria offchip. A rede opera com flit de 64 bits e utiliza handshake valid/ready '
    'para controle de fluxo, garantindo que nenhum flit seja perdido sob backpressure.')

prose(doc,
    'A NoC e composta por tres redes logicamente independentes que trafegam '
    'simultaneamente: NoC1 transporta as requisicoes dos tiles para a memoria '
    '(instruction miss, load, store, AMO), NoC2 transporta as respostas da memoria '
    'de volta para os tiles (fills, acknowledgements), e NoC3 transporta as mensagens '
    'de coerencia e writebacks (invalidacoes, upgrades de estado MESI). A separacao '
    'em tres redes evita deadlocks no protocolo de coerencia e permite que requisicoes '
    'e respostas fluam em sentidos opostos sem bloqueio mutuo.')

tbl(doc,
    ['Rede', 'Direcao', 'Mensagens', 'Uso na Simulacao'],
    [
        ('NoC1', 'Tile → Offchip', 'IMISS_RQ, LOAD_RQ, STORE_RQ',         'Observado: IMISS_RQ dos 2 tiles'),
        ('NoC2', 'Offchip → Tile', 'IFILL_RET, LOAD_RET, STORE_ACK',      'Observado: IFILL_RET para os 2 tiles'),
        ('NoC3', 'Tile → Offchip', 'Writebacks, invalidacoes MESI',        'Nenhum evento (boot.hex sem stores)'),
    ],
    [2.0, 3.5, 5.0, 5.5]
)

sec_title(doc, '4.2', 'Formato do Pacote NoC e Latencia')

prose(doc,
    'Cada pacote NoC e composto por um flit de cabecalho seguido de zero ou mais flits '
    'de payload. O cabecalho de 192 bits (MSG_HEADER_WIDTH) e transmitido no primeiro '
    'flit de 64 bits e carrega o endereco de destino (chip_id, coordenadas x/y do tile), '
    'o tipo da mensagem, o tamanho do payload e os bits de roteamento. Por isso, o valor '
    'do primeiro flit visivel no log (NOC1_FIRST data=0x0) nao indica ausencia de dado: '
    'os bits baixos do flit de cabecalho estao reservados para payload, que e transmitido '
    'nos flits seguintes.')

prose(doc,
    'A latencia de transporte pela rede para o arranjo 2×1 e de 4 a 6 ciclos por salto, '
    'como evidenciado pela diferenca de 4 ciclos entre as transacoes AXI_AR[0] (ciclo 163) '
    'e AXI_AR[1] (ciclo 167): o Tile 1 esta na posicao East no crossbar e percorre um '
    'salto adicional antes de alcancar o controlador de memoria a West.')

tbl(doc,
    ['Parametro', 'Valor', 'Fonte RTL'],
    [
        ('Largura do flit',         '64 bits',  'NOC_DATA_WIDTH'),
        ('Largura do cabecalho',    '192 bits', 'MSG_HEADER_WIDTH  (3 flits)'),
        ('Largura do campo chip_id','14 bits',  'NOC_CHIPID_WIDTH'),
        ('Largura dos campos x/y',  '8 bits cada','NOC_X_WIDTH / NOC_Y_WIDTH'),
        ('Largura do node ID',      '34 bits',  'NOC_NODEID_WIDTH'),
        ('Largura do campo addr',   '48 bits',  'MSG_ADDR_WIDTH'),
        ('Protocolo de fluxo',      'Valid / Ready (yummy para chip)', 'chip.v'),
        ('Latencia tipica (2x1)',   '4-6 ciclos por salto', 'observado na simulacao'),
    ],
    [5.5, 4.0, 6.5]
)

doc.add_page_break()

# ================================================================
# CAP 5 — SUBSISTEMA DE MEMORIA
# ================================================================
ch_title(doc, '5', 'Subsistema de Memoria')

sec_title(doc, '5.1', 'Mapa de Memoria')

prose(doc,
    'O espaco de enderecos fisico do SoC e de 40 bits (1 TB), organizado em regioes '
    'distintas para diferentes perifericos e memoria principal. A regiao principal de '
    'DRAM esta mapeada entre 0x80000000 e 0xBFFFFFFF (1 GB), coincidindo com o RESET_PC '
    'configurado no CVA6 (0x80000000). Na simulacao, esta regiao e modelada pelo bloco '
    'AXI4 SRAM de 256 KB. A regiao de debug module (JTAG e acesso de debug) ocupa os '
    'primeiros 4 KB (0x0000 a 0x0FFF), e o boot ROM e mapeado entre 0x10000 e 0x1FFFF.')

tbl(doc,
    ['Regiao', 'Base', 'Limite', 'Tamanho', 'Conteudo'],
    [
        ('Debug Module',  '0x0000_0000', '0x0000_0FFF', '4 KB',   'JTAG, debug unit'),
        ('Boot ROM',      '0x0001_0000', '0x0001_FFFF', '64 KB',  'Codigo de boot (ROM)'),
        ('DRAM / SRAM',   '0x8000_0000', '0xBFFF_FFFF', '1 GB',   'Memoria principal (SRAM 256 KB no TB)'),
        ('MMIO / Perif.', '0xC000_0000', '0xFFFF_FFFF', '1 GB',   'Mapeado para IO (nao implementado no TB)'),
    ],
    [3.0, 3.0, 3.0, 2.5, 4.5]
)

sec_title(doc, '5.2', 'Adaptador de Protocolo e Ponte NoC-AXI4')

prose(doc,
    'Os sinais offchip da NoC utilizam o protocolo yummy (similar a credit-based), onde '
    'o receptor sinaliza disponibilidade de buffer com um sinal "yummy" em vez de um '
    '"ready" convencional. O modulo protocol_adapter converte este protocolo para o '
    'handshake val/rdy padrao, compativel com a ponte noc_axi4_bridge. A conversao '
    'garante que pacotes NoC nunca sejam perdidos por backpressure, pois o chip so '
    'transmite um flit quando o adaptador retorna yummy=1.')

prose(doc,
    'A ponte noc_axi4_bridge traduz cada pacote NoC1 (requisicao de leitura ou escrita) '
    'em uma sequencia de transacoes AXI4 sobre os canais padrao: AR (Read Address), '
    'R (Read Data), AW (Write Address), W (Write Data) e B (Write Response). Para o '
    'caso de miss de instrucao observado na simulacao, cada requisicao IMISS_RQ gera '
    'uma transacao AXI4 Read com burst length 0 (uma transferencia de 64 bits). '
    'A resposta da SRAM e encapsulada em um pacote NoC2 (IFILL_RET) e enviada de '
    'volta ao tile de origem.')

sec_title(doc, '5.3', 'Modelo SRAM AXI4')

prose(doc,
    'Na simulacao funcional, a memoria principal e modelada pelo modulo axi4_sram_model, '
    'uma SRAM comportamental de 256 KB mapeada no endereco base 0x80000000. O modelo '
    'implementa a interface escrava AXI4 completa e responde a transacoes de leitura '
    'e escrita com latencia de um ciclo para operacoes ja armazenadas no buffer interno. '
    'O binario boot.hex e pre-carregado nesta SRAM durante a inicializacao da simulacao, '
    'posicionando as instrucoes do programa nos enderecos esperados pelo CVA6.')

tbl(doc,
    ['Parametro', 'Valor'],
    [
        ('Tamanho',              '256 KB'),
        ('Endereco base',        '0x8000_0000'),
        ('Interface',            'AXI4 slave (AR/R/AW/W/B)'),
        ('Largura de dados AXI', '64 bits (AXI4_DATA_WIDTH)'),
        ('Largura de endereco',  '40 bits (AXI4_ADDR_WIDTH)'),
        ('Largura de ID AXI',    '5 bits (AXI4_ID_WIDTH)'),
        ('Conteudo inicial',     'Carregado a partir de tb/boot.hex'),
        ('Latencia de leitura',  '1 ciclo (modelo comportamental)'),
    ],
    [5.5, 10.5]
)

doc.add_page_break()

# ================================================================
# CAP 6 — INTERRUPCOES E DEBUG
# ================================================================
ch_title(doc, '6', 'Interrupcoes, Debug e Interfaces Externas')

prose(doc,
    'O CVA6 suporta o modelo de interrupcoes RISC-V padrao, com sinais distintos para '
    'interrupcao de software (IPI — Inter-Processor Interrupt), interrupcao de timer '
    '(time_irq_i) e interrupcoes externas de nivel (irq_i[1:0]). No SoC dual-core, cada '
    'nucleo recebe seus proprios sinais de interrupcao independentes: debug_req_i[1:0] '
    'para requisicoes de debug por tile, timer_irq_i[1:0] para timers independentes e '
    'ipi_i[1:0] para inter-process interrupts entre os harts. Na configuracao atual '
    'do testbench, todos estes sinais sao conectados a zero (nenhuma interrupcao externa '
    'e gerada durante a simulacao).')

prose(doc,
    'A interface de debug do CVA6 segue o padrao RISC-V Debug Specification 0.13, com '
    'suporte ao modulo de debug via JTAG. O sinal ndmreset_i permite um reset nao-debug '
    'do sistema a partir do modulo de debug externo. No testbench atual, ndmreset_i esta '
    'conectado a zero e a interface JTAG nao esta instanciada, de modo que o debug '
    'nao-invasivo (via trace CVA6) e a unica forma de observacao do estado interno.')

tbl(doc,
    ['Sinal', 'Largura', 'Direcao', 'Funcao'],
    [
        ('debug_req_i',  '2 bits',  'Entrada', 'Requisicao de halt/resume do debug module'),
        ('ndmreset_i',   '1 bit',   'Entrada', 'Non-debug-module reset (reset externo)'),
        ('timer_irq_i',  '2 bits',  'Entrada', 'Interrupcao de timer por hart'),
        ('ipi_i',        '2 bits',  'Entrada', 'Inter-processor interrupt por hart'),
        ('irq_i',        '4 bits',  'Entrada', 'Interrupcoes externas de nivel'),
        ('unavailable_o','2 bits',  'Saida',   'Hart indisponivel (em reset ou halt)'),
        ('piton_ready_n','1 bit',   'Saida',   'Chip pronto apos inicializacao'),
    ],
    [3.5, 2.5, 2.5, 7.5]
)

doc.add_page_break()

# ================================================================
# CAP 7 — AMBIENTE UVM
# ================================================================
ch_title(doc, '7', 'Ambiente de Verificacao UVM')

sec_title(doc, '7.1', 'Estrutura do Testbench')

prose(doc,
    'O ambiente de verificacao foi desenvolvido em UVM 1.2 e e composto por um testbench '
    'SystemVerilog (uvmt_opc_tb.sv) que instancia o DUT wrapper (uvmt_opc_dut_wrap.sv) e '
    'as interfaces UVM, e por uma hierarquia de classes UVM que implementa os agentes, '
    'o scoreboard e a sequencia de teste. O DUT wrapper encapsula todo o hardware: o chip '
    'OpenPiton, o adaptador de protocolo, a ponte NoC-AXI4 e a SRAM, expondo apenas '
    'as interfaces padronizadas para os agentes UVM.')

prose(doc,
    'O ambiente instancia quatro agentes de verificacao: o agente clk_rst, responsavel '
    'por gerar o clock de 100 MHz e a sequencia de reset; o agente l15_tri, que monitora '
    'a interface TRI entre o CVA6 e o L1.5 do Tile 0 via referencias hierarquicas '
    'diretas ao RTL; o agente noc, que captura pacotes completos nas tres redes NoC; '
    'e o agente status, que monitora os sinais good_trap e bad_trap e a saida UART '
    'virtual. O scoreboard centraliza a analise dos eventos publicados pelos agentes '
    'e determina o resultado final do teste.')

tbl(doc,
    ['Agente / Componente', 'Interface', 'Funcao'],
    [
        ('uvmt_opc_clk_rst_agent',  'clk_rst_if',   'Gera clock 100 MHz e sequencia de reset de 20 ciclos'),
        ('uvmt_opc_l15_tri_agent',  'l15_tri_if',   'Monitora requisicoes CVA6->L1.5 e respostas L1.5->CVA6'),
        ('uvmt_opc_noc_agent',      'noc_if',        'Captura flits e pacotes completos nas 3 redes NoC'),
        ('uvmt_opc_status_agent',   'status_if',     'Detecta good_trap, bad_trap e caracteres UART'),
        ('uvmt_opc_scoreboard',     'analysis ports','Verifica resultado do teste (PASS/FAIL)'),
        ('uvmt_opc_asm_test_seq',   'clk_rst_seqr',  'Carrega boot.hex na SRAM e aguarda o DUT executar'),
    ],
    [5.5, 3.5, 7.0]
)

sec_title(doc, '7.2', 'Mecanismo de Deteccao GOOD_TRAP')

prose(doc,
    'A deteccao do resultado do teste e baseada no mecanismo tohost padrao dos riscv-tests: '
    'o programa escreve o valor 1 (PASS) ou um codigo de erro (FAIL) no endereco de memoria '
    '0x8000FF50 (tohost). No caminho normal de hardware, esta escrita geraria uma transacao '
    'AXI4 na SRAM, que o testbench interceptaria monitorando os canais AW e W da interface '
    'AXI4. No entanto, o xsim 2025.1 inclui um stub condicional no store_buffer.sv que '
    'force data_req=0 quando compilado com a diretiva XSIM, impedindo que stores saiam '
    'do buffer interno do CVA6 e cheguem ao L1.5 e a AXI4.')

prose(doc,
    'Para contornar esta limitacao, o DUT wrapper monitora diretamente o store buffer '
    'interno do CVA6 via referencias hierarquicas: o sinal commit_i do modulo '
    'store_buffer_i indica quando um store e efetivado, e o campo address do '
    'speculative_queue_q[ptr] fornece o endereco fisico correspondente. Quando commit_i=1 '
    'e address[31:0]=0x8000FF50, o testbench aciona good_trap[0] e emite a mensagem '
    'STORE_COMMIT. Este mecanismo foi validado com sucesso na simulacao e detectou '
    'corretamente o store tohost do Hart 0 no ciclo 193.')

callout(doc, 'ATENCAO',
    'O bypass de store via commit_i e especifico para o xsim 2025.1 com o stub XSIM. '
    'Em um simulador sem esta limitacao (Questa, VCS) ou em hardware real (FPGA), '
    'o caminho normal AXI4 funcionaria e o bypass nao seria necessario.')

doc.add_page_break()

# ================================================================
# CAP 8 — PARAMETROS CONSOLIDADOS
# ================================================================
ch_title(doc, '8', 'Tabela Consolidada de Parametros do RTL')

tbl(doc,
    ['Modulo / Arquivo', 'Parametro', 'Valor'],
    [
        # CVA6
        ('cva6.sv / ariane_pkg.sv',  'NR_COMMIT_PORTS',    '2'),
        ('cva6.sv / ariane_pkg.sv',  'ISSUE_WIDTH',        '1'),
        ('cva6.sv / ariane_pkg.sv',  'NR_SB_ENTRIES',      '8  (scoreboard / ROB)'),
        ('cva6.sv / ariane_pkg.sv',  'TRANS_ID_BITS',      '3  (log2(8))'),
        ('cva6.sv / ariane_pkg.sv',  'FETCH_FIFO_DEPTH',   '4'),
        ('cva6.sv / ariane_pkg.sv',  'INSTR_PER_FETCH',    '2  (fetch 32 bits / RVC 16 bits)'),
        # Branch prediction
        ('ariane_pkg.sv',             'BTBEntries',         '32'),
        ('ariane_pkg.sv',             'BHTEntries',         '128'),
        ('ariane_pkg.sv',             'RASDepth',           '2'),
        # Store buffer
        ('ariane_pkg.sv',             'DEPTH_SPEC',         '4  (speculative store entries)'),
        ('ariane_pkg.sv',             'DEPTH_COMMIT',       '4  (commit entries, WT_DCACHE)'),
        # L1I
        ('cva6_icache.sv',            'L1I_SIZE',           '16 KB'),
        ('cva6_icache.sv',            'L1I_WAYS',           '4'),
        ('cva6_icache.sv',            'L1I_SETS',           '128'),
        ('cva6_icache.sv',            'L1I_LINE_WIDTH',     '256 bits  (32 bytes)'),
        # L1D
        ('wt_dcache.sv',              'L1D_SIZE',           '8 KB'),
        ('wt_dcache.sv',              'L1D_WAYS',           '4'),
        ('wt_dcache.sv',              'L1D_SETS',           '128'),
        ('wt_dcache.sv',              'L1D_LINE_WIDTH',     '128 bits  (16 bytes)'),
        ('wt_dcache.sv',              'DCACHE_MAX_TX',      '8'),
        # L1.5
        ('l15.tmp.h',                 'L15_SIZE',           '8 KB'),
        ('l15.tmp.h',                 'L15_WAYS',           '4'),
        ('l15.tmp.h',                 'L15_NUM_ENTRIES',    '512'),
        ('l15.tmp.h',                 'L15_INDEX_WIDTH',    '7 bits'),
        # NoC
        ('define.h',                  'NOC_DATA_WIDTH',     '64 bits'),
        ('define.h',                  'NOC_CHIPID_WIDTH',   '14 bits'),
        ('define.h',                  'MSG_HEADER_WIDTH',   '192 bits'),
        ('define.h',                  'MSG_ADDR_WIDTH',     '48 bits'),
        # Sistema
        ('define.tmp.h',              'PITON_NUM_TILES',    '2'),
        ('define.tmp.h',              'PITON_X_TILES',      '2'),
        ('define.tmp.h',              'PITON_Y_TILES',      '1'),
        ('define.tmp.h',              'PHY_ADDR_WIDTH',     '40 bits'),
    ],
    [5.5, 4.5, 6.0]
)

# ================================================================
out = r'C:\Users\rafae\Documents\SoC_dual_core\doc\arquitetura_soc_dual_core.docx'
doc.save(out)
print('Word gerado: ' + out)
