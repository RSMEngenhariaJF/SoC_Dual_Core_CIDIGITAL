// Coherency Scoreboard
// Verifies cache coherency properties

class coherency_sb extends uvm_scoreboard;
    
    `uvm_component_utils(coherency_sb)
    
    uvm_analysis_imp_port #(coherency_event, coherency_sb) coherency_port;
    
    // Tracking
    bit valid_write_then_read;
    bit snoop_broadcast_seen;
    bit snoop_response_seen;
    
    int violations;
    int proper_sequences;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        coherency_port = new("coherency_port", this);
        violations = 0;
        proper_sequences = 0;
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
    endfunction
    
    function void write(coherency_event evt);
        case (evt.event_type)
            COHERENCY_SUCCESS: begin
                proper_sequences++;
                `uvm_info("SB_PASS", evt.convert2string(), UVM_MEDIUM)
            end
            
            COHERENCY_VIOLATION: begin
                violations++;
                `uvm_warning("SB_VIOL", $sformatf("VIOLATION: %s", evt.convert2string()))
            end
            
            SNOOP_BROADCAST: begin
                snoop_broadcast_seen = 1'b1;
                `uvm_info("SB_SNOOP", evt.convert2string(), UVM_HIGH)
            end
            
            SNOOP_RESPONSE: begin
                snoop_response_seen = 1'b1;
                `uvm_info("SB_RESP", evt.convert2string(), UVM_HIGH)
            end
            
            CACHE_UPDATE: begin
                `uvm_info("SB_CACHE", evt.convert2string(), UVM_MEDIUM)
            end
        endcase
    endfunction
    
    function void report_phase(uvm_report_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SB_REPORT", $sformatf("\n\n=== COHERENCY SCOREBOARD REPORT ===\n"), UVM_MEDIUM)
        `uvm_info("SB_REPORT", $sformatf("Proper Sequences: %0d", proper_sequences), UVM_MEDIUM)
        `uvm_info("SB_REPORT", $sformatf("Violations: %0d", violations), UVM_MEDIUM)
        
        if (violations == 0) begin
            `uvm_info("SB_REPORT", "✓ NO COHERENCY VIOLATIONS DETECTED", UVM_MEDIUM)
        end else begin
            `uvm_error("SB_REPORT", $sformatf("✗ %0d COHERENCY VIOLATIONS FOUND", violations))
        end
        
        `uvm_info("SB_REPORT", $sformatf("==============================\n"), UVM_MEDIUM)
    endfunction

endclass
