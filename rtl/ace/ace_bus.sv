// ACE Bus Interface Definition
// AMBA AXI4 Coherencyextensions (ACE)

`include "axi4_defines.sv"

interface ace_bus #(
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_USER_WIDTH = 4
);

    // Clock and Reset
    logic clk;
    logic rst_n;

    // ===== Write Address Channel =====
    logic [AXI_ID_WIDTH-1:0]              awid;
    logic [AXI_ADDR_WIDTH-1:0]            awaddr;
    logic [7:0]                           awlen;
    logic [2:0]                           awsize;
    logic [1:0]                           awburst;
    logic [AXI_USER_WIDTH-1:0]            awuser;
    logic                                 awvalid;
    logic                                 awready;
    
    // ACE Extensions for Write Address
    logic [3:0]                           awsnoop;      // Snoop type
    logic [1:0]                           awdomain;     // Domain (non-shareable to system)
    logic [1:0]                           awbar;        // Barrier
    logic [1:0]                           awcache;      // Cache policy
    logic                                 awlock;       // Exclusive access

    // ===== Write Data Channel =====
    logic [AXI_DATA_WIDTH-1:0]            wdata;
    logic [(AXI_DATA_WIDTH/8)-1:0]        wstrb;
    logic                                 wlast;
    logic                                 wvalid;
    logic                                 wready;

    // ===== Write Response Channel =====
    logic [AXI_ID_WIDTH-1:0]              bid;
    logic [1:0]                           bresp;
    logic [AXI_USER_WIDTH-1:0]            buser;
    logic                                 bvalid;
    logic                                 bready;

    // ===== Read Address Channel =====
    logic [AXI_ID_WIDTH-1:0]              arid;
    logic [AXI_ADDR_WIDTH-1:0]            araddr;
    logic [7:0]                           arlen;
    logic [2:0]                           arsize;
    logic [1:0]                           arburst;
    logic [AXI_USER_WIDTH-1:0]            aruser;
    logic                                 arvalid;
    logic                                 arready;
    
    // ACE Extensions for Read Address
    logic [3:0]                           arsnoop;      // Snoop type
    logic [1:0]                           ardomain;     // Domain
    logic [1:0]                           arbar;        // Barrier
    logic [1:0]                           arcache;      // Cache policy
    logic                                 arlock;       // Exclusive access

    // ===== Read Data Channel =====
    logic [AXI_ID_WIDTH-1:0]              rid;
    logic [AXI_DATA_WIDTH-1:0]            rdata;
    logic [1:0]                           rresp;
    logic                                 rlast;
    logic [AXI_USER_WIDTH-1:0]            ruser;
    logic                                 rvalid;
    logic                                 rready;
    
    // ACE Extensions for Read Data
    logic [1:0]                           rcrresp;      // Cache response
    logic                                 racvalid;     // Cache valid

    // ===== Snoop Address Channel (ACE only) =====
    logic [AXI_ID_WIDTH-1:0]              acid;
    logic [AXI_ADDR_WIDTH-1:0]            acaddr;
    logic [3:0]                           acsnoop;
    logic [1:0]                           acdomain;
    logic                                 acvalid;
    logic                                 acready;

    // ===== Snoop Response Channel (ACE only) =====
    logic [AXI_ID_WIDTH-1:0]              crid;
    logic [2:0]                           crresp;
    logic                                 crvalid;
    logic                                 crready;

    // ===== Snoop Data Channel (ACE only) =====
    logic [AXI_ID_WIDTH-1:0]              cdid;
    logic [AXI_DATA_WIDTH-1:0]            cddata;
    logic                                 cdlast;
    logic                                 cdvalid;
    logic                                 cdready;

    // ===== Master Mode Modport =====
    modport master (
        output awid, awaddr, awlen, awsize, awburst, awuser, awvalid,
               awsnoop, awdomain, awbar, awcache, awlock,
               wdata, wstrb, wlast, wvalid,
               bready,
               arid, araddr, arlen, arsize, arburst, aruser, arvalid,
               arsnoop, ardomain, arbar, arcache, arlock,
               rready,
               crresp, crvalid,
               cddata, cdlast, cdvalid,
        input  awready,
               wready,
               bid, bresp, buser, bvalid,
               arready,
               rid, rdata, rresp, rlast, ruser, rvalid, rcrresp, racvalid,
               acid, acaddr, acsnoop, acdomain, acvalid,
               crid, crready,
               cdid, cdready
    );

    // ===== Slave Mode Modport =====
    modport slave (
        input  awid, awaddr, awlen, awsize, awburst, awuser, awvalid,
               awsnoop, awdomain, awbar, awcache, awlock,
               wdata, wstrb, wlast, wvalid,
               bready,
               arid, araddr, arlen, arsize, arburst, aruser, arvalid,
               arsnoop, ardomain, arbar, arcache, arlock,
               rready,
               crresp, crvalid,
               cddata, cdlast, cdvalid,
        output awready,
               wready,
               bid, bresp, buser, bvalid,
               arready,
               rid, rdata, rresp, rlast, ruser, rvalid, rcrresp, racvalid,
               acid, acaddr, acsnoop, acdomain, acvalid,
               crid, crready,
               cdid, cdready
    );

endinterface
