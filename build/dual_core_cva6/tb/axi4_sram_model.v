// AXI4 Slave SRAM Behavioral Model
//
// Parâmetros:
//   BASE_ADDR : endereço físico base (padrão: 0x80000000 — DRAMBase OpenPiton)
//   MEM_WORDS : número de palavras de 32 bits (padrão: 65536 = 256 KB)
//
// Protocolo: AXI4 full (suporta ARLEN ≥ 0 para bursts de 512 bits por beat).
// Inicialização: $readmemh("boot.hex", mem) carrega o programa de boot.
//
// Cada beat AXI4 transfere AXI4_DATA_WIDTH = 512 bits = 64 bytes = 16 words.
// Para reads: compõe 512 bits a partir de 16 palavras consecutivas do mem[].
// Para writes: decompõe 512 bits em 16 palavras usando wstrb por byte.

`include "noc_axi4_bridge_define.vh"

module axi4_sram_model #(
    parameter BASE_ADDR = 64'h8000_0000,
    parameter MEM_WORDS = 65536         // 256 KB em palavras de 32 bits
) (
    input  wire                          clk,
    input  wire                          rst_n,

    // --- Write Address ---
    input  wire [`AXI4_ID_WIDTH-1:0]     s_axi_awid,
    input  wire [`AXI4_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [`AXI4_LEN_WIDTH-1:0]    s_axi_awlen,
    input  wire [`AXI4_SIZE_WIDTH-1:0]   s_axi_awsize,
    input  wire [`AXI4_BURST_WIDTH-1:0]  s_axi_awburst,
    input  wire                          s_axi_awvalid,
    output reg                           s_axi_awready,

    // --- Write Data ---
    input  wire [`AXI4_DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [`AXI4_STRB_WIDTH-1:0]   s_axi_wstrb,
    input  wire                          s_axi_wlast,
    input  wire                          s_axi_wvalid,
    output reg                           s_axi_wready,

    // --- Write Response ---
    output reg  [`AXI4_ID_WIDTH-1:0]     s_axi_bid,
    output wire [1:0]                    s_axi_bresp,
    output reg                           s_axi_bvalid,
    input  wire                          s_axi_bready,

    // --- Read Address ---
    input  wire [`AXI4_ID_WIDTH-1:0]     s_axi_arid,
    input  wire [`AXI4_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [`AXI4_LEN_WIDTH-1:0]    s_axi_arlen,
    input  wire [`AXI4_SIZE_WIDTH-1:0]   s_axi_arsize,
    input  wire [`AXI4_BURST_WIDTH-1:0]  s_axi_arburst,
    input  wire                          s_axi_arvalid,
    output reg                           s_axi_arready,

    // --- Read Data ---
    output reg  [`AXI4_ID_WIDTH-1:0]     s_axi_rid,
    output reg  [`AXI4_DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]                    s_axi_rresp,
    output reg                           s_axi_rlast,
    output reg                           s_axi_rvalid,
    input  wire                          s_axi_rready
);

// Respostas sempre OKAY
assign s_axi_bresp = 2'b00;
assign s_axi_rresp = 2'b00;

// ------------------------------------------------------------
// Memória (palavras de 32 bits, endereçamento por word index)
// ------------------------------------------------------------
reg [31:0] mem [0:MEM_WORDS-1];

// Inicialização
integer i;
initial begin
    for (i = 0; i < MEM_WORDS; i = i + 1)
        mem[i] = 32'h0000_006F; // jal x0, 0  (loop infinito seguro)
    $readmemh("boot.hex", mem);
end

// ------------------------------------------------------------
// Funções auxiliares
// ------------------------------------------------------------

