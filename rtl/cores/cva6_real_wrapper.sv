// CVA6 Real Core Wrapper with ACE Interface Adapter
// Uses the actual Ariane/CVA6 core from OpenHW repository

module cva6_real_wrapper #(
    parameter int unsigned CVA6_CORE_ID = 0,
    parameter int unsigned AXI_ADDR_WIDTH = 32,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH = 4
) (
    input logic clk_i,
    input logic rst_ni,
    
    // ACE interface to interconnect
    ace_bus.master ace,
    
    // Debug/monitor outputs
    output logic [63:0] hart_id_o,
    output logic [2:0]  irq_i_o,
    output logic        debug_req_o
);

    // Internal AXI signals from CVA6
    logic [AXI_ID_WIDTH-1:0] axi_awid, axi_arid, axi_bid, axi_rid;
    logic [AXI_ADDR_WIDTH-1:0] axi_awaddr, axi_araddr;
    logic [7:0] axi_awlen, axi_arlen;
    logic [2:0] axi_awsize, axi_arsize;
    logic [1:0] axi_awburst, axi_arburst;
    logic axi_awvalid, axi_awready, axi_arvalid, axi_arready;
    logic axi_bvalid, axi_bready, axi_rvalid, axi_rready;
    logic [AXI_DATA_WIDTH-1:0] axi_wdata, axi_rdata;
    logic [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb;
    logic axi_wlast, axi_rlast;
    logic axi_wvalid, axi_wready;
    logic [1:0] axi_bresp, axi_rresp;
    
    // Debug/interrupt signals
    logic [63:0] hart_id_int;
    logic [2:0]  irq_i_int;
    logic        debug_req_int;
    
    // =========================================================================
    // Instantiate CVA6 Core from OpenHW Repository
    // =========================================================================
    
    // Note: This instantiates 'ariane' which is the wrapper around 'cva6'
    // The configuration comes from cva6_pkg
    ariane i_cva6_core (
        .clk_i           ( clk_i ),
        .rst_ni          ( rst_ni ),
        .boot_addr_i     ( 64'h80000000 ),
        .hart_id_i       ( {{{64-$bits(CVA6_CORE_ID)}{1'b0}}, CVA6_CORE_ID[($bits(CVA6_CORE_ID)-1):0]} ),
        .irq_i           ( irq_i_int[1:0] ),
        .ipi_i           ( 1'b0 ),
        .time_irq_i      ( 1'b0 ),
        .debug_req_i     ( debug_req_int ),
        .rvfi_probes_o   ( ),  // Not used in this integration
        .noc_req_o       ( {axi_rid, axi_bid, axi_awid, axi_arid, axi_bresp, axi_rresp,
                            axi_awlen, axi_arlen, axi_awsize, axi_arsize, axi_awburst, axi_arburst,
                            axi_rdata, axi_wdata, axi_awaddr, axi_araddr,
                            axi_bvalid, axi_rvalid, axi_rlast, axi_wlast, axi_wvalid, axi_awvalid, axi_arvalid,
                            axi_wstrb} ),
        .noc_resp_i      ( {axi_bresp, axi_bvalid, axi_rvalid, axi_rlast, axi_rdata,
                            axi_awready, axi_wready, axi_arready, axi_bready, axi_rready,
                            axi_bid, axi_rid} )
    );

    // =========================================================================
    // AXI4 to AXI4+ACE Adapter
    // ========================================================================= 
    
    cva6_ace_adapter i_adapter (
        .clk           ( clk_i ),
        .rst_n         ( rst_ni ),
        
        // AXI4 from CVA6
        .axi_awid      ( axi_awid ),
        .axi_awaddr    ( axi_awaddr ),
        .axi_awlen     ( axi_awlen ),
        .axi_awsize    ( axi_awsize ),
        .axi_awburst   ( axi_awburst ),
        .axi_awvalid   ( axi_awvalid ),
        .axi_awready   ( axi_awready ),
        
        .axi_wdata     ( axi_wdata ),
        .axi_wstrb     ( axi_wstrb ),
        .axi_wlast     ( axi_wlast ),
        .axi_wvalid    ( axi_wvalid ),
        .axi_wready    ( axi_wready ),
        
        .axi_bid       ( axi_bid ),
        .axi_bresp     ( axi_bresp ),
        .axi_bvalid    ( axi_bvalid ),
        .axi_bready    ( axi_bready ),
        
        .axi_arid      ( axi_arid ),
        .axi_araddr    ( axi_araddr ),
        .axi_arlen     ( axi_arlen ),
        .axi_arsize    ( axi_arsize ),
        .axi_arburst   ( axi_arburst ),
        .axi_arvalid   ( axi_arvalid ),
        .axi_arready   ( axi_arready ),
        
        .axi_rid       ( axi_rid ),
        .axi_rdata     ( axi_rdata ),
        .axi_rresp     ( axi_rresp ),
        .axi_rlast     ( axi_rlast ),
        .axi_rvalid    ( axi_rvalid ),
        .axi_rready    ( axi_rready ),
        
        // ACE output
        .ace           ( ace )
    );

    // =========================================================================
    // Output Assignments for Monitoring/Debug
    // =========================================================================
    
    assign hart_id_o = hart_id_int;
    assign irq_i_o = irq_i_int;
    assign debug_req_o = debug_req_int;

endmodule : cva6_real_wrapper
