// Virtual Sequencer
// Coordinates sequences across multiple agents

class soc_virtual_sequencer extends uvm_sequencer;
    
    `uvm_component_utils(soc_virtual_sequencer)
    
    uvm_sequencer #(ace_master_sequence_item) master_seqr[2];
    uvm_sequencer #(ace_slave_sequence_item) slave_seqr[2];
    uvm_sequencer #(memory_transaction) mem_seqr;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

// UVM Environment
class soc_env extends uvm_env;
    
    `uvm_component_utils(soc_env)
    
    // Agents
    ace_master_agent core_agents[2];
    ace_slave_agent slave_agents[2];
    memory_agent mem_agent;
    
    // Monitors
    ace_monitor ace_monitors[2];
    coherency_monitor coh_monitor;
    
    // Scoreboard
    coherency_sb coh_sb;
    
    // Virtual sequencer
    soc_virtual_sequencer v_seqr;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        
        // Create core agents
        for (int i = 0; i < 2; i++) begin
            core_agents[i] = ace_master_agent::type_id::create($sformatf("core_agent_%0d", i), this);
            uvm_config_db #(int)::set(this, $sformatf("core_agent_%0d", i), "master_id", i);
        end
        
        // Create snoop slave agents
        for (int i = 0; i < 2; i++) begin
            slave_agents[i] = ace_slave_agent::type_id::create($sformatf("slave_agent_%0d", i), this);
        end
        
        // Create memory agent
        mem_agent = memory_agent::type_id::create("mem_agent", this);
        
        // Create monitors
        for (int i = 0; i < 2; i++) begin
            ace_monitors[i] = ace_monitor::type_id::create($sformatf("ace_monitor_%0d", i), this);
            uvm_config_db #(int)::set(this, $sformatf("ace_monitor_%0d", i), "master_id", i);
        end
        
        coh_monitor = coherency_monitor::type_id::create("coh_monitor", this);
        
        // Create scoreboard
        coh_sb = coherency_sb::type_id::create("coh_sb", this);
        
        // Create virtual sequencer
        v_seqr = soc_virtual_sequencer::type_id::create("v_seqr", this);
    endfunction
    
    function void connect_phase(uvm_connect_phase phase);
        super.connect_phase(phase);
        
        // Connect virtual sequencer
        for (int i = 0; i < 2; i++) begin
            v_seqr.master_seqr[i] = core_agents[i].sequencer;
            v_seqr.slave_seqr[i] = slave_agents[i].sequencer;
        end
        v_seqr.mem_seqr = mem_agent.sequencer;
        
        // Connect monitors to scoreboard
        for (int i = 0; i < 2; i++) begin
            ace_monitors[i].ap.connect(coh_monitor.ace_rx_port);
        end
        
        coh_monitor.ap.connect(coh_sb.coherency_port);
    endfunction

endclass