// Converte endereço AXI4 em índice de word (32 bits) no array
function automatic integer addr_to_widx;
    input [`AXI4_ADDR_WIDTH-1:0] addr;
    begin
        addr_to_widx = (addr - BASE_ADDR) >> 2;
    end
endfunction

// Compõe uma linha de cache de 512 bits a partir do índice de word base
// beat_addr: endereço byte do beat atual
function automatic [`AXI4_DATA_WIDTH-1:0] read_line;
    input [`AXI4_ADDR_WIDTH-1:0] beat_addr;
    integer base_idx, j;
    reg [`AXI4_DATA_WIDTH-1:0] line;
    begin
        base_idx = addr_to_widx(beat_addr & ~64'd63); // alinha a 64 bytes
        line = {`AXI4_DATA_WIDTH{1'b0}};
        for (j = 0; j < 16; j = j + 1)
            line[j*32 +: 32] = mem[base_idx + j];
        read_line = line;
    end
endfunction

// Escreve 512 bits em 16 words com byte-enable
task write_line;
    input [`AXI4_ADDR_WIDTH-1:0] beat_addr;
    input [`AXI4_DATA_WIDTH-1:0] wdata;
    input [`AXI4_STRB_WIDTH-1:0] wstrb;
    integer base_idx, j, b;
    begin
        base_idx = addr_to_widx(beat_addr & ~64'd63);
        for (j = 0; j < 16; j = j + 1) begin
            for (b = 0; b < 4; b = b + 1) begin
                if (wstrb[j*4 + b])
                    mem[base_idx + j][b*8 +: 8] = wdata[(j*32 + b*8) +: 8];
            end
        end
    end
endtask

// ------------------------------------------------------------
// Máquina de estados — READ
// ------------------------------------------------------------
localparam RD_IDLE = 2'd0, RD_DATA = 2'd1;
reg [1:0] rd_state;

reg [`AXI4_ID_WIDTH-1:0]    rd_id;
reg [`AXI4_ADDR_WIDTH-1:0]  rd_addr;
reg [`AXI4_LEN_WIDTH-1:0]   rd_len;
reg [`AXI4_LEN_WIDTH-1:0]   rd_beat;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_state    <= RD_IDLE;
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b0;
        s_axi_rlast   <= 1'b0;
        s_axi_rid     <= 0;
        s_axi_rdata   <= 0;
        rd_beat       <= 0;
    end else begin
        case (rd_state)
            RD_IDLE: begin
                s_axi_rvalid  <= 1'b0;
                s_axi_rlast   <= 1'b0;
                if (s_axi_arvalid) begin
                    s_axi_arready <= 1'b1;
                    rd_id    <= s_axi_arid;
                    rd_addr  <= s_axi_araddr;
                    rd_len   <= s_axi_arlen;
                    rd_beat  <= 0;
                    rd_state <= RD_DATA;
                end
            end

            RD_DATA: begin
                s_axi_arready <= 1'b0;
                s_axi_rid     <= rd_id;
                s_axi_rdata   <= read_line(rd_addr + rd_beat * 64);
                s_axi_rlast   <= (rd_beat == rd_len);
                s_axi_rvalid  <= 1'b1;

                if (s_axi_rready && s_axi_rvalid) begin
                    if (rd_beat == rd_len) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                        rd_state     <= RD_IDLE;
                    end else begin
                        rd_beat <= rd_beat + 1;
                    end
                end
            end
        endcase
    end
end

// ------------------------------------------------------------
// Máquina de estados — WRITE
// ------------------------------------------------------------
localparam WR_IDLE = 2'd0, WR_DATA = 2'd1, WR_RESP = 2'd2;
reg [1:0] wr_state;

reg [`AXI4_ID_WIDTH-1:0]    wr_id;
reg [`AXI4_ADDR_WIDTH-1:0]  wr_addr;
reg [`AXI4_LEN_WIDTH-1:0]   wr_len;
reg [`AXI4_LEN_WIDTH-1:0]   wr_beat;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_state      <= WR_IDLE;
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        s_axi_bid     <= 0;
        wr_beat       <= 0;
    end else begin
        case (wr_state)
            WR_IDLE: begin
                s_axi_bvalid  <= 1'b0;
                if (s_axi_awvalid) begin
                    s_axi_awready <= 1'b1;
                    wr_id    <= s_axi_awid;
                    wr_addr  <= s_axi_awaddr;
                    wr_len   <= s_axi_awlen;
                    wr_beat  <= 0;
                    wr_state <= WR_DATA;
                end
            end

            WR_DATA: begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b1;
                if (s_axi_wvalid && s_axi_wready) begin
                    write_line(wr_addr + wr_beat * 64, s_axi_wdata, s_axi_wstrb);
                    if (s_axi_wlast || wr_beat == wr_len) begin
                        s_axi_wready <= 1'b0;
                        wr_state     <= WR_RESP;
                    end else begin
                        wr_beat <= wr_beat + 1;
                    end
                end
            end

            WR_RESP: begin
                s_axi_bid    <= wr_id;
                s_axi_bvalid <= 1'b1;
                if (s_axi_bready && s_axi_bvalid) begin
                    s_axi_bvalid <= 1'b0;
                    wr_state     <= WR_IDLE;
                end
            end
        endcase
    end
end

endmodule
