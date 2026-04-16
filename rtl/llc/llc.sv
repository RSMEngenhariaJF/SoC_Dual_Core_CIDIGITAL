// Last Level Cache (LLC)
// Shared L2 cache with ACE interface for coherency support

`include "axi4_defines.sv"

module llc #(
    parameter CACHE_SIZE     = 4096,    // 4KB cache
    parameter LINE_SIZE      = 64,      // 64 bytes per line
    parameter NUM_WAYS       = 4,       // 4-way associative
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_USER_WIDTH = 4
) (
    input  logic                         clk,
    input  logic                         rst_n,
    
    // ACE Slave Interface (from CCU)
    ace_bus.slave                        ace,
    
    // External memory interface (AXI4)
    ace_bus.master                       axi_mem
);

    localparam NUM_SETS      = (CACHE_SIZE / (LINE_SIZE * NUM_WAYS));
    localparam LINE_BITS     = $clog2(LINE_SIZE);
    localparam SET_BITS      = (NUM_SETS > 1) ? $clog2(NUM_SETS) : 1;
    localparam TAG_BITS      = AXI_ADDR_WIDTH - LINE_BITS - SET_BITS;
    
    // Cache line structure
    typedef struct packed {
        logic                           valid;
        logic                           dirty;
        logic [1:0]                     state;  // 00=Invalid, 01=Shared, 10=Unique, 11=Modified
        logic [TAG_BITS-1:0]            tag;
        logic [LINE_SIZE*8-1:0]         data;
    } cache_line_t;
    
    // Cache memory
    cache_line_t cache_mem [NUM_SETS][NUM_WAYS];
    logic [NUM_WAYS-1:0]                lru_cntr [NUM_SETS];
    
    // Write address channel buffering
    logic                               aw_valid_buf;
    logic [AXI_ID_WIDTH-1:0]            aw_id_buf;
    logic [AXI_ADDR_WIDTH-1:0]          aw_addr_buf;
    logic [7:0]                         aw_len_buf;
    logic [2:0]                         aw_size_buf;
    logic [1:0]                         aw_burst_buf;
    logic [AXI_USER_WIDTH-1:0]          aw_user_buf;
    logic [3:0]                         aw_snoop_buf;
    logic [1:0]                         aw_domain_buf;
    logic [1:0]                         aw_cache_buf;
    logic                               aw_lock_buf;
    
    // Read address channel buffering
    logic                               ar_valid_buf;
    logic [AXI_ID_WIDTH-1:0]            ar_id_buf;
    logic [AXI_ADDR_WIDTH-1:0]          ar_addr_buf;
    logic [7:0]                         ar_len_buf;
    logic [2:0]                         ar_size_buf;
    logic [1:0]                         ar_burst_buf;
    logic [AXI_USER_WIDTH-1:0]          ar_user_buf;
    logic [3:0]                         ar_snoop_buf;
    logic [1:0]                         ar_domain_buf;
    logic [1:0]                         ar_cache_buf;
    logic                               ar_lock_buf;
    
    // Extracted address fields
    logic [SET_BITS-1:0]                aw_set, ar_set;
    logic [TAG_BITS-1:0]                aw_tag, ar_tag;
    logic [LINE_BITS-1:0]               aw_offset, ar_offset;
    
    // Hit/Miss signals
    logic                               aw_cache_hit;
    logic [NUM_WAYS-1:0]                aw_way_hit;
    logic                               ar_cache_hit;
    logic [NUM_WAYS-1:0]                ar_way_hit;
    
    // ===== Address Decoding =====
    always_comb begin
        aw_set    = ace.awaddr[LINE_BITS+SET_BITS-1:LINE_BITS];
        aw_tag    = ace.awaddr[AXI_ADDR_WIDTH-1:LINE_BITS+SET_BITS];
        aw_offset = ace.awaddr[LINE_BITS-1:0];
        
        ar_set    = ace.araddr[LINE_BITS+SET_BITS-1:LINE_BITS];
        ar_tag    = ace.araddr[AXI_ADDR_WIDTH-1:LINE_BITS+SET_BITS];
        ar_offset = ace.araddr[LINE_BITS-1:0];
    end
    
    // ===== Cache Hit Detection =====
    always_comb begin
        aw_cache_hit = 1'b0;
        aw_way_hit = '0;
        
        for (int i = 0; i < NUM_WAYS; i++) begin
            if (cache_mem[aw_set][i].valid && cache_mem[aw_set][i].tag == aw_tag) begin
                aw_cache_hit = 1'b1;
                aw_way_hit[i] = 1'b1;
            end
        end
    end
    
    always_comb begin
        ar_cache_hit = 1'b0;
        ar_way_hit = '0;
        
        for (int i = 0; i < NUM_WAYS; i++) begin
            if (cache_mem[ar_set][i].valid && cache_mem[ar_set][i].tag == ar_tag) begin
                ar_cache_hit = 1'b1;
                ar_way_hit[i] = 1'b1;
            end
        end
    end
    
    // ===== Write Address Channel =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_valid_buf <= 1'b0;
        end else if (ace.awvalid && ace.awready) begin
            aw_valid_buf <= 1'b1;
            aw_id_buf    <= ace.awid;
            aw_addr_buf  <= ace.awaddr;
            aw_len_buf   <= ace.awlen;
            aw_size_buf  <= ace.awsize;
            aw_burst_buf <= ace.awburst;
            aw_user_buf  <= ace.awuser;
            aw_snoop_buf <= ace.awsnoop;
            aw_domain_buf <= ace.awdomain;
            aw_cache_buf <= ace.awcache;
            aw_lock_buf  <= ace.awlock;
        end else if (axi_mem.bvalid && axi_mem.bready) begin
            aw_valid_buf <= 1'b0;
        end
    end
    
    assign ace.awready = 1'b1;  // Always accept write address
    
    // ===== Write Data Channel =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_mem.wvalid <= 1'b0;
        end else if (ace.wvalid && aw_cache_hit) begin
            // Write hit: update cache directly
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (aw_way_hit[i]) begin
                    cache_mem[aw_set][i].data <= ace.wdata;
                    cache_mem[aw_set][i].dirty <= 1'b1;
                    cache_mem[aw_set][i].state <= 2'b11;  // Modified
                end
            end
            axi_mem.wvalid <= 1'b0;
        end else if (ace.wvalid && !aw_cache_hit) begin
            // Write miss: forward to memory
            axi_mem.wvalid <= 1'b1;
            axi_mem.wdata  <= ace.wdata;
            axi_mem.wstrb  <= ace.wstrb;
            axi_mem.wlast  <= ace.wlast;
        end else begin
            axi_mem.wvalid <= 1'b0;
        end
    end
    
    assign ace.wready = ace.awready;  // Simplified: always ready
    
    // ===== Write Response Channel =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ace.bvalid <= 1'b0;
        end else if (aw_valid_buf && ace.wvalid) begin
            // Send response after write
            ace.bvalid <= 1'b1;
            ace.bid    <= aw_id_buf;
            ace.bresp  <= `AXI4_RESP_OKAY;
            ace.buser  <= aw_user_buf;
        end else if (ace.bready) begin
            ace.bvalid <= 1'b0;
        end
    end
    
    assign ace.bready = ace.bready;  // Flow control
    
    // ===== Read Address Channel =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ar_valid_buf <= 1'b0;
        end else if (ace.arvalid && ace.arready) begin
            ar_valid_buf <= 1'b1;
            ar_id_buf    <= ace.arid;
            ar_addr_buf  <= ace.araddr;
            ar_len_buf   <= ace.arlen;
            ar_size_buf  <= ace.arsize;
            ar_burst_buf <= ace.arburst;
            ar_user_buf  <= ace.aruser;
            ar_snoop_buf <= ace.arsnoop;
            ar_domain_buf <= ace.ardomain;
            ar_cache_buf <= ace.arcache;
            ar_lock_buf  <= ace.arlock;
        end else if (ace.rvalid && ace.rready && ace.rlast) begin
            ar_valid_buf <= 1'b0;
        end
    end
    
    assign ace.arready = 1'b1;  // Always accept read address
    
    // ===== Read Data Channel =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ace.rvalid <= 1'b0;
        end else if (ar_valid_buf && ar_cache_hit) begin
            // Read hit: return from cache
            ace.rvalid <= 1'b1;
            ace.rid    <= ar_id_buf;
            
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (ar_way_hit[i]) begin
                    ace.rdata   <= cache_mem[ar_set][i].data;
                    ace.rcrresp <= {1'b0, cache_mem[ar_set][i].state};
                end
            end
            
            ace.rresp   <= `AXI4_RESP_OKAY;
            ace.rlast   <= 1'b1;
            ace.ruser   <= ar_user_buf;
            ace.racvalid <= 1'b0;
        end else if (ar_valid_buf && !ar_cache_hit) begin
            // Read miss: forward to memory
            if (!axi_mem.arvalid) begin
                axi_mem.arvalid <= 1'b1;
                axi_mem.arid    <= ar_id_buf;
                axi_mem.araddr  <= ar_addr_buf;
                axi_mem.arlen   <= ar_len_buf;
                axi_mem.arsize  <= ar_size_buf;
                axi_mem.arburst <= ar_burst_buf;
                axi_mem.aruser  <= ar_user_buf;
            end else if (axi_mem.arready) begin
                axi_mem.arvalid <= 1'b0;
            end
            
            if (axi_mem.rvalid) begin
                ace.rvalid <= 1'b1;
                ace.rid    <= axi_mem.rid;
                ace.rdata  <= axi_mem.rdata;
                ace.rresp  <= axi_mem.rresp;
                ace.rlast  <= axi_mem.rlast;
                ace.ruser  <= axi_mem.ruser;
            end
        end else if (ace.rready) begin
            ace.rvalid <= 1'b0;
        end
    end
    
    assign ace.rready = ace.rready;  // Flow control
    
    // ===== Snoop Channel =====
    // Simple snoop handler: invalidate or downgrade cache
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ace.crvalid <= 1'b0;
        end else if (ace.acvalid) begin
            // Process snoop request
            logic [SET_BITS-1:0] snoop_set;
            logic [TAG_BITS-1:0] snoop_tag;
            
            snoop_set = ace.acaddr[LINE_BITS+SET_BITS-1:LINE_BITS];
            snoop_tag = ace.acaddr[AXI_ADDR_WIDTH-1:LINE_BITS+SET_BITS];
            
            case (ace.acsnoop)
                `ACE_SNOOP_CLEANINVALID: begin
                    // Invalidate matching cache line
                    for (int i = 0; i < NUM_WAYS; i++) begin
                        if (cache_mem[snoop_set][i].valid && cache_mem[snoop_set][i].tag == snoop_tag) begin
                            cache_mem[snoop_set][i].valid <= 1'b0;
                            ace.crresp <= `ACE_SNOOP_RESP_INVALID;
                        end
                    end
                    ace.crvalid <= 1'b1;
                end
                
                `ACE_SNOOP_READSHARED: begin
                    // Return shared copy if valid
                    for (int i = 0; i < NUM_WAYS; i++) begin
                        if (cache_mem[snoop_set][i].valid && cache_mem[snoop_set][i].tag == snoop_tag) begin
                            if (cache_mem[snoop_set][i].dirty) begin
                                ace.crresp <= `ACE_SNOOP_RESP_PASSDIRTY;
                            end else begin
                                ace.crresp <= `ACE_SNOOP_RESP_PASSDIR;
                            end
                            cache_mem[snoop_set][i].state <= 2'b01;  // Shared
                        end
                    end
                    ace.crvalid <= 1'b1;
                end
                
                `ACE_SNOOP_READUNIQUE: begin
                    // Return unique copy if valid
                    for (int i = 0; i < NUM_WAYS; i++) begin
                        if (cache_mem[snoop_set][i].valid && cache_mem[snoop_set][i].tag == snoop_tag) begin
                            if (cache_mem[snoop_set][i].dirty) begin
                                ace.crresp <= `ACE_SNOOP_RESP_PASSDIRTY;
                            end else begin
                                ace.crresp <= `ACE_SNOOP_RESP_PASSDIR;
                            end
                            cache_mem[snoop_set][i].state <= 2'b10;  // Unique
                        end
                    end
                    ace.crvalid <= 1'b1;
                end
                
                default: begin
                    ace.crvalid <= 1'b0;
                    ace.crresp  <= `ACE_SNOOP_RESP_INVALID;
                end
            endcase
        end else if (ace.crready) begin
            ace.crvalid <= 1'b0;
        end
    end
    
    assign ace.acready = 1'b1;  // Always accept snoop
    
    // ===== Snoop Data Channel =====
    always_comb begin
        for (int i = 0; i < NUM_WAYS; i++) begin
            if (cache_mem[ar_set][i].valid && cache_mem[ar_set][i].tag == ar_tag) begin
                ace.cddata = cache_mem[ar_set][i].data;
            end
        end
        ace.cdlast = 1'b1;
        ace.cdvalid = ace.crvalid && (ace.crresp != `ACE_SNOOP_RESP_INVALID);
    end
    
    assign ace.cdready = ace.cdready;  // Flow control

endmodule
