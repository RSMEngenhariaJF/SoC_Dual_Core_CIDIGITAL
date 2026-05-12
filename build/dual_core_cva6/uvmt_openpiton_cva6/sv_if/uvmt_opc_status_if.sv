// ============================================================================
// uvmt_opc_status_if.sv
// Interface de status do teste: detecta GOOD_TRAP / BAD_TRAP e captura
// saida da UART virtual (fake_uart do OpenPiton).
//
// No OpenPiton+Ariane, pass/fail e sinalizado por:
//   - Escrita em endereco MMIO 0x0000_0000_FF50 (pass=1 / fail=codigo)
//   - UART virtual em 0xFFF0_1100_00 para printf/putchar
//
// Esta interface e conectada por binding ou por drivers no DUT wrapper.
// ============================================================================
`ifndef __UVMT_OPC_STATUS_IF_SV__
`define __UVMT_OPC_STATUS_IF_SV__

interface uvmt_opc_status_if #(
    parameter int unsigned NUM_TILES = 1
)(
    input logic clk,
    input logic rst_n
);

    // ---- Sinais de trap por tile --------------------------------------------
    logic [NUM_TILES-1:0] good_trap;     // tile completou com sucesso
    logic [NUM_TILES-1:0] bad_trap;      // tile encontrou erro
    logic [63:0]          bad_trap_code [NUM_TILES]; // codigo do erro (reg a0)

    // ---- UART virtual (fake_uart do OpenPiton) ------------------------------
    logic       uart_valid;   // byte disponivel
    logic [7:0] uart_data;    // byte ASCII

    // ---- Contador de ciclos ------------------------------------------------
    longint unsigned cycle_count;

    initial cycle_count = 0;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycle_count <= 0;
        else        cycle_count <= cycle_count + 1;
    end

    // Clocking block para monitor
    clocking mon_cb @(posedge clk);
        input good_trap;
        input bad_trap;
        input bad_trap_code;
        input uart_valid;
        input uart_data;
        input cycle_count;
    endclocking

    modport mon_mp (clocking mon_cb, input clk, rst_n);

    // ---- Assercoes ---------------------------------------------------------

    // good_trap e bad_trap nao podem ser simultaneos no mesmo tile
    // (verificado para cada tile individualmente)
    genvar gi;
    generate
        for (gi = 0; gi < NUM_TILES; gi++) begin : gen_trap_chk
            AST_NO_DUAL_TRAP : assert property (
                @(posedge clk) disable iff (!rst_n)
                !(good_trap[gi] && bad_trap[gi])
            );
        end
    endgenerate

endinterface : uvmt_opc_status_if

`endif // __UVMT_OPC_STATUS_IF_SV__
