// ============================================================================
// uvmt_opc_clk_rst_drv.sv
// Gera clock continuo e sequencia de reset.
// ============================================================================
`ifndef __UVMT_OPC_CLK_RST_DRV_SV__
`define __UVMT_OPC_CLK_RST_DRV_SV__

class uvmt_opc_clk_rst_drv_c extends uvm_driver #(uvmt_opc_clk_rst_seq_item_c);

    `uvm_component_utils(uvmt_opc_clk_rst_drv_c)

    virtual uvmt_opc_clk_rst_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual uvmt_opc_clk_rst_if)::get(
                this, "", "clk_rst_vif", vif))
            `uvm_fatal("OPC_CLK_DRV", "clk_rst_vif nao encontrado no config_db")
    endfunction

    task run_phase(uvm_phase phase);
        uvmt_opc_clk_rst_seq_item_c req;
        int unsigned half_period_ps;

        // Estado inicial seguro
        vif.clk   = 1'b0;
        vif.rst_n = 1'b0;

        // Recebe item de configuracao (periodo + ciclos de reset)
        seq_item_port.get_next_item(req);
        half_period_ps = req.clk_period_ps / 2;

        `uvm_info("OPC_CLK_DRV",
            $sformatf("Iniciando clock: periodo=%0d ps, reset=%0d ciclos",
                req.clk_period_ps, req.rst_cycles),
            UVM_LOW)

        fork
            // Thread A: gera clock indefinidamente
            forever begin
                #(half_period_ps * 1ps);
                vif.clk = ~vif.clk;
            end

            // Thread B: sequencia de reset
            begin
                // Aguarda N ciclos com rst_n=0
                repeat (req.rst_cycles) @(posedge vif.clk);
                @(negedge vif.clk);
                vif.rst_n = 1'b1;
                `uvm_info("OPC_CLK_DRV",
                    $sformatf("rst_n desassertado no ciclo %0d", req.rst_cycles),
                    UVM_LOW)
            end
        join_none

        seq_item_port.item_done();

        // Driver nao termina - clock roda ate o fim da simulacao
        wait fork;
    endtask

endclass : uvmt_opc_clk_rst_drv_c

`endif // __UVMT_OPC_CLK_RST_DRV_SV__
