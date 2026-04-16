// ACE Monitor - Captures all ACE transactions

class ace_transaction extends uvm_sequence_item;
    
    `uvm_object_utils(ace_transaction)
    
    typedef enum {
        AW_PHASE,          // Write address
        W_PHASE,           // Write data
        B_PHASE,           // Write response
        AR_PHASE,          // Read address
        R_PHASE,           // Read data
        AC_PHASE,          // Snoop address
        CR_PHASE,          // Snoop response
        CD_PHASE           // Snoop data
    } phase_e;
    
    phase_e                 phase;
    logic [31:0]            address;
    logic [63:0]            data;
    logic [3:0]             snoop_cmd;
    logic [2:0]             snoop_resp;
    logic [1:0]             cache_state;
    real                    timestamp;
    int                     master_id;
    
    function new(string name = "ace_transaction");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf(
            "[%0fs] M%0d %s addr=0x%08X data=0x%016X",
            timestamp, master_id, phase.name(), address, data
        );
    endfunction

endclass

class ace_monitor extends uvm_monitor;
    
    `uvm_component_utils(ace_monitor)
    
    uvm_analysis_port #(ace_transaction) ap;
    virtual ace_bus vif;
    int master_id;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ace_bus)::get(this, "", "ace_vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
        if (!uvm_config_db #(int)::get(this, "", "master_id", master_id)) begin
            master_id = 0;
        end
    endfunction
    
    task run_phase(uvm_run_phase phase);
        fork
            monitor_aw();
            monitor_w();
            monitor_b();
            monitor_ar();
            monitor_r();
            monitor_ac();
            monitor_cr();
            monitor_cd();
        join_none
    endtask
    
    task monitor_aw();
        forever begin
            wait(vif.awvalid && vif.awready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = AW_PHASE;
            tx.address = vif.awaddr;
            tx.snoop_cmd = vif.awsnoop;
            tx.timestamp = $realtime;
            tx.master_id = master_id;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask
    
    task monitor_w();
        forever begin
            wait(vif.wvalid && vif.wready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = W_PHASE;
            tx.data = vif.wdata;
            tx.timestamp = $realtime;
            tx.master_id = master_id;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask
    
    task monitor_b();
        forever begin
            wait(vif.bvalid && vif.bready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = B_PHASE;
            tx.timestamp = $realtime;
            tx.master_id = master_id;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask
    
    task monitor_ar();
        forever begin
            wait(vif.arvalid && vif.arready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = AR_PHASE;
            tx.address = vif.araddr;
            tx.snoop_cmd = vif.arsnoop;
            tx.timestamp = $realtime;
            tx.master_id = master_id;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask
    
    task monitor_r();
        forever begin
            wait(vif.rvalid && vif.rready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = R_PHASE;
            tx.data = vif.rdata;
            tx.cache_state = vif.rcrresp;
            tx.timestamp = $realtime;
            tx.master_id = master_id;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask
    
    task monitor_ac();
        forever begin
            wait(vif.acvalid && vif.acready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = AC_PHASE;
            tx.address = vif.acaddr;
            tx.snoop_cmd = vif.acsnoop;
            tx.timestamp = $realtime;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask
    
    task monitor_cr();
        forever begin
            wait(vif.crvalid && vif.crready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = CR_PHASE;
            tx.snoop_resp = vif.crresp;
            tx.timestamp = $realtime;
            tx.master_id = master_id;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask
    
    task monitor_cd();
        forever begin
            wait(vif.cdvalid && vif.cdready);
            ace_transaction tx = ace_transaction::type_id::create("tx");
            tx.phase = CD_PHASE;
            tx.data = vif.cddata;
            tx.timestamp = $realtime;
            tx.master_id = master_id;
            ap.write(tx);
            @(posedge vif.clk);
        end
    endtask

endclass
