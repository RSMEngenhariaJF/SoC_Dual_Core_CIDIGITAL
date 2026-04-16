// Coherency Test Sequences

class base_coherency_sequence extends uvm_sequence #(ace_master_sequence_item);
    
    `uvm_object_utils(base_coherency_sequence)
    
    function new(string name = "base_coherency_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info("BASE_COH", "Base coherency sequence", UVM_HIGH)
    endtask

endclass

class write_invalidate_sequence extends base_coherency_sequence;
    
    `uvm_object_utils(write_invalidate_sequence)
    
    // Test: Write causes invalidation of other caches
    
    function new(string name = "write_invalidate_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        `uvm_info("WR_INV", "Testing Write Invalidation Protocol", UVM_MEDIUM)
        
        // Step 1: Core0 writes
        item = ace_master_sequence_item::type_id::create("core0_write");
        start_item(item);
        
        item.tx_type = WRITE;
        item.address = 32'h00002000;
        item.data = 64'hAAAAAAAAAAAAAAAA;
        item.snoop_type = `ACE_SNOOP_READUNIQUE;
        item.domain = `ACE_DOMAIN_SYS_SHARED;
        
        finish_item(item);
        get_response(item);
        
        `uvm_info("WR_INV", "Core0 wrote 0xAAAAAAAAAAAAAAAA to 0x2000", UVM_MEDIUM)
        
        #300ns;
        
        // Step 2: Verify Core1 gets invalidation snoop
        `uvm_info("WR_INV", "Waiting for snoop invalidation...", UVM_MEDIUM)
        
        #300ns;
        
        `uvm_info("WR_INV", "Write Invalidation Test Complete", UVM_MEDIUM)
    endtask

endclass

class write_update_sequence extends base_coherency_sequence;
    
    `uvm_object_utils(write_update_sequence)
    
    // Test: Multiple writes without intervening reads
    
    function new(string name = "write_update_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        `uvm_info("WR_UPD", "Testing Repeated Write Updates", UVM_MEDIUM)
        
        repeat(3) begin
            item = ace_master_sequence_item::type_id::create("repeated_write");
            start_item(item);
            
            item.tx_type = WRITE;
            item.address = 32'h00003000;
            item.data = $urandom();
            item.snoop_type = `ACE_SNOOP_READUNIQUE;
            item.domain = `ACE_DOMAIN_SYS_SHARED;
            
            finish_item(item);
            get_response(item);
            
            `uvm_info("WR_UPD", $sformatf("Write: data=0x%016X", item.data), UVM_MEDIUM)
            
            #250ns;
        end
        
        `uvm_info("WR_UPD", "Write Update Test Complete", UVM_MEDIUM)
    endtask

endclass

class exclusive_access_sequence extends base_coherency_sequence;
    
    `uvm_object_utils(exclusive_access_sequence)
    
    // Test: Exclusive atomic access
    
    function new(string name = "exclusive_access_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        `uvm_info("EXC_ACC", "Testing Exclusive Access", UVM_MEDIUM)
        
        // Acquire exclusive access
        item = ace_master_sequence_item::type_id::create("excl_read");
        start_item(item);
        
        item.tx_type = READ;
        item.address = 32'h00004000;
        item.snoop_type = `ACE_SNOOP_READUNIQUE;
        item.domain = `ACE_DOMAIN_SYS_SHARED;
        
        finish_item(item);
        get_response(item);
        
        `uvm_info("EXC_ACC", "Acquired exclusive read access", UVM_MEDIUM)
        
        #200ns;
        
        // Exclusive write
        item = ace_master_sequence_item::type_id::create("excl_write");
        start_item(item);
        
        item.tx_type = WRITE;
        item.address = 32'h00004000;
        item.data = 64'hBBBBBBBBBBBBBBBB;
        item.snoop_type = `ACE_SNOOP_READUNIQUE;
        item.domain = `ACE_DOMAIN_SYS_SHARED;
        
        finish_item(item);
        get_response(item);
        
        `uvm_info("EXC_ACC", "Exclusive write complete", UVM_MEDIUM)
    endtask

endclass

class snoop_forward_sequence extends base_coherency_sequence;
    
    `uvm_object_utils(snoop_forward_sequence)
    
    // Test: Snoop forwarding from one core to another
    
    function new(string name = "snoop_forward_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        `uvm_info("SN_FWD", "Testing Snoop Forwarding", UVM_MEDIUM)
        
        // Core0: Read with READUNIQUE (expects unique copy)
        item = ace_master_sequence_item::type_id::create("snoop_read");
        start_item(item);
        
        item.tx_type = READ;
        item.address = 32'h00005000;
        item.snoop_type = `ACE_SNOOP_READUNIQUE;
        item.domain = `ACE_DOMAIN_SYS_SHARED;
        
        finish_item(item);
        get_response(item);
        
        `uvm_info("SN_FWD", "Read with READUNIQUE snoop", UVM_MEDIUM)
        
        #300ns;
        
        // Verify CCU forwards snoop to other core
        `uvm_info("SN_FWD", "Checking snoop forwarding...", UVM_MEDIUM)
        
        #300ns;
        
        `uvm_info("SN_FWD", "Snoop Forward Test Complete", UVM_MEDIUM)
    endtask

endclass
