// ACE Slave Agent (Cache Snoop Responder)
// Models slave side of ACE (snoop requests and responses)

class ace_slave_sequence_item extends uvm_sequence_item;
    
    `uvm_object_utils(ace_slave_sequence_item)
    
    typedef enum {SNOOP_REQ, SNOOP_RESP} tx_type_e;
    
    rand logic [31:0]           snoop_address;
    rand logic [3:0]            snoop_cmd;
    rand logic [1:0]            snoop_domain;
    rand logic [2:0]            snoop_resp;
    rand logic [63:0]           snoop_data;
    
    tx_type_e                   tx_type;
    
    function new(string name = "ace_slave_sequence_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf(
            "SNOOP: cmd=0x%X addr=0x%08X resp=0x%X data=0x%016X",
            snoop_cmd, snoop_address, snoop_resp, snoop_data
        );
    endfunction

endclass

class ace_slave_driver extends uvm_driver #(ace_slave_sequence_item);
    
    `uvm_component_utils(ace_slave_driver)
    
    virtual ace_bus vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ace_bus)::get(this, "", "ace_vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction
    
    task run_phase(uvm_run_phase phase);
        ace_slave_sequence_item req, rsp;
        
        forever begin
            // Listen for snoop requests from CCU
            wait(vif.acvalid);
            
            // Send snoop response
            @(posedge vif.clk);
            vif.crvalid <= 1'b1;
            vif.crresp <= 3'b000;  // Default response
            
            wait(vif.crready);
            @(posedge vif.clk);
            vif.crvalid <= 1'b0;
        end
    endtask

endclass

class ace_slave_monitor extends uvm_monitor;
    
    `uvm_component_utils(ace_slave_monitor)
    
    uvm_analysis_port #(ace_slave_sequence_item) ap;
    virtual ace_bus vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ace_bus)::get(this, "", "ace_vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction
    
    task run_phase(uvm_run_phase phase);
        forever begin
            ace_slave_sequence_item item;
            
            // Monitor snoop requests (AC channel)
            wait(vif.acvalid);
            item = ace_slave_sequence_item::type_id::create("item");
            
            item.tx_type = SNOOP_REQ;
            item.snoop_address = vif.acaddr;
            item.snoop_cmd = vif.acsnoop;
            item.snoop_domain = vif.acdomain;
            
            ap.write(item);
            @(posedge vif.clk);
            
            // Monitor snoop responses (CR channel)
            wait(vif.crvalid);
            item = ace_slave_sequence_item::type_id::create("item");
            
            item.tx_type = SNOOP_RESP;
            item.snoop_resp = vif.crresp;
            
            ap.write(item);
            @(posedge vif.clk);
        end
    endtask

endclass

class ace_slave_agent extends uvm_agent;
    
    `uvm_component_utils(ace_slave_agent)
    
    uvm_sequencer #(ace_slave_sequence_item) sequencer;
    ace_slave_driver driver;
    ace_slave_monitor monitor;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        
        sequencer = uvm_sequencer #(ace_slave_sequence_item)::type_id::create("sequencer", this);
        driver = ace_slave_driver::type_id::create("driver", this);
        monitor = ace_slave_monitor::type_id::create("monitor", this);
    endfunction
    
    function void connect_phase(uvm_connect_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
