// ============================================================================
// uvmt_opc_cfg.sv  -  Objeto de configuracao do ambiente
// ============================================================================
`ifndef __UVMT_OPC_CFG_SV__
`define __UVMT_OPC_CFG_SV__

class uvmt_opc_cfg_c extends uvm_object;

    `uvm_object_utils_begin(uvmt_opc_cfg_c)
        `uvm_field_int(num_x_tiles,     UVM_ALL_ON)
        `uvm_field_int(num_y_tiles,     UVM_ALL_ON)
        `uvm_field_int(clk_period_ps,   UVM_ALL_ON)
        `uvm_field_int(rst_cycles,      UVM_ALL_ON)
        `uvm_field_int(timeout_cycles,  UVM_ALL_ON)
        `uvm_field_string(test_binary,  UVM_ALL_ON)
        `uvm_field_int(finish_mask,     UVM_ALL_ON)
        `uvm_field_int(enable_coh_check,UVM_ALL_ON)
        `uvm_field_int(enable_coverage, UVM_ALL_ON)
    `uvm_object_utils_end

    // ---- Topologia ----------------------------------------------------------
    // Valores default: single-tile (sem necessidade de constraint_mode no XSim)
    rand int unsigned num_x_tiles = 1;
    rand int unsigned num_y_tiles = 1;

    // ---- Temporizacao -------------------------------------------------------
    int unsigned clk_period_ps = 10_000;  // 10 ns -> 100 MHz
    int unsigned rst_cycles    = 20;
    int unsigned timeout_cycles= 5_000_000;

    // ---- Teste --------------------------------------------------------------
    // Caminho do binario compilado (.vmh ou .hex)
    string test_binary = "";

    // Mascara de tiles que devem atingir GOOD_TRAP para o teste passar.
    // Equivalente ao -finish_mask do sims do OpenPiton.
    // Bit N = 1 -> tile N deve completar. Default: so tile 0.
    longint unsigned finish_mask = 64'h1;

    // ---- Habilitadores ------------------------------------------------------
    bit enable_coh_check  = 1;  // verificar protocolo MESI
    bit enable_coverage   = 1;  // modelos de cobertura funcional

    // ---- Restricoes --------------------------------------------------------
    // Restricao de topologia: valores validos para X e Y tiles
    constraint c_tiles {
        num_x_tiles inside {[1:8]};
        num_y_tiles inside {[1:8]};
    }
    // NOTA: O default single-tile e definido diretamente em post_randomize()
    // Nao usar c_single_tile_default.constraint_mode() — nao suportado no XSim

    // ---- API ----------------------------------------------------------------
    function int unsigned num_tiles();
        return num_x_tiles * num_y_tiles;
    endfunction

    function new(string name = "uvmt_opc_cfg");
        super.new(name);
    endfunction

    function void post_randomize();
        // Garante que finish_mask reflete todos os tiles configurados
        if (num_tiles() > 1)
            finish_mask = (64'h1 << num_tiles()) - 1;
        else
            finish_mask = 64'h1;
        `uvm_info("OPC_CFG",
            $sformatf("[CFG] %0dx%0d tiles | timeout=%0d | finish_mask=0x%0h",
                num_x_tiles, num_y_tiles, timeout_cycles, finish_mask),
            UVM_LOW)
    endfunction

endclass : uvmt_opc_cfg_c

`endif // __UVMT_OPC_CFG_SV__
