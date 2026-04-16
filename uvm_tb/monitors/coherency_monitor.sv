// Coherency Monitor - Verifies cache coherency protocol

class coherency_event;
    
    typedef enum {
        COHERENCY_SUCCESS,
        COHERENCY_VIOLATION,
        SNOOP_BROADCAST,
        SNOOP_RESPONSE,
        CACHE_UPDATE
    } event_type_e;
    
    event_type_e            event_type;
    logic [31:0]            address;
    int                     master_id;
    int                     snoop_target;
    real                    timestamp;
    string                  description;
    
    function string convert2string();
        return $sformatf(
            "[%0fs] [M%0d] %s: addr=0x%08X target=M%0d - %s",
            timestamp, master_id, event_type.name(), address, snoop_target, description
        );
    endfunction

endclass

class coherency_monitor extends uvm_monitor;
    
    `uvm_component_utils(coherency_monitor)
    
    uvm_analysis_port #(coherency_event) ap;
    uvm_analysis_imp_port #(ace_transaction, coherency_monitor) ace_rx_port;
    
    // Tracking data structures
    int cache_line_state [logic[31:0]][2];  // [address][master_id]
    int pending_snoops [logic[31:0]];       // [address]
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
        ace_rx_port = new("ace_rx_port", this);
    endfunction
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);
        init_tracking();
    endfunction
    
    function void init_tracking();
        foreach (cache_line_state[addr])
            foreach (cache_line_state[addr][i])
                cache_line_state[addr][i] = 0;  // Invalid
    endfunction
    
    function void write(ace_transaction tx);
        coherency_event evt;
        
        case (tx.phase)
            AR_PHASE: begin
                handle_read_request(tx);
            end
            AW_PHASE: begin
                handle_write_request(tx);
            end
            AC_PHASE: begin
                handle_snoop_request(tx);
            end
            CR_PHASE: begin
                handle_snoop_response(tx);
            end
        endcase
    endfunction
    
    function void handle_read_request(ace_transaction tx);
        coherency_event evt = new();
        
        evt.timestamp = tx.timestamp;
        evt.master_id = tx.master_id;
        evt.address = tx.address;
        evt.event_type = SNOOP_BROADCAST;
        evt.description = $sformatf("Read request - snoop type: 0x%X", tx.snoop_cmd);
        
        // Check for other masters with modified copy
        for (int i = 0; i < 2; i++) begin
            if (i != tx.master_id && cache_line_state[tx.address][i] == 3) begin  // Modified
                evt.snoop_target = i;
                evt.description = $sformatf("Snoop to M%0d (has modified copy)", i);
                break;
            end
        end
        
        ap.write(evt);
        
        // Update state
        cache_line_state[tx.address][tx.master_id] = 1;  // Shared
    endfunction
    
    function void handle_write_request(ace_transaction tx);
        coherency_event evt = new();
        
        evt.timestamp = tx.timestamp;
        evt.master_id = tx.master_id;
        evt.address = tx.address;
        evt.event_type = SNOOP_BROADCAST;
        evt.description = "Write request - broadcasting invalidation";
        
        // Broadcast to all other masters
        for (int i = 0; i < 2; i++) begin
            if (i != tx.master_id && cache_line_state[tx.address][i] != 0) begin
                evt.snoop_target = i;
                evt.description = $sformatf("Invalidate M%0d cache line", i);
                ap.write(evt);
                cache_line_state[tx.address][i] = 0;  // Invalid
            end
        end
        
        // Update requester state
        cache_line_state[tx.address][tx.master_id] = 3;  // Modified
    endfunction
    
    function void handle_snoop_request(ace_transaction tx);
        coherency_event evt = new();
        
        evt.timestamp = tx.timestamp;
        evt.address = tx.address;
        evt.event_type = SNOOP_BROADCAST;
        
        case (tx.snoop_cmd)
            `ACE_SNOOP_CLEANINVALID: begin
                evt.description = "CLEANINVALID - invalidate cache line";
            end
            `ACE_SNOOP_MAKEUNIQUE: begin
                evt.description = "MAKEUNIQUE - exclusive access";
            end
            `ACE_SNOOP_READSHARED: begin
                evt.description = "READSHARED - shared read";
            end
            `ACE_SNOOP_READUNIQUE: begin
                evt.description = "READUNIQUE - exclusive read";
            end
            default: begin
                evt.description = $sformatf("Unknown snoop: 0x%X", tx.snoop_cmd);
            end
        endcase
        
        ap.write(evt);
    endfunction
    
    function void handle_snoop_response(ace_transaction tx);
        coherency_event evt = new();
        
        evt.timestamp = tx.timestamp;
        evt.master_id = tx.master_id;
        evt.event_type = SNOOP_RESPONSE;
        evt.description = $sformatf("Snoop response: 0x%X", tx.snoop_resp);
        
        ap.write(evt);
    endfunction

endclass
