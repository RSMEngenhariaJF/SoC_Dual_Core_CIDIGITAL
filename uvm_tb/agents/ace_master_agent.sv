// ACE Master Agent
// Models CVA6 core behavior and ACE transactions

class ace_master_sequence_item extends uvm_sequence_item;
    
    `uvm_object_utils(ace_master_sequence_item)
    
    // Transaction type
    typedef enum {READ, WRITE, SNOOP_RESP} tx_type_e;
    
    // Address and data
    rand logic [31:0]           address;
    rand logic [63:0]           data;
    rand logic [7:0]            strb;
    rand tx_type_e              tx_type;
    
    // ACE specific
    rand logic [3:0]            snoop_type;
    rand logic [1:0]            domain;
    rand logic [1:0]            cache_state;
    
    // Status
    logic [1:0]                 response;
    logic                       accept;
    
    constraint addr_range   { address >= 0 && address < 32'h10000000; }
    constraint data_valid   { data != 64'hxxxxxxxx; }
    
    function new(string name = "ace_master_sequence_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf(
            "TX: type=%s addr=0x%08X data=0x%016X strb=0x%02X snoop=0x%X domain=%d cache=%d",
            tx_type.name(), address, data, strb, snoop_type, domain, cache_state
        );
    endfunction

endclass

class ace_master_driver extends uvm_driver #(ace_master_sequence_item);
    
    `uvm_component_utils(ace_master_driver)
    
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
        ace_master_sequence_item req, rsp;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            case (req.tx_type)
                READ: begin
                    drive_read(req);
                end
                WRITE: begin
                    drive_write(req);
                end
                SNOOP_RESP: begin
                    drive_snoop_response(req);
                end
            endcase
            
            rsp = ace_master_sequence_item::type_id::create("rsp");
            rsp.copy(req);
            rsp.response = 2'b00;  // OKAY
            rsp.accept = 1'b1;
            
            seq_item_port.item_done(rsp);
        end
    endtask
    
    task drive_read(ace_master_sequence_item req);
        @(posedge vif.clk);
        vif.arvalid <= 1'b1;
        vif.araddr <= req.address;
        vif.arsize <= 3'b011;  // 8 bytes
        vif.arlen <= 8'b0;
        vif.arsnoop <= req.snoop_type;
        vif.ardomain <= req.domain;
        vif.arcache <= 2'b00;
        
        wait(vif.arready);
        @(posedge vif.clk);
        vif.arvalid <= 1'b0;
        
        wait(vif.rvalid);
        @(posedge vif.clk);
        vif.rready <= 1'b1;
        @(posedge vif.clk);
        vif.rready <= 1'b0;
    endtask
    
    task drive_write(ace_master_sequence_item req);
        @(posedge vif.clk);
        vif.awvalid <= 1'b1;
        vif.awaddr <= req.address;
        vif.awsize <= 3'b011;  // 8 bytes
        vif.awlen <= 8'b0;
        vif.awsnoop <= req.snoop_type;
        vif.awdomain <= req.domain;
        vif.awcache <= 2'b00;
        
        wait(vif.awready);
        @(posedge vif.clk);
        vif.awvalid <= 1'b0;
        
        // Write data
        vif.wvalid <= 1'b1;
        vif.wdata <= req.data;
        vif.wstrb <= 8'hFF;
        vif.wlast <= 1'b1;
        
        wait(vif.wready);
        @(posedge vif.clk);
        vif.wvalid <= 1'b0;
        vif.wlast <= 1'b0;
        
        // Write response
        wait(vif.bvalid);
        @(posedge vif.clk);
        vif.bready <= 1'b1;
        @(posedge vif.clk);
        vif.bready <= 1'b0;
    endtask
    
    task drive_snoop_response(ace_master_sequence_item req);
        // Respond to snoop requests
        wait(vif.acvalid);
        @(posedge vif.clk);
        vif.acready <= 1'b1;
        @(posedge vif.clk);
        vif.acready <= 1'b0;
        
        // Send snoop response
        vif.crvalid <= 1'b1;
        vif.crresp <= req.cache_state;
        
        wait(vif.crready);
        @(posedge vif.clk);
        vif.crvalid <= 1'b0;
    endtask

endclass

class ace_master_monitor extends uvm_monitor;
    
    `uvm_component_utils(ace_master_monitor)
    
    uvm_analysis_port #(ace_master_sequence_item) ap;
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
            ace_master_sequence_item item;
            
            wait(vif.arvalid || vif.awvalid || vif.acready);
            item = ace_master_sequence_item::type_id::create("item");
            
            if (vif.arvalid) begin
                item.tx_type = READ;
                item.address = vif.araddr;
                item.snoop_type = vif.arsnoop;
            end else if (vif.awvalid) begin
                item.tx_type = WRITE;
                item.address = vif.awaddr;
                item.snoop_type = vif.awsnoop;
            end
            
            ap.write(item);
            @(posedge vif.clk);
        end
    endtask

endclass

class ace_master_agent extends uvm_agent;
    
    `uvm_component_utils(ace_master_agent)
    
    uvm_sequencer #(ace_master_sequence_item) sequencer;
    ace_master_driver driver;
    ace_master_monitor monitor;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        
        sequencer = uvm_sequencer #(ace_master_sequence_item)::type_id::create("sequencer", this);
        driver = ace_master_driver::type_id::create("driver", this);
        monitor = ace_master_monitor::type_id::create("monitor", this);
    endfunction
    
    function void connect_phase(uvm_connect_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
