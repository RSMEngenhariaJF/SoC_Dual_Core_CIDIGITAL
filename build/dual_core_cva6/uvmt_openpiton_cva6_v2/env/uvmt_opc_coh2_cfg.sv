// ============================================================================
// uvmt_opc_coh2_cfg.sv
// Configuração estendida para o testbench v2 de coerência.
//
// Herda todos os campos de uvmt_opc_cfg_c e adiciona:
//   - num_false_sharing_iters : iterações do padrão false-sharing
//   - enable_latency_tracking  : habilita medição de latência INVAL
//   - enable_sb_mon            : habilita agente store-buffer
//   - tohost_addr              : endereço tohost configurável (padrão 0x8000FF50)
//   - data_base_addr           : endereço base da região de dados (padrão 0x80002000)
// ============================================================================
`ifndef __UVMT_OPC_COH2_CFG_SV__
`define __UVMT_OPC_COH2_CFG_SV__

class uvmt_opc_coh2_cfg_c extends uvmt_opc_cfg_c;

    `uvm_object_utils_begin(uvmt_opc_coh2_cfg_c)
        `uvm_field_int(num_false_sharing_iters, UVM_ALL_ON)
        `uvm_field_int(enable_latency_tracking,  UVM_ALL_ON)
        `uvm_field_int(enable_sb_mon,            UVM_ALL_ON)
        `uvm_field_int(tohost_addr,              UVM_ALL_ON)
        `uvm_field_int(data_base_addr,           UVM_ALL_ON)
    `uvm_object_utils_end

    // Número de iterações do padrão de false sharing
    rand int unsigned  num_false_sharing_iters;

    // Habilita medição de latência INVAL_REQ → INVAL_ACK
    rand bit           enable_latency_tracking;

    // Habilita agente de monitoramento do store buffer
    rand bit           enable_sb_mon;

    // Endereço físico do tohost (bit[0]=1 → GOOD_TRAP)
    logic [39:0]       tohost_addr;

    // Endereço base da região de dados para testes de coerência
    logic [39:0]       data_base_addr;

    constraint c_v2_defaults {
        num_false_sharing_iters inside {[4:64]};
        enable_latency_tracking == 1;
        enable_sb_mon           == 1;
    }

    // Sobrescreve defaults da topologia para 2 tiles
    constraint c_topology_2t {
        num_x_tiles == 2;
        num_y_tiles == 1;
    }

    function new(string name = "uvmt_opc_coh2_cfg");
        super.new(name);
        tohost_addr    = 40'h8000_FF50;
        data_base_addr = 40'h8000_2000;
    endfunction

    // post_randomize: recalcula finish_mask após randomização
    function void post_randomize();
        super.post_randomize();
        finish_mask      = (1 << num_tiles()) - 1;
        enable_coh_check = 1;
    endfunction

endclass : uvmt_opc_coh2_cfg_c

`endif // __UVMT_OPC_COH2_CFG_SV__
