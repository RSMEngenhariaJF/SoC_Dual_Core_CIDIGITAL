// ============================================================================
// uvmt_opc_clk_rst_if.sv
// Interface SystemVerilog de clock e reset.
// Clock e rst_n sao driven pelo uvmt_opc_clk_rst_drv_c.
// ============================================================================
`ifndef __UVMT_OPC_CLK_RST_IF_SV__
`define __UVMT_OPC_CLK_RST_IF_SV__

interface uvmt_opc_clk_rst_if;

    logic clk;
    logic rst_n;

    // Clocking block para monitor (leitura sincrona)
    clocking mon_cb @(posedge clk);
        input rst_n;
    endclocking

    // Modports
    modport drv_mp (output clk, output rst_n);
    modport mon_mp (input  clk, input  rst_n);

    // Task: aguarda N ciclos
    task automatic wait_clks(input int unsigned n);
        repeat (n) @(posedge clk);
    endtask

    // Task: aguarda rst_n subir
    task automatic wait_rst_done();
        @(posedge clk);
        while (!rst_n) @(posedge clk);
        @(posedge clk);
    endtask

endinterface : uvmt_opc_clk_rst_if

`endif // __UVMT_OPC_CLK_RST_IF_SV__
