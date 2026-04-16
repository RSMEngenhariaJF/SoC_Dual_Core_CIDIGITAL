// SoC Top-Level
// Dual-Core CVA6 with ACE Coherency

`include "axi4_defines.sv"

module soc_top #(
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_USER_WIDTH = 4
) (
    input  logic                         clk,
    input  logic                         rst_n,
    
    // External memory port (to DDR)
    output logic                         mem_clk,
    output logic                         mem_rst_n,
    output logic [AXI_ADDR_WIDTH-1:0]   mem_addr,
    output logic                         mem_valid,
    input  logic [AXI_DATA_WIDTH-1:0]   mem_data,
    input  logic                         mem_ready,
    
    // Debug outputs
    output logic [63:0]                  core0_pc,
    output logic                         core0_valid,
    output logic [63:0]                  core1_pc,
    output logic                         core1_valid,
    
    // Performance monitoring
    output logic [31:0]                  instr_counter,
    output logic [31:0]                  cycle_counter
);

    // ===== Clock and Reset =====
    assign mem_clk = clk;
    assign mem_rst_n = rst_n;
    
    // ===== ACE Bus Instances =====
    ace_bus #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
    ) ace_core0 (.clk(clk), .rst_n(rst_n));
    
    ace_bus #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
    ) ace_core1 (.clk(clk), .rst_n(rst_n));
    
    ace_bus #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
    ) ace_ccu_llc (.clk(clk), .rst_n(rst_n));
    
    ace_bus #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
    ) ace_mem (.clk(clk), .rst_n(rst_n));
    
    // Snoop buses
    ace_bus #(
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
    ) ace_snoop [1:0] (.clk(clk), .rst_n(rst_n));

    // ===== Core Instantiation (Real CVA6) =====
    cva6_real_wrapper #(
        .CVA6_CORE_ID(0),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH)
    ) core0_inst (
        .clk_i(clk),
        .rst_ni(rst_n),
        .ace(ace_core0.master),
        .hart_id_o(),
        .irq_i_o(),
        .debug_req_o()
    );
    
    cva6_real_wrapper #(
        .CVA6_CORE_ID(1),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH)
    ) core1_inst (
        .clk_i(clk),
        .rst_ni(rst_n),
        .ace(ace_core1.master),
        .hart_id_o(),
        .irq_i_o(),
        .debug_req_o()
    );

    // ===== Cache Coherency Unit Instantiation =====
    ccu #(
        .NUM_MASTERS(2),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
    ) ccu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ace_master({ace_core1.slave, ace_core0.slave}),
        .ace_slave(ace_ccu_llc.master),
        .snoop_out(ace_snoop)
    );

    // ===== Last Level Cache Instantiation =====
    llc #(
        .CACHE_SIZE(4096),
        .LINE_SIZE(64),
        .NUM_WAYS(4),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
    ) llc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ace(ace_ccu_llc.slave),
        .axi_mem(ace_mem.master)
    );

    // ===== Debug Outputs (Placeholder for CVA6 Real) =====
    assign core0_pc = 64'b0;  // PC not yet exposed from CVA6 real wrapper
    assign core0_valid = 1'b0;
    assign core1_pc = 64'b0;
    assign core1_valid = 1'b0;
    
    // ===== Performance Monitoring =====
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 32'b0;
            instr_counter <= 32'b0;
        end else begin
            cycle_counter <= cycle_counter + 1;
            // TODO: Connect to actual instruction retire signals from CVA6
        end
    end

    // ===== Memory Interface Adaptation =====
    // For simulation purposes: simple protocol handler
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_valid <= 1'b0;
        end else if (ace_mem.arvalid) begin
            mem_valid <= 1'b1;
            mem_addr  <= ace_mem.araddr;
        end else begin
            mem_valid <= mem_valid & ~mem_ready;
        end
    end

endmodule
