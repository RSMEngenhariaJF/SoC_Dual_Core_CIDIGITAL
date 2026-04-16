// CVA6 to ACE Adapter
// Converts CVA6 AXI4 interface to AXI4+ACE

module cva6_ace_adapter #(
    parameter AXI_ID_WIDTH = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64
) (
    input clk,
    input rst_n,
    
    // AXI4 interface from CVA6
    input [AXI_ID_WIDTH-1:0] axi_awid,
    input [AXI_ADDR_WIDTH-1:0] axi_awaddr,
    input [7:0] axi_awlen,
    input [2:0] axi_awsize,
    input [1:0] axi_awburst,
    input axi_awvalid,
    output axi_awready,
    
    input [AXI_DATA_WIDTH-1:0] axi_wdata,
    input [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb,
    input axi_wlast,
    input axi_wvalid,
    output axi_wready,
    
    output [AXI_ID_WIDTH-1:0] axi_bid,
    output [1:0] axi_bresp,
    output axi_bvalid,
    input axi_bready,
    
    input [AXI_ID_WIDTH-1:0] axi_arid,
    input [AXI_ADDR_WIDTH-1:0] axi_araddr,
    input [7:0] axi_arlen,
    input [2:0] axi_arsize,
    input [1:0] axi_arburst,
    input axi_arvalid,
    output axi_arready,
    
    output [AXI_ID_WIDTH-1:0] axi_rid,
    output [AXI_DATA_WIDTH-1:0] axi_rdata,
    output [1:0] axi_rresp,
    output axi_rlast,
    output axi_rvalid,
    input axi_rready,
    
    // ACE interface to interconnect
    ace_bus.master ace
);

    // Simple pass-through for now
    // Full adapter with snoop support would go here
    
    assign ace.awid = axi_awid;
    assign ace.awaddr = axi_awaddr;
    assign ace.awlen = axi_awlen;
    assign ace.awsize = axi_awsize;
    assign ace.awburst = axi_awburst;
    assign ace.awvalid = axi_awvalid;
    assign axi_awready = ace.awready;
    assign ace.awsnoop = 4'b0001; // WRITEUNIQUE
    assign ace.awdomain = 2'b11;  // SYS_SHARED
    
    assign ace.wdata = axi_wdata;
    assign ace.wstrb = axi_wstrb;
    assign ace.wlast = axi_wlast;
    assign ace.wvalid = axi_wvalid;
    assign axi_wready = ace.wready;
    
    assign axi_bid = ace.bid;
    assign axi_bresp = ace.bresp;
    assign axi_bvalid = ace.bvalid;
    assign ace.bready = axi_bready;
    
    assign ace.arid = axi_arid;
    assign ace.araddr = axi_araddr;
    assign ace.arlen = axi_arlen;
    assign ace.arsize = axi_arsize;
    assign ace.arburst = axi_arburst;
    assign ace.arvalid = axi_arvalid;
    assign axi_arready = ace.arready;
    assign ace.arsnoop = 4'b0101; // READUNIQUE
    assign ace.ardomain = 2'b11;  // SYS_SHARED
    
    assign axi_rid = ace.rid;
    assign axi_rdata = ace.rdata;
    assign axi_rresp = ace.rresp;
    assign axi_rlast = ace.rlast;
    assign axi_rvalid = ace.rvalid;
    assign ace.rready = axi_rready;

endmodule
