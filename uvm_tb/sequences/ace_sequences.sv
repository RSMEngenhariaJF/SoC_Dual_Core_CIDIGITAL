// ACE Master Test Sequences

class base_ace_sequence extends uvm_sequence #(ace_master_sequence_item);
    
    `uvm_object_utils(base_ace_sequence)
    
    function new(string name = "base_ace_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info("BASE_SEQ", "Base sequence", UVM_HIGH)
    endtask

endclass

class ace_read_sequence extends base_ace_sequence;
    
    `uvm_object_utils(ace_read_sequence)
    
    rand int num_reads;
    constraint reads_c { num_reads inside {[1:10]}; }
    
    function new(string name = "ace_read_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        repeat(num_reads) begin
            item = ace_master_sequence_item::type_id::create("read_item");
            start_item(item);
            
            item.tx_type = READ;
            item.address = $urandom_range(0, 32'h0FFFFFFF);
            item.snoop_type = `ACE_SNOOP_READUNIQUE;
            item.domain = `ACE_DOMAIN_SYS_SHARED;
            item.cache_state = `ACE_CACHE_U;
            
            finish_item(item);
            get_response(item);
            
            `uvm_info("READ_SEQ", item.convert2string(), UVM_MEDIUM)
            
            #100ns;
        end
    endtask

endclass

class ace_write_sequence extends base_ace_sequence;
    
    `uvm_object_utils(ace_write_sequence)
    
    rand int num_writes;
    constraint writes_c { num_writes inside {[1:10]}; }
    
    function new(string name = "ace_write_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        repeat(num_writes) begin
            item = ace_master_sequence_item::type_id::create("write_item");
            start_item(item);
            
            item.tx_type = WRITE;
            item.address = $urandom_range(0, 32'h0FFFFFFF);
            item.data = $urandom_range(0, 64'hFFFFFFFFFFFFFFFF);
            item.snoop_type = `ACE_SNOOP_READUNIQUE;
            item.domain = `ACE_DOMAIN_SYS_SHARED;
            item.cache_state = `ACE_CACHE_M;
            
            finish_item(item);
            get_response(item);
            
            `uvm_info("WRITE_SEQ", item.convert2string(), UVM_MEDIUM)
            
            #150ns;
        end
    endtask

endclass

class ace_coherency_sequence extends base_ace_sequence;
    
    `uvm_object_utils(ace_coherency_sequence)
    
    // Test data coherency - Core0 writes, Core1 reads
    
    function new(string name = "ace_coherency_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        // Core0: Write to address 0x1000 with data 0xDEADBEEF
        `uvm_info("COH_SEQ", "Testing coherency: Core0 WRITE", UVM_MEDIUM)
        
        item = ace_master_sequence_item::type_id::create("coh_write");
        start_item(item);
        
        item.tx_type = WRITE;
        item.address = 32'h00001000;
        item.data = 64'hDEADBEEFCAFEBABE;
        item.snoop_type = `ACE_SNOOP_READUNIQUE;
        item.domain = `ACE_DOMAIN_SYS_SHARED;
        item.cache_state = `ACE_CACHE_M;
        
        finish_item(item);
        get_response(item);
        
        #200ns;
        
        // Core1 should see the updated data
        `uvm_info("COH_SEQ", "Testing coherency: Core1 READ", UVM_MEDIUM)
        
        item = ace_master_sequence_item::type_id::create("coh_read");
        start_item(item);
        
        item.tx_type = READ;
        item.address = 32'h00001000;
        item.snoop_type = `ACE_SNOOP_READSHARED;
        item.domain = `ACE_DOMAIN_SYS_SHARED;
        item.cache_state = `ACE_CACHE_S;
        
        finish_item(item);
        get_response(item);
        
        `uvm_info("COH_SEQ", "Coherency test complete", UVM_MEDIUM)
    endtask

endclass

class ace_mixed_sequence extends base_ace_sequence;
    
    `uvm_object_utils(ace_mixed_sequence)
    
    rand int num_transactions;
    constraint tx_c { num_transactions inside {[5:20]}; }
    
    function new(string name = "ace_mixed_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        repeat(num_transactions) begin
            item = ace_master_sequence_item::type_id::create("mixed_item");
            start_item(item);
            
            // Randomly choose READ or WRITE
            if ($urandom_range(0, 1)) begin
                item.tx_type = READ;
                item.address = $urandom_range(0, 32'h0FFFFFFF);
                item.snoop_type = `ACE_SNOOP_READUNIQUE;
                item.cache_state = `ACE_CACHE_U;
            end else begin
                item.tx_type = WRITE;
                item.address = $urandom_range(0, 32'h0FFFFFFF);
                item.data = $urandom_range(0, 64'hFFFFFFFFFFFFFFFF);
                item.snoop_type = `ACE_SNOOP_READUNIQUE;
                item.cache_state = `ACE_CACHE_M;
            end
            
            item.domain = `ACE_DOMAIN_SYS_SHARED;
            
            finish_item(item);
            get_response(item);
            
            `uvm_info("MIXED_SEQ", item.convert2string(), UVM_LOW)
            
            #(100 + $urandom_range(0, 100))ns;
        end
    endtask

endclass

class ace_stress_sequence extends base_ace_sequence;
    
    `uvm_object_utils(ace_stress_sequence)
    
    function new(string name = "ace_stress_sequence");
        super.new(name);
    endfunction
    
    task body();
        ace_master_sequence_item item;
        
        `uvm_info("STRESS_SEQ", "Starting stress test: 100 transactions", UVM_MEDIUM)
        
        repeat(100) begin
            item = ace_master_sequence_item::type_id::create("stress_item");
            start_item(item);
            
            item.tx_type = ($urandom_range(0, 1) ? READ : WRITE);
            item.address = $urandom_range(0, 32'h00FFFFFF);
            item.data = $urandom();
            item.snoop_type = $urandom_range(0, 7);
            item.domain = $urandom_range(0, 3);
            item.cache_state = $urandom_range(0, 3);
            
            finish_item(item);
            get_response(item);
            
            #(50 + $urandom_range(0, 50))ns;
        end
        
        `uvm_info("STRESS_SEQ", "Stress test complete", UVM_MEDIUM)
    endtask

endclass
