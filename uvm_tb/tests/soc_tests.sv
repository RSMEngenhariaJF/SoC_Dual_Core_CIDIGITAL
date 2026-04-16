// Base Test
// Provides common test infrastructure

class base_test extends uvm_test;
    
    `uvm_component_utils(base_test)
    
    soc_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        env = soc_env::type_id::create("env", this);
    endfunction
    
    function void report_phase(uvm_report_phase phase);
        super.report_phase(phase);
        `uvm_info("TEST_REPORT", $sformatf("Test: %s", get_type_name()), UVM_MEDIUM)
    endfunction

endclass

// Simple Read Test
class read_test extends base_test;
    
    `uvm_component_utils(read_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_run_phase phase);
        ace_read_sequence read_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("READ_TEST", "Starting Read Test", UVM_MEDIUM)
        
        read_seq = ace_read_sequence::type_id::create("read_seq");
        read_seq.num_reads = 5;
        read_seq.start(env.v_seqr.master_seqr[0]);
        
        `uvm_info("READ_TEST", "Read Test Complete", UVM_MEDIUM)
        
        phase.drop_objection(this);
    endtask

endclass

// Simple Write Test
class write_test extends base_test;
    
    `uvm_component_utils(write_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_run_phase phase);
        ace_write_sequence write_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("WRITE_TEST", "Starting Write Test", UVM_MEDIUM)
        
        write_seq = ace_write_sequence::type_id::create("write_seq");
        write_seq.num_writes = 5;
        write_seq.start(env.v_seqr.master_seqr[0]);
        
        `uvm_info("WRITE_TEST", "Write Test Complete", UVM_MEDIUM)
        
        phase.drop_objection(this);
    endtask

endclass

// Mixed Read/Write Test
class mixed_test extends base_test;
    
    `uvm_component_utils(mixed_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_run_phase phase);
        ace_mixed_sequence mixed_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("MIXED_TEST", "Starting Mixed R/W Test", UVM_MEDIUM)
        
        mixed_seq = ace_mixed_sequence::type_id::create("mixed_seq");
        mixed_seq.num_transactions = 10;
        mixed_seq.start(env.v_seqr.master_seqr[0]);
        
        `uvm_info("MIXED_TEST", "Mixed Test Complete", UVM_MEDIUM)
        
        phase.drop_objection(this);
    endtask

endclass

// Coherency Test
class coherency_test extends base_test;
    
    `uvm_component_utils(coherency_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_run_phase phase);
        write_invalidate_sequence inv_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("COH_TEST", "Starting Coherency Test", UVM_MEDIUM)
        
        inv_seq = write_invalidate_sequence::type_id::create("inv_seq");
        inv_seq.start(env.v_seqr.master_seqr[0]);
        
        `uvm_info("COH_TEST", "Coherency Test Complete", UVM_MEDIUM)
        
        phase.drop_objection(this);
    endtask

endclass

// Stress Test
class stress_test extends base_test;
    
    `uvm_component_utils(stress_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_run_phase phase);
        ace_stress_sequence stress_seq[2];
        
        phase.raise_objection(this);
        
        `uvm_info("STRESS_TEST", "Starting Dual-Core Stress Test", UVM_MEDIUM)
        
        // Both cores run stress sequences in parallel
        for (int i = 0; i < 2; i++) begin
            stress_seq[i] = ace_stress_sequence::type_id::create($sformatf("stress_seq_%0d", i));
        end
        
        fork
            stress_seq[0].start(env.v_seqr.master_seqr[0]);
            stress_seq[1].start(env.v_seqr.master_seqr[1]);
        join
        
        `uvm_info("STRESS_TEST", "Dual-Core Stress Test Complete", UVM_MEDIUM)
        
        phase.drop_objection(this);
    endtask

endclass
