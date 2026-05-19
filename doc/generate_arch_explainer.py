#!/usr/bin/env python3
"""
generate_arch_explainer.py
Gera um documento Word explicativo da arquitetura do SoC e do ambiente UVM:
  - O que é cada componente
  - Para que serve
  - Qual problema resolve

Saída: doc/Teste leitura e escrita/arquitetura_explicativa.docx
"""

import os
from docx import Document
from docx.shared import Pt, RGBColor, Cm, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR    = os.path.join(SCRIPT_DIR, "Teste leitura e escrita")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def no_sp(p, before=0, after=0):
    p.paragraph_format.space_before = Pt(before)
    p.paragraph_format.space_after  = Pt(after)
    return p

def set_cell_bg(cell, hex_color):
    tc   = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd  = OxmlElement("w:shd")
    shd.set(qn("w:val"),   "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"),  hex_color)
    tcPr.append(shd)

def set_col_width(table, widths_cm):
    for row in table.rows:
        for i, cell in enumerate(row.cells):
            if i < len(widths_cm):
                cell.width = Cm(widths_cm[i])

def prose(doc, text, indent=True):
    p = doc.add_paragraph()
    if indent:
        p.paragraph_format.first_line_indent = Cm(1.25)
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    no_sp(p, 0, 6)
    r = p.add_run(text)
    r.font.size = Pt(11)
    return p

def ch(doc, text):
    p = doc.add_heading(text, level=1)
    no_sp(p, 14, 4)
    return p

def sec(doc, text):
    p = doc.add_heading(text, level=2)
    no_sp(p, 10, 3)
    return p

def sub(doc, text):
    p = doc.add_heading(text, level=3)
    no_sp(p, 7, 2)
    return p

def card(doc, o_que_e, para_que_serve, problema_resolve,
         bg_title="1F3864", bg_body="F2F7FF"):
    """
    Caixa de 3 linhas: O que é | Para que serve | Qual problema resolve
    """
    tbl = doc.add_table(rows=3, cols=2)
    tbl.style = "Table Grid"

    labels  = ["O que é", "Para que serve", "Qual problema resolve"]
    bodies  = [o_que_e, para_que_serve, problema_resolve]
    lbl_bgs = ["1F3864", "2E5E8E", "1A4A2E"]
    bdy_bgs = ["EEF4FF", "F0F5FF", "EDFAF1"]

    for i, (lbl, body, lb, bb) in enumerate(zip(labels, bodies, lbl_bgs, bdy_bgs)):
        row = tbl.rows[i]

        # coluna 0 — rótulo
        set_cell_bg(row.cells[0], lb)
        p0 = row.cells[0].paragraphs[0]
        p0.alignment = WD_ALIGN_PARAGRAPH.CENTER
        no_sp(p0, 4, 4)
        r0 = p0.add_run(lbl)
        r0.bold = True
        r0.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        r0.font.size = Pt(9)

        # coluna 1 — conteúdo
        set_cell_bg(row.cells[1], bb)
        p1 = row.cells[1].paragraphs[0]
        p1.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        no_sp(p1, 4, 4)
        r1 = p1.add_run(body)
        r1.font.size = Pt(9.5)

    set_col_width(tbl, [3.5, 13.0])
    doc.add_paragraph()


