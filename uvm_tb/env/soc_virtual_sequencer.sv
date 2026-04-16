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
