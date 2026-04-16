// Memory Agent
// Models external memory for LLC transactions

class memory_transaction extends uvm_sequence_item;
    
    `uvm_object_utils(memory_transaction)
    
    typedef enum {MEM_READ, MEM_WRITE} mem_tx_type_e;
    
    rand logic [31:0]           address;
    rand logic [63:0]           data;
    rand logic [7:0]            strb;
    mem_tx_type_e               tx_type;
    logic [1:0]                 response;
    
    function new(string name = "memory_transaction");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf(
            "MEM_%s: addr=0x%08X data=0x%016X strb=0x%02X",
            tx_type.name(), address, data, strb
        );
    endfunction

endclass

class memory_driver extends uvm_driver #(memory_transaction);
    
    `uvm_component_utils(memory_driver)
    
    virtual ace_bus vif;
    
    // Memory model
    logic [63:0] mem_array [0:16384];
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ace_bus)::get(this, "", "mem_vif", vif)) begin
            `uvm_fatal("NO_VIF", "Memory virtual interface not found")
        end
        init_memory();
    endfunction
    
    function void init_memory();
        for (int i = 0; i < 16384; i++) begin
            mem_array[i] = 64'h0;
        end
        // Add test data
        mem_array[0] = 64'hDEADBEEFCAFEBABE;
        mem_array[1] = 64'h1234567890ABCDEF;
        mem_array[2] = 64'hFEDCBA9876543210;
    endfunction
    
    task run_phase(uvm_run_phase phase);
        forever begin
            // Simulate memory latency
            wait(vif.arvalid || vif.awvalid);
            
            if (vif.arvalid) begin
                handle_read();
            end
            
            if (vif.awvalid) begin
                handle_write();
            end
        end
    endtask
    
    task handle_read();
        logic [31:0] addr;
        
        @(posedge vif.clk);
        addr = vif.araddr >> 3;  // Convert byte address to 64-bit index
        
        vif.arready <= 1'b1;
        @(posedge vif.clk);
        vif.arready <= 1'b0;
        
        // Simulate 2-cycle latency
        @(posedge vif.clk);
        @(posedge vif.clk);
        
        vif.rvalid <= 1'b1;
        vif.rdata <= mem_array[addr];
        vif.rlast <= 1'b1;
        vif.rresp <= 2'b00;
        
        wait(vif.rready);
        @(posedge vif.clk);
        vif.rvalid <= 1'b0;
    endtask
    
    task handle_write();
        logic [31:0] addr;
        
        @(posedge vif.clk);
        addr = vif.awaddr >> 3;
        
        vif.awready <= 1'b1;
        @(posedge vif.clk);
        vif.awready <= 1'b0;
        
        // Wait for write data
        wait(vif.wvalid);
        
        // Store in memory
        if (vif.wstrb[0]) mem_array[addr][7:0] <= vif.wdata[7:0];
        if (vif.wstrb[1]) mem_array[addr][15:8] <= vif.wdata[15:8];
        if (vif.wstrb[2]) mem_array[addr][23:16] <= vif.wdata[23:16];
        if (vif.wstrb[3]) mem_array[addr][31:24] <= vif.wdata[31:24];
        if (vif.wstrb[4]) mem_array[addr][39:32] <= vif.wdata[39:32];
        if (vif.wstrb[5]) mem_array[addr][47:40] <= vif.wdata[47:40];
        if (vif.wstrb[6]) mem_array[addr][55:48] <= vif.wdata[55:48];
        if (vif.wstrb[7]) mem_array[addr][63:56] <= vif.wdata[63:56];
        
        @(posedge vif.clk);
        vif.wready <= 1'b1;
        @(posedge vif.clk);
        vif.wready <= 1'b0;
        
        @(posedge vif.clk);
        @(posedge vif.clk);
        
        vif.bvalid <= 1'b1;
        vif.bresp <= 2'b00;
        
        wait(vif.bready);
        @(posedge vif.clk);
        vif.bvalid <= 1'b0;
    endtask

endclass

class memory_monitor extends uvm_monitor;
    
    `uvm_component_utils(memory_monitor)
    
    uvm_analysis_port #(memory_transaction) ap;
    virtual ace_bus vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ace_bus)::get(this, "", "mem_vif", vif)) begin
            `uvm_fatal("NO_VIF", "Memory virtual interface not found")
        end
    endfunction
    
    task run_phase(uvm_run_phase phase);
        forever begin
            memory_transaction item;
            
            wait(vif.arvalid && vif.arready);
            item = memory_transaction::type_id::create("item");
            item.tx_type = MEM_READ;
            item.address = vif.araddr;
            ap.write(item);
            @(posedge vif.clk);
            
            wait(vif.awvalid && vif.awready);
            item = memory_transaction::type_id::create("item");
            item.tx_type = MEM_WRITE;
            item.address = vif.awaddr;
            item.data = vif.wdata;
            item.strb = vif.wstrb;
            ap.write(item);
            @(posedge vif.clk);
        end
    endtask

endclass

class memory_agent extends uvm_agent;
    
    `uvm_component_utils(memory_agent)
    
    uvm_sequencer #(memory_transaction) sequencer;
    memory_driver driver;
    memory_monitor monitor;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        
        sequencer = uvm_sequencer #(memory_transaction)::type_id::create("sequencer", this);
        driver = memory_driver::type_id::create("driver", this);
        monitor = memory_monitor::type_id::create("monitor", this);
    endfunction
    
    function void connect_phase(uvm_connect_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