def divider(doc, text, bg="1F3864"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.style = "Table Grid"
    cell = tbl.cell(0, 0)
    set_cell_bg(cell, bg)
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    no_sp(p, 5, 5)
    r = p.add_run(text)
    r.bold = True
    r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    r.font.size = Pt(11)
    doc.add_paragraph()


# ===========================================================================
# DOCUMENTO
# ===========================================================================
def build():
    doc = Document()

    for sec_obj in doc.sections:
        sec_obj.top_margin    = Cm(2.5)
        sec_obj.bottom_margin = Cm(2.5)
        sec_obj.left_margin   = Cm(3.0)
        sec_obj.right_margin  = Cm(2.0)

    # --------------------------------------------------------
    # CAPA
    # --------------------------------------------------------
    h = doc.add_heading(
        "Arquitetura do SoC Dual-Core CVA6\ne do Ambiente de Verificação UVM", 0)
    h.alignment = WD_ALIGN_PARAGRAPH.CENTER
    no_sp(h, 0, 8)

    sub_h = doc.add_paragraph(
        "O que é · Para que serve · Qual problema resolve\n"
        "OpenPiton 2×1 | CVA6 RV64GC | UVM 1.2 | Vivado xsim 2025.1")
    sub_h.alignment = WD_ALIGN_PARAGRAPH.CENTER
    no_sp(sub_h, 0, 20)
    for run in sub_h.runs:
        run.font.size = Pt(10)
        run.font.color.rgb = RGBColor(0x44, 0x44, 0x66)

    # --------------------------------------------------------
    # INTRODUCAO
    # --------------------------------------------------------
    ch(doc, "1  Visão Geral do Sistema")
    prose(doc,
        "Este documento descreve a arquitetura do System-on-Chip (SoC) dual-core "
        "baseado no framework OpenPiton com dois núcleos CVA6 e o ambiente de "
        "verificação UVM construído para validá-lo. Para cada componente são "
        "apresentadas três perspectivas: o que ele é (definição e características), "
        "para que serve (função dentro do sistema) e qual problema ele resolve "
        "(motivação de projeto e vantagens em relação às alternativas).")

    prose(doc,
        "O sistema foi desenvolvido com foco em pesquisa e educação em arquitetura "
        "de computadores. Toda a cadeia — desde o núcleo do processador até o "
        "ambiente de verificação — é baseada em componentes de código aberto, "
        "permitindo inspeção completa do RTL e customização irrestrita. "
        "A simulação é executada no Vivado xsim 2025.1, sem necessidade de "
        "hardware físico ou licenças de ferramentas proprietárias de EDA.")

    # --------------------------------------------------------
    # PARTE I — SOC
    # --------------------------------------------------------
    divider(doc, "PARTE I — ARQUITETURA DO SoC OPENPITON 2×1")

    # --- 2. OpenPiton ---
    ch(doc, "2  OpenPiton: o Framework do SoC")
    prose(doc,
        "OpenPiton é um framework de SoC multi-core de código aberto desenvolvido "
        "pela Universidade de Princeton. Ele fornece uma infraestrutura de tiles "
        "interligados por uma rede de interconexão (NoC) que pode ser configurada "
        "para qualquer número de núcleos e qualquer processador compatível. "
        "Neste projeto, a configuração é 2×1: dois tiles CVA6 em linha compartilhando "
        "a mesma NoC P-Mesh e a mesma SRAM.")

    card(doc,
        o_que_e=(
            "Framework de SoC tile-based de código aberto (Princeton University). "
            "Cada tile encapsula um núcleo de processador, suas caches L1 privadas, "
            "o adaptador L1.5 e a interface com a rede de interconexão NoC. "
            "O número e o tipo dos tiles são configuráveis em tempo de compilação."
        ),
        para_que_serve=(
            "Fornece toda a infraestrutura de SoC necessária para conectar múltiplos "
            "núcleos a uma memória compartilhada: arbitragem de barramento, protocolo "
            "de coerência de cache (MESI no L1.5), ponte AXI4, e controle de reset "
            "e boot. Permite que o pesquisador se concentre no núcleo (CVA6) sem "
            "reimplementar a plumbing do SoC."
        ),
        problema_resolve=(
            "Elimina a necessidade de projetar do zero a interconexão multi-core, "
            "o protocolo de coerência e a interface com memória. Alternativas "
            "proprietárias (ARM CoreLink, Intel Xeon NoC) são caixas-pretas; "
            "OpenPiton expõe todo o RTL, tornando possível medir latência real "
            "de cache miss, estudar contenção na NoC e modificar o protocolo MESI."
        )
    )

    # --- 3. CVA6 ---
    ch(doc, "3  CVA6 (Ariane): o Núcleo do Processador")
    prose(doc,
        "CVA6, anteriormente chamado Ariane, é um processador RISC-V RV64GC de "
        "código aberto desenvolvido pelo grupo PULP da ETH Zurich. Ele implementa "
        "o ISA RISC-V de 64 bits com as extensões padrão I (inteiro), M "
        "(multiplicação/divisão), A (atômicas), F e D (ponto flutuante) e C "
        "(instruções comprimidas de 16 bits). O pipeline in-order de 6 estágios "
        "foi projetado para equilíbrio entre desempenho, área e verificabilidade.")

    card(doc,
        o_que_e=(
            "Processador RISC-V RV64GC in-order, pipeline de 6 estágios "
            "(IF → ID → IS → EX → WB → COMMIT). Suporta M-extension (MUL/DIV "
            "pipelined), supervisor mode, MMU Sv39, e mecanismo de commit duplo "
            "(NR_COMMIT_PORTS=2). ROB com 8 entradas (NR_SB_ENTRIES=8). "
            "Frequência alvo de 100 MHz em FPGA Xilinx."
        ),
        para_que_serve=(
            "É o núcleo computacional de cada tile. Busca instruções via L1 ICache, "
            "decodifica, emite para unidades funcionais (ALU, multiplicador, LSU, "
            "branch unit), confirma no estágio COMMIT e atualiza o estado "
            "arquitetural. O store_buffer retém escritas pendentes até o commit, "
            "garantindo consistência com o modelo de memória RISC-V RVWMO."
        ),
        problema_resolve=(
            "Processadores RISC-V open-source de qualidade de produção eram escassos "
            "antes do CVA6. Cores simplificados (Rocket, BOOM) têm microarquiteturas "
            "muito diferentes do estilo clássico in-order. O CVA6 preenche esse "
            "espaço com um design limpo, auditável e parametrizável, adequado tanto "
            "para ASIC quanto para FPGA, sem royalties."
        )
    )

    sec(doc, "3.1  Pipeline de 6 Estágios")
    prose(doc,
        "O pipeline in-order garante que as instruções sejam comprometidas na "
        "ordem do programa, simplificando o modelo de programação e a verificação. "
        "Cada estágio tem função bem definida:", indent=False)

    tbl = doc.add_table(rows=7, cols=3)
    tbl.style = "Table Grid"
    # header
    set_cell_bg(tbl.rows[0].cells[0], "1F3864")
    set_cell_bg(tbl.rows[0].cells[1], "1F3864")
    set_cell_bg(tbl.rows[0].cells[2], "1F3864")
    for i, t in enumerate(["Estágio", "Nome", "O que faz"]):
        p = tbl.rows[0].cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        no_sp(p)
        r = p.add_run(t)
        r.bold = True; r.font.color.rgb = RGBColor(255,255,255); r.font.size = Pt(9)
    rows_data = [
        ("IF",     "Instruction Fetch",  "Solicita instrução ao L1 ICache; gera PC especulativo via BPU"),
        ("ID",     "Decode",             "Decodifica opcode, expande imediatos, lê register file"),
        ("IS",     "Issue",              "Despacha para unidade funcional disponível (sem reorder)"),
        ("EX",     "Execute",            "ALU computa resultado; multiplicador produz MUL em 1 ciclo; LSU calcula endereço"),
        ("WB",     "Write-Back",         "Escreve resultado no register file (forwarding para stages seguintes)"),
        ("COMMIT", "Commit",             "Confirma estado arquitetural; ativa store_buffer.commit_i; libera ROB"),
    ]
    bgs = ["EEF4FF","EEF4FF","EEF4FF","EEF4FF","EEF4FF","FADBD8"]
    for i, (s, n, f) in enumerate(rows_data):
        row = tbl.rows[i+1]
        for j, txt in enumerate([s, n, f]):
            set_cell_bg(row.cells[j], bgs[i])
            p = row.cells[j].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if j==2 else WD_ALIGN_PARAGRAPH.CENTER
            no_sp(p, 3, 3)
            r = p.add_run(txt)
            r.font.size = Pt(9)
            if j == 0: r.bold = True
    set_col_width(tbl, [1.5, 3.5, 11.5])
    doc.add_paragraph()

    sec(doc, "3.2  store_buffer: o Caminho de Escrita")
    prose(doc,
        "O store_buffer é uma fila FIFO de 4 entradas especulativas "
        "(speculative_queue) que armazena escritas pendentes antes de "
        "confirmá-las na hierarquia de cache. Quando o estágio COMMIT aprova "
        "a instrução SW, o bit commit_i é ativado e o endereço físico em "
        "speculative_queue_q[ptr].address torna-se autoritativo. "
        "Somente após o commit o store é enviado ao L1 DCache via req_port_o.")

    card(doc,
        o_que_e=(
            "Fila especulativa de escritas pendentes (DEPTH_SPEC=4). Cada entrada "
            "armazena endereço físico de 56 bits, dado de 64 bits (xlen_t), byte "
            "enable (8 bits), tamanho (2 bits) e flag valid. "
            "Implementado em store_buffer.sv dentro do pipeline CVA6."
        ),
        para_que_serve=(
            "Desacopla o pipeline de escritas da latência da hierarquia de memória. "
            "Sem o store_buffer, cada SW bloquearia o pipeline aguardando o ACK "
            "da SRAM (~30 ciclos). Com ele, o pipeline pode avançar e a escrita "
            "é propagada ao cache de forma assíncrona após o commit."
        ),
        problema_resolve=(
            "Garante que escritas especulativas (antes do commit) nunca vistam "
            "o estado da memória, evitando erros de consistência em caso de "
            "exceção ou branch misprediction. No xsim 2025.1, o caminho físico "
            "está bloqueado pelo stub 'ifndef XSIM; o monitor de commit_i "
            "contorna isso observando o bit diretamente no RTL."
        )
    )

    # --- 4. Hierarquia de Cache ---
    ch(doc, "4  Hierarquia de Memória")
    prose(doc,
        "O SoC implementa uma hierarquia de memória de três níveis: L1 privado "
        "por tile (ICache e DCache), L1.5 compartilhado por tile (TRI — "
        "Transactional Register Interface) e SRAM compartilhada entre tiles. "
        "A coerência de dados entre tiles é mantida pelo protocolo MESI no L1.5, "
        "com suporte a invalidação por broadcast na NoC3 (write-back network).")

    sec(doc, "4.1  L1 ICache — Cache de Instrução")
    card(doc,
        o_que_e=(
            "Cache de instrução de 16 KB, 4-way set-associative, com linha de "
            "32 bytes (256 bits). Implementado em wt_icache.sv. Privado por tile, "
            "sem protocolo de coerência entre tiles (instrução é read-only)."
        ),
        para_que_serve=(
            "Reduz o número de acessos à SRAM durante o fetch de instruções. "
            "Após o primeiro miss (cold start), as instruções são servidas "
            "localmente em 1 ciclo (hit). Na simulação, os 4 blocos de 64 bytes "
            "cobrindo os 256 bytes de código foram todos carregados em ≤14 misses."
        ),
        problema_resolve=(
            "Sem cache, cada instrução exigiria um round-trip de ~30 ciclos até "
            "a SRAM, limitando o IPC a 1/30. Com cache e código sequencial "
            "(hit rate ~100% após warm-up), o pipeline sustenta commits a ~1 "
            "instrução/ciclo. O custo de miss inicial é amortizado pelo reúso."
        )
    )

    sec(doc, "4.2  L1 DCache e store_buffer — Cache de Dados")
    card(doc,
        o_que_e=(
            "Cache de dados write-through de 16 KB, 4-way, com controlador "
            "wt_dcache_ctrl.sv. Opera em conjunto com o store_buffer (escrita) "
            "e load_unit.sv (leitura). No xsim 2025.1, o caminho de leitura "
            "(LW/LD via load_unit.sv) falha com FATAL_ERROR por bug de "
            "packed-struct no kernel do simulador."
        ),
        para_que_serve=(
            "Armazena dados lidos e escritos pelo programa. Escritas (SW) "
            "percorrem store_buffer → DCache → L1.5 → NoC → SRAM. Leituras (LW) "
            "consultam primeiro o DCache e, em caso de miss, buscam via L1.5. "
            "O write-through garante consistência imediata com a SRAM sem "
            "necessidade de write-back explícito."
        ),
        problema_resolve=(
            "Isola o pipeline de processador da latência de 30+ ciclos da SRAM "
            "para operações de dados, da mesma forma que o ICache faz para "
            "instruções. No contexto deste projeto, o caminho de leitura está "
            "temporariamente indisponível no simulador; os operandos são "
            "fornecidos via ADDI (imediato) como workaround documentado."
        )
    )

    sec(doc, "4.3  L1.5 TRI — Camada Intermediária")
    card(doc,
        o_que_e=(
            "Cache de nível 1.5 de 8 KB, 4-way, protocolo MESI, implementado "
            "como TRI (Transactional Register Interface). Fica entre o L1 e a "
            "NoC P-Mesh. O adaptador L15ADAP converte requisições do L1 ICache "
            "(type=16 para IFILL) e do DCache para o formato de flit da NoC."
        ),
        para_que_serve=(
            "Serve como buffer de coerência e ponto de filtro entre o tile e "
            "a rede de interconexão. Hits no L1.5 evitam tráfego na NoC. "
            "Gerenencia invalidações MESI recebidas de outros tiles via NoC3, "
            "garantindo que leituras de um tile vejam escritas de outro."
        ),
        problema_resolve=(
            "Sem o L1.5, cada miss do L1 geraria diretamente tráfego na NoC "
            "e na SRAM, aumentando a contenção. O L1.5 agrupa requisições "
            "pendentes (MSHR) e responde a hits sem ir à SRAM, reduzindo a "
            "latência média e o tráfego inter-tile."
        )
    )

    # --- 5. NoC P-Mesh ---
    ch(doc, "5  NoC P-Mesh: a Rede de Interconexão")
    prose(doc,
        "A NoC P-Mesh (Packet-switched Mesh) é a espinha dorsal do OpenPiton. "
        "Ela conecta todos os tiles e o bridge de memória em uma topologia de "
        "malha, com três redes independentes para evitar deadlock: NoC1 para "
        "requisições, NoC2 para respostas e NoC3 para write-back/invalidações. "
        "Cada rede é roteada de forma determinística (dimension-order routing), "
        "sem necessidade de tabelas de roteamento dinâmicas.")

    card(doc,
        o_que_e=(
            "Interconexão packet-switched com topologia de malha 2D. Três redes "
            "independentes de 64 bits por flit: NoC1 (requisições: load/store/fill), "
            "NoC2 (respostas: dados, ACKs) e NoC3 (write-back e invalidações MESI). "
            "Arbitragem FIFO por porta, roteamento dimension-order (X primeiro, Y depois)."
        ),
        para_que_serve=(
            "Transporta todos os pacotes entre tiles e a memória: pedidos de fill "
            "de instrução (IFILL type=16), confirmações de store, respostas de dados "
            "e mensagens de coerência. Na configuração 2×1, os dois tiles compartilham "
            "as três redes, e o noc_axi4_bridge converte os flits P-Mesh para "
            "transações AXI4 na interface da SRAM."
        ),
        problema_resolve=(
            "Barramentos compartilhados (como AXI4 multi-master) criam gargalos "
            "severos com múltiplos masters simultâneos. A NoC distribui o tráfego "
            "pela malha, permitindo comunicação simultânea entre pares de nós "
            "não conflitantes. A separação em 3 redes elimina deadlocks clássicos "
            "de protocolo de coerência (ciclo de dependência req → resp → wb)."
        )
    )

    # --- 6. noc_axi4_bridge ---
    ch(doc, "6  noc_axi4_bridge: a Ponte de Memória")
    card(doc,
        o_que_e=(
            "Módulo RTL que traduz flits P-Mesh (NoC1/NoC2) em transações "
            "AXI4 (AR/AW/W/R/B channels) e vice-versa. Recebe requisições "
            "dos tiles via NoC1, emite beats AXI4 para a SRAM e devolve "
            "as respostas pelos flits NoC2."
        ),
        para_que_serve=(
            "Permite que a SRAM (interface AXI4 padrão de mercado) seja "
            "conectada ao ecossistema OpenPiton sem modificação. Toda a "
            "complexidade do protocolo P-Mesh fica contida na ponte; "
            "a SRAM enxerga apenas transações AXI4 convencionais "
            "(AR len=0, 512 bits por beat)."
        ),
        problema_resolve=(
            "Sem a ponte, seria necessário implementar uma SRAM com interface "
            "P-Mesh nativa ou criar um protocolo proprietário. A ponte reutiliza "
            "modelos de SRAM AXI4 existentes (inclusive os modelos comportamentais "
            "do Vivado), reduz a complexidade de verificação e facilita a "
            "substituição futura por DDR4 ou HBM com interface AXI4."
        )
    )

    # --- 7. AXI4 SRAM ---
    ch(doc, "7  AXI4 SRAM: a Memória Principal")
    card(doc,
        o_que_e=(
            "Modelo comportamental de SRAM com interface AXI4 Full, capacidade "
            "de 256 KB e largura de dados de 512 bits. Inicializada via "
            "$readmemh com o arquivo boot_rw.hex. Compartilhada entre os "
            "dois tiles. Latência de ~13 ciclos (130 ns @ 100 MHz) por "
            "transação AXI4 de leitura."
        ),
        para_que_serve=(
            "Armazena o código do programa (instruções) e a área de dados "
            "(resultados SW de cada hart). No mapa de endereços: "
            "BASE=0x80000000, código em 0x000-0x0FF, dados Hart0 em "
            "0x1000-0x1010, dados Hart1 em 0x1020-0x1030, tohost_pass em "
            "0x8000FF50. Um único modelo de SRAM serve os dois tiles."
        ),
        problema_resolve=(
            "Em FPGA real, este bloco seria substituído por um controlador "
            "DDR4 ou por BRAMs com interface AXI4. O modelo comportamental "
            "simplifica a simulação: resposta determinística sem latência "
            "variável de refresh DDR. O mapa de endereços fixo em 0x80000000 "
            "reflete a convenção do bootloader CVA6 para execução baremetal."
        )
    )

    # --------------------------------------------------------
    # PARTE II — UVM
    # --------------------------------------------------------
    divider(doc, "PARTE II — AMBIENTE DE VERIFICAÇÃO UVM", bg="1A4A2E")

    # --- 8. UVM ---
    ch(doc, "8  UVM: Universal Verification Methodology")
    prose(doc,
        "UVM (Universal Verification Methodology) é um padrão IEEE 1800.2 "
        "para construção de ambientes de verificação SystemVerilog reusáveis "
        "e estruturados. Diferente de um testbench ad-hoc, o UVM define "
        "classes base, protocolos de comunicação entre componentes (TLM), "
        "mecanismos de configuração e hierarquia de objetos que permitem "
        "reusar agentes entre projetos com mínima adaptação.")

    card(doc,
        o_que_e=(
            "Framework de verificação SystemVerilog baseado em classes OOP. "
            "Define a hierarquia: Test → Environment → Agent (Driver + Monitor + "
            "Sequencer) → Scoreboard. Comunicação entre componentes via "
            "TLM (Transaction Level Modeling) FIFOs e análise ports."
        ),
        para_que_serve=(
            "Estrutura a simulação em camadas bem definidas: o Test configura o "
            "cenário, o Environment instancia agentes, os Drivers estimulam o DUT, "
            "os Monitors observam passivamente sinais, e o Scoreboard verifica "
            "resultados. Cada camada é independente — trocar o Test não afeta "
            "os Monitors, por exemplo."
        ),
        problema_resolve=(
            "Testbenches monolíticos crescem sem estrutura e tornam-se "
            "impossíveis de manter. O UVM impõe separação de responsabilidades: "
            "um agente AXI4 escrito uma vez pode ser reutilizado em qualquer "
            "DUT com barramento AXI4. No projeto, o mesmo ambiente base valida "
            "tanto o teste matemático quanto o teste de escrita, mudando apenas "
            "o arquivo .hex."
        )
    )

    # --- 9. Componentes UVM ---
    ch(doc, "9  Componentes do Ambiente")

    sec(doc, "9.1  uvmt_opc_asm_test_c — Test")
    card(doc,
        o_que_e=(
            "Classe de teste no topo da hierarquia UVM. Herda de uvm_test. "
            "Responsável por selecionar a sequência asm_seq, configurar o "
            "ambiente (timeout=5000000 ps, finish_mask=0x7FFF) e iniciar a "
            "fase run_phase via start() da sequência."
        ),
        para_que_serve=(
            "Ponto de entrada da simulação. O nome do test é passado via "
            "+UVM_TESTNAME=uvmt_opc_asm_test_c na linha de comando do xsim. "
            "Carrega o binário via UVM_RUN_BINARY_OVERRIDE e delega a execução "
            "ao sequenciador do agente clk_rst."
        ),
        problema_resolve=(
            "Centraliza a configuração do cenário em um único lugar. Para rodar "
            "um teste diferente (ex: apenas Hart 0, ou com timeout menor), "
            "basta criar um novo Test derivado — sem tocar nos agentes ou DUT wrap. "
            "O test também é o ponto onde a cobertura funcional seria configurada."
        )
    )

    sec(doc, "9.2  Agentes: clk_rst, noc, l15_tri, status")
    prose(doc,
        "Cada agente encapsula a interface com um protocolo ou sinal específico "
        "do DUT. Um agente UVM é composto por um Driver (ativo, estimula sinais), "
        "um Monitor (passivo, observa sinais) e um Sequencer (coordena sequências). "
        "Os agentes noc, l15_tri e status são apenas passivos (monitor-only).", indent=False)

    tbl2 = doc.add_table(rows=5, cols=3)
    tbl2.style = "Table Grid"
    for i, txt in enumerate(["Agente", "Função", "Sinal Monitorado"]):
        set_cell_bg(tbl2.rows[0].cells[i], "1F3864")
        p = tbl2.rows[0].cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER; no_sp(p)
        r = p.add_run(txt); r.bold=True
        r.font.color.rgb = RGBColor(255,255,255); r.font.size = Pt(9)
    agents = [
        ("clk_rst_agent",  "Gera clock 100 MHz e controla rst_n.\nDesasserta reset no ciclo 20 (t=200 ns).",
         "clk, rst_n"),
        ("noc_agent",      "Monitora flits da NoC1 (NOC1_FIRST).\nRegistra primeiro flit de cada pacote.",
         "noc1_valid, noc1_data"),
        ("l15_tri_agent",  "Monitora interface L1.5 TRI (L15ADAP).\nRegistra REQ, RTRN e IFILL_ACK.",
         "l15_req_*, l15_ack_*"),
        ("status_agent",   "Detecta good_trap e bad_trap.\nEmite 'HIT GOOD TRAP' e notifica scoreboard.",
         "good_trap, bad_trap"),
    ]
    bgs2 = ["EEF4FF","EEF4FF","EEF4FF","EEF4FF"]
    for i, (ag, fn, sig) in enumerate(agents):
        row = tbl2.rows[i+1]
        set_cell_bg(row.cells[0], bgs2[i])
        set_cell_bg(row.cells[1], bgs2[i])
        set_cell_bg(row.cells[2], bgs2[i])
        for j, txt in enumerate([ag, fn, sig]):
            p = row.cells[j].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT; no_sp(p, 3, 3)
            r = p.add_run(txt); r.font.size = Pt(9)
            if j == 0: r.bold = True
    set_col_width(tbl2, [3.5, 8.5, 4.5])
    doc.add_paragraph()

    sec(doc, "9.3  uvmt_opc_scoreboard — Scoreboard")
    card(doc,
        o_que_e=(
            "Componente de verificação que recebe notificações de GOOD_TRAP "
            "e BAD_TRAP do status_agent via analysis port TLM. Mantém um "
            "contador de tiles concluídos contra a máscara finish_mask=0x7FFF "
            "(bitmask dos tiles esperados)."
        ),
        para_que_serve=(
            "Determina o veredicto final da simulação. Quando "
            "Completados == Esperados (0x1 == 0x1 neste projeto), "
            "o scoreboard declara PASS e a simulação pode ser encerrada. "
            "Também detecta BAD_TRAP e declara FAIL imediatamente."
        ),
        problema_resolve=(
            "Sem scoreboard, o critério de sucesso seria hard-coded no DUT wrap "
            "via $finish após um número fixo de ciclos — frágil e não escalável. "
            "O scoreboard centraliza a lógica de veredicto e permite escalar "
            "para N tiles simplesmente ajustando finish_mask, sem tocar no RTL."
        )
    )

    # --- 10. DUT Wrap ---
    ch(doc, "10  uvmt_opc_dut_wrap: o DUT e seus Monitores")
    prose(doc,
        "O DUT wrap é o módulo SystemVerilog que instancia o chip OpenPiton "
        "e conecta suas interfaces aos virtual interfaces UVM. É nele que "
        "estão os monitores customizados adicionados a este projeto para "
        "observar o comportamento interno do SoC sem modificar o RTL "
        "sintetizável.")

    sec(doc, "10.1  H0_COMMIT e H1_COMMIT")
    card(doc,
        o_que_e=(
            "Blocos always @(posedge clk) que amostram os sinais "
            "commit_i[0].valid e commit_i[0].pc de cada CVA6 via "
            "hierarquia de caminhos hierárquicos (backtick paths). "
            "Exibem no log a linha '[t ns] H0_COMMIT pc=0x... @cyc=...' "
            "a cada instrução comprometida."
        ),
        para_que_serve=(
            "Produzem o rastreamento de execução instrução a instrução para "
            "ambos os harts. Permitem verificar manualmente (ou por script) "
            "se o fluxo de controle seguiu o caminho esperado: hart0_init → "
            "compute → store_h0 → verify_h0 → pass, e hart1_init → "
            "compute → store_h1 → verify_h1."
        ),
        problema_resolve=(
            "O xsim não tem suporte a waveform stepping conveniente para "
            "grandes simulações. Os logs H0/H1_COMMIT fornecem visibilidade "
            "de execução equivalente a um trace de simulador ISA (como Spike), "
            "permitindo correlacionar cada commit com a instrução assembly "
            "correspondente no build_rw_test.py."
        )
    )

    sec(doc, "10.2  SB0_STORE e SB1_STORE")
    card(doc,
        o_que_e=(
            "Monitores que observam store_buffer.commit_i e os campos "
            "speculative_queue_q[speculative_read_pointer_q].address e .data "
            "de cada tile via hierarchical references. Exibem "
            "'[t ns] SB0_STORE addr=... data=... @cyc=...' a cada store comprometido."
        ),
        para_que_serve=(
            "Verificam que os resultados aritméticos foram corretamente gravados "
            "na memória: Hart0 grava ADD=16, SUB=4, MUL=60, AND=2, OR=14 "
            "em 0x80001000-0x80001010; Hart1 grava ADD=12, SUB=6, MUL=27, "
            "AND=1, OR=11 em 0x80001020-0x80001030. "
            "Também detecta a escrita de GOOD TRAP em 0x8000FF50."
        ),
        problema_resolve=(
            "Como o stub xsim suprime data_req=0, os stores nunca chegam ao "
            "barramento AXI4 e não são visíveis como transações AW/W. "
            "O monitor de commit_i é o único meio de observar o resultado "
            "dos stores sem modificar o RTL sintetizável. Este bypass foi "
            "implementado especificamente para contornar a limitação do simulador "
            "enquanto a funcionalidade de D-cache é restaurada em ambiente FPGA."
        )
    )

    sec(doc, "10.3  AXI_AR monitor")
    card(doc,
        o_que_e=(
            "Monitor do canal AR (Address Read) do barramento AXI4 entre "
            "o noc_axi4_bridge e a SRAM. Detecta m_axi_arvalid & arready "
            "e classifica o beat como INST (addr < 0x80001000) ou DATA "
            "(addr >= 0x80001000). Exibe '[t ns] AXI_AR[N] INST/DATA addr=...'."
        ),
        para_que_serve=(
            "Rastreia os acessos de instrução à SRAM, permitindo calcular o "
            "número de misses de L1 ICache e a latência de cada fill. "
            "Na simulação foram 14 beats AR[0..13], todos INST, cobrindo "
            "4 blocos de 64 bytes (0x80000000, 0x80000040, 0x80000080, 0x800000C0)."
        ),
        problema_resolve=(
            "Sem este monitor, os acessos AXI4 só seriam visíveis via waveform "
            "VCD/WDB (centenas de MB para esta simulação). O log textual permite "
            "análise rápida de padrões de acesso à memória, identificação de "
            "acessos redundantes (mesmo bloco requisitado duas vezes por tiles "
            "diferentes) e cálculo de métricas de desempenho de cache."
        )
    )

    sec(doc, "10.4  STORE_COMMIT e Detecção de GOOD TRAP")
    card(doc,
        o_que_e=(
            "Monitor específico para o endereço tohost_pass (0x8000FF50). "
            "Quando SB0_STORE detecta addr==0x8000FF50, seta o sinal "
            "good_trap na interface de status. Um contador de drenagem de "
            "25 ciclos é iniciado antes do $finish, permitindo capturar "
            "commits adicionais de Hart1."
        ),
        para_que_serve=(
            "Encerra a simulação de forma determinística quando o programa "
            "sinaliza conclusão. Substitui o mecanismo padrão AXI4-AW "
            "(que não funciona no xsim por causa do stub). Também detecta "
            "BAD TRAP (addr==0x8000FF58) e encerra com veredicto de falha."
        ),
        problema_resolve=(
            "Uma simulação sem critério de parada precisa de timeout fixo, "
            "que ou é muito curto (termina antes do GOOD TRAP) ou muito "
            "longo (desperdiça tempo de simulação). O mecanismo de "
            "store_buffer.commit_i + drain de 25 ciclos equilibra os dois "
            "requisitos: termina rápido após PASS e ainda captura evidências "
            "do Hart1 em execução."
        )
    )

    # --- 11. Programa baremetal ---
    ch(doc, "11  Programa Baremetal: boot_rw.hex")
    card(doc,
        o_que_e=(
            "Binário RISC-V baremetal gerado pelo montador Python build_rw_test.py, "
            "sem toolchain GCC. Cada instrução é codificada diretamente nos "
            "formatos R/I/S/B/U/J do ISA. Contém 1040 words de 32 bits "
            "(4160 bytes), carregado via $readmemh na SRAM."
        ),
        para_que_serve=(
            "Executa o teste de escrita dual-core: identifica o hart via CSR "
            "mhartid, carrega operandos por ADDI, computa 5 operações aritméticas "
            "(ADD/SUB/MUL/AND/OR), grava via SW em regiões exclusivas da SRAM, "
            "verifica os resultados e sinaliza PASS (escrita em 0x8000FF50) "
            "ou FAIL (escrita em 0x8000FF58)."
        ),
        problema_resolve=(
            "Compiladores GCC/LLVM para RISC-V requerem toolchain completa "
            "(300+ MB), linker scripts, bibliotecas de startup e são difíceis "
            "de auditar para testes simples. O montador Python produz exatamente "
            "as instruções desejadas em 250 linhas de código auditável, "
            "facilita ajuste de imediatos e endereços, e pode ser integrado "
            "a qualquer pipeline CI sem dependências externas."
        )
    )

    # --------------------------------------------------------
    # PARTE III — LIMITACOES E PROXIMOS PASSOS
    # --------------------------------------------------------
    divider(doc, "PARTE III — LIMITAÇÕES CONHECIDAS E PRÓXIMOS PASSOS",
            bg="7B241C")

    ch(doc, "12  Limitações do Simulador xsim 2025.1")
    prose(doc,
        "Duas limitações do kernel do xsim 2025.1 afetam diretamente a "
        "simulação deste projeto. Ambas têm origem no mesmo bug de avaliação "
        "de always_comb com arrays de structs packed de 131 bits, mas se "
        "manifestam em módulos diferentes.")

    tbl3 = doc.add_table(rows=3, cols=3)
    tbl3.style = "Table Grid"
    for i, txt in enumerate(["Limitação", "Módulo afetado", "Workaround adotado"]):
        set_cell_bg(tbl3.rows[0].cells[i], "7B241C")
        p = tbl3.rows[0].cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER; no_sp(p)
        r = p.add_run(txt); r.bold=True
        r.font.color.rgb = RGBColor(255,255,255); r.font.size = Pt(9)
    lims = [
        ("Writes não chegam ao AXI4\n(data_req forçado a 0)",
         "store_buffer.sv\n('ifndef XSIM stub)",
         "Monitor commit_i + speculative_queue_q observado diretamente no RTL"),
        ("LW/LD causam FATAL_ERROR\n(D-cache crash em load_unit.sv)",
         "wt_dcache_ctrl.sv:95\nNetRegassign345_31703",
         "Operandos carregados por ADDI (imediato); sem instruções de carga"),
    ]
    for i, (lim, mod, wk) in enumerate(lims):
        row = tbl3.rows[i+1]
        bg = "FEF9E7"
        set_cell_bg(row.cells[0], bg)
        set_cell_bg(row.cells[1], bg)
        set_cell_bg(row.cells[2], "EDFAF1")
        for j, txt in enumerate([lim, mod, wk]):
            p = row.cells[j].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT; no_sp(p, 3, 3)
            r = p.add_run(txt); r.font.size = Pt(9)
    set_col_width(tbl3, [5.5, 4.5, 6.5])
    doc.add_paragraph()

    ch(doc, "13  Próximos Passos")
    prose(doc,
        "Os próximos desenvolvimentos naturais para este projeto são: "
        "(1) Migração para Vivado 2024 ou implementação FPGA, onde as limitações "
        "do xsim desaparecem e o caminho completo de D-cache pode ser exercitado; "
        "(2) Adição de instruções LW para leitura dos resultados gravados na SRAM "
        "e verificação cross-hart (Hart0 lê o que Hart1 escreveu); "
        "(3) Testes de sincronização inter-core usando instruções atômicas (A-ext: "
        "LR/SC, AMOSWAP), exercitando o protocolo MESI do L1.5; "
        "(4) Cobertura funcional UVM formal para garantir que todos os caminhos "
        "da hierarquia de cache sejam exercitados.")

    # --------------------------------------------------------
    # CONCLUSAO
    # --------------------------------------------------------
    ch(doc, "14  Conclusão")
    prose(doc,
        "Este projeto demonstra uma plataforma completa e auditável de "
        "verificação de SoC multi-core: do ISA RISC-V ao RTL do processador, "
        "da hierarquia de cache à rede de interconexão, do binário baremetal "
        "ao ambiente UVM. Cada componente foi escolhido por ser de código "
        "aberto, rastreável e educacionalmente rico.")
    prose(doc,
        "O teste de escrita dual-core validou com sucesso o caminho SW → "
        "store_buffer.commit_i em ambos os núcleos CVA6, com resultados "
        "aritméticos corretos (incluindo MUL da extensão M) e detecção de "
        "GOOD TRAP no ciclo 397. As limitações do xsim foram documentadas "
        "e contornadas de forma não-intrusiva — os workarounds não modificam "
        "o RTL sintetizável e serão transparentemente removidos quando a "
        "simulação migrar para FPGA ou para versão corrigida do simulador.")

    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, "arquitetura_explicativa.docx")
    doc.save(path)
    print(f"Gerado: {path}")


if __name__ == "__main__":
    build()
