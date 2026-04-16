// AXI4 Protocol Definitions
// Base AXI4 definitions extended for ACE support

`ifndef AXI4_DEFINES_SV
`define AXI4_DEFINES_SV

// AXI4 Burst Types
`define AXI4_BURST_FIXED   2'b00
`define AXI4_BURST_INCR    2'b01
`define AXI4_BURST_WRAP    2'b10

// AXI4 Response Types
`define AXI4_RESP_OKAY     2'b00
`define AXI4_RESP_EXOKAY   2'b01
`define AXI4_RESP_SLVERR   2'b10
`define AXI4_RESP_DECERR   2'b11

// AXI4 Size (2^n bytes per beat)
`define AXI4_SIZE_1B       3'b000
`define AXI4_SIZE_2B       3'b001
`define AXI4_SIZE_4B       3'b010
`define AXI4_SIZE_8B       3'b011
`define AXI4_SIZE_16B      3'b100
`define AXI4_SIZE_32B      3'b101
`define AXI4_SIZE_64B      3'b110

// ACE Coherency Types
`define ACE_BARRIER_NONE   2'b00
`define ACE_BARRIER_SYNC   2'b01

// ACE Domain
`define ACE_DOMAIN_NON_SHAREABLE  2'b00
`define ACE_DOMAIN_INNER_SHARED   2'b01
`define ACE_DOMAIN_OUTER_SHARED   2'b10
`define ACE_DOMAIN_SYS_SHARED     2'b11

// ACE Snoop Types
`define ACE_SNOOP_CLEANINVALID  4'b0000
`define ACE_SNOOP_MAKEUNIQUE    4'b0001
`define ACE_SNOOP_CLEANSHARED   4'b0010
`define ACE_SNOOP_CLEANALL      4'b0011
`define ACE_SNOOP_READSHARED    4'b0100
`define ACE_SNOOP_READUNIQUE    4'b0101
`define ACE_SNOOP_READONCE      4'b0110
`define ACE_SNOOP_READNOTSHAREDDIRTY 4'b0111

// ACE Snoop Response
`define ACE_SNOOP_RESP_PASSDIR   3'b000
`define ACE_SNOOP_RESP_PASSDIRTY 3'b001
`define ACE_SNOOP_RESP_INVALID   3'b010

// ACE Cache State
`define ACE_CACHE_I  2'b00  // Invalid
`define ACE_CACHE_S  2'b01  // Shared
`define ACE_CACHE_U  2'b10  // Unique
`define ACE_CACHE_M  2'b11  // Modified

`endif
