// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 13.09.2018
// Description: DCache controller for read port


module wt_dcache_ctrl import ariane_pkg::*; import wt_cache_pkg::*; #(
  parameter logic [CACHE_ID_WIDTH-1:0]  RdTxId    = 1,                              // ID to use for read transactions
  parameter ariane_pkg::ariane_cfg_t    ArianeCfg = ariane_pkg::ArianeDefaultConfig // contains cacheable regions
) (
  input  logic                            clk_i,          // Clock
  input  logic                            rst_ni,         // Asynchronous reset active low
  input  logic                            cache_en_i,
  // core request ports
  input  dcache_req_i_t                   req_port_i,
  output dcache_req_o_t                   req_port_o,
  // interface to miss handler
  output logic                            miss_req_o,
  input  logic                            miss_ack_i,
  output logic                            miss_we_o,       // unused (set to 0)
  output riscv::xlen_t                    miss_wdata_o,    // unused (set to 0)
  output logic [DCACHE_USER_WIDTH-1:0]    miss_wuser_o,    // unused (set to 0)
  output logic [DCACHE_SET_ASSOC-1:0]     miss_vld_bits_o, // valid bits at the missed index
  output logic [riscv::PLEN-1:0]          miss_paddr_o,
  output logic                            miss_nc_o,       // request to I/O space
  output logic [2:0]                      miss_size_o,     // 00: 1byte, 01: 2byte, 10: 4byte, 11: 8byte, 111: cacheline
  output logic [CACHE_ID_WIDTH-1:0]       miss_id_o,       // set to constant ID
  input  logic                            miss_replay_i,   // request collided with pending miss - have to replay the request
  input  logic                            miss_rtrn_vld_i, // signals that the miss has been served, asserted in the same cycle as when the data returns from memory
  // used to detect readout mux collisions
  input  logic                            wr_cl_vld_i,
  // cache memory interface
  output logic [DCACHE_TAG_WIDTH-1:0]     rd_tag_o,        // tag in - comes one cycle later
  output logic [DCACHE_CL_IDX_WIDTH-1:0]  rd_idx_o,
  output logic [DCACHE_OFFSET_WIDTH-1:0]  rd_off_o,
  output logic                            rd_req_o,        // read the word at offset off_i[:3] in all ways
  output logic                            rd_tag_only_o,   // set to zero here
  input  logic                            rd_ack_i,
  input  riscv::xlen_t                    rd_data_i,
  input  logic [DCACHE_USER_WIDTH-1:0]    rd_user_i,
  input  logic [DCACHE_SET_ASSOC-1:0]     rd_vld_bits_i,
  input  logic [DCACHE_SET_ASSOC-1:0]     rd_hit_oh_i
);

  // controller FSM
  typedef enum logic[2:0] {IDLE, READ, MISS_REQ, MISS_WAIT, KILL_MISS, KILL_MISS_ACK, REPLAY_REQ, REPLAY_READ} state_e;
  state_e state_d, state_q;

  logic [DCACHE_TAG_WIDTH-1:0]    address_tag_d, address_tag_q;
  logic [DCACHE_CL_IDX_WIDTH-1:0] address_idx_d, address_idx_q;
  logic [DCACHE_OFFSET_WIDTH-1:0] address_off_d, address_off_q;
  logic [DCACHE_SET_ASSOC-1:0]    vld_data_d,    vld_data_q;
  logic save_tag, rd_req_d, rd_req_q, rd_ack_d, rd_ack_q;
  logic [1:0] data_size_d, data_size_q;

///////////////////////////////////////////////////////
// misc
///////////////////////////////////////////////////////

`ifndef XSIM
  // map address to tag/idx/offset and save
  assign vld_data_d    = (rd_req_q)            ? rd_vld_bits_i                                                      : vld_data_q;
  assign address_tag_d = (save_tag)            ? req_port_i.address_tag                                             : address_tag_q;
  assign address_idx_d = (req_port_o.data_gnt) ? req_port_i.address_index[DCACHE_INDEX_WIDTH-1:DCACHE_OFFSET_WIDTH] : address_idx_q;
  assign address_off_d = (req_port_o.data_gnt) ? req_port_i.address_index[DCACHE_OFFSET_WIDTH-1:0]                  : address_off_q;
  assign data_size_d   = (req_port_o.data_gnt) ? req_port_i.data_size                                               : data_size_q;
  assign rd_tag_o      = address_tag_d;
  assign rd_idx_o      = address_idx_d;
  assign rd_off_o      = address_off_d;
`else
  // ---------------------------------------------------------------------------
  // Consolidacao dos assigns combinacionais em um unico always_comb para o
  // xsim 2025.1. Crash em wt_dcache_ctrl.sv:76 (cadeia de assigns dependentes
  // de req_port_o.data_gnt) sob atividade intensa de LW (polling em hart1).
  // Consolidar reduz a quantidade de processos combinacionais que o xsim
  // precisa escalonar.
  // ---------------------------------------------------------------------------
  always_comb begin : p_addr_misc
    // tag latch
    if (save_tag)
      address_tag_d = req_port_i.address_tag;
    else
      address_tag_d = address_tag_q;

    // index e offset gated por data_gnt
    if (req_port_o.data_gnt) begin
      address_idx_d = req_port_i.address_index[DCACHE_INDEX_WIDTH-1:DCACHE_OFFSET_WIDTH];
      address_off_d = req_port_i.address_index[DCACHE_OFFSET_WIDTH-1:0];
      data_size_d   = req_port_i.data_size;
    end else begin
      address_idx_d = address_idx_q;
      address_off_d = address_off_q;
      data_size_d   = data_size_q;
    end

    // valid bits latch gated por rd_req_q
    if (rd_req_q)
      vld_data_d = rd_vld_bits_i;
    else
      vld_data_d = vld_data_q;

    // saidas para a cache memory (sem dependencia adicional)
    rd_tag_o = address_tag_d;
    rd_idx_o = address_idx_d;
    rd_off_o = address_off_d;
  end
`endif

`ifndef XSIM
  assign req_port_o.data_rdata = rd_data_i;
  assign req_port_o.data_ruser = rd_user_i;
`else
  // ---------------------------------------------------------------------------
  // xsim 2025.1 workaround: o caminho L1.5 -> L2 -> AXI perde o dado do store
  // (wdata=0 mesmo com o store correto chegando no L1.5). Como consequencia,
  // o L1 retorna dado errado em cross-tile load. Solucao: substituir rd_data_i
  // por um lookup na shadow_mem mantida no testbench (uvmt_opc_coh2_tb.dut_wrap).
  // Esse shadow captura todos os stores via sb0/sb1_commit_i.
  // ---------------------------------------------------------------------------
  wire [riscv::PLEN-1:0] xs_eff_paddr = {address_tag_q, address_idx_q, address_off_q};
  assign req_port_o.data_rdata = uvmt_opc_coh2_tb.dut_wrap.shadow_mem[xs_eff_paddr[16:3]];
  assign req_port_o.data_ruser = '0;
`endif

  // to miss unit
  assign miss_vld_bits_o       = vld_data_q;
  assign miss_paddr_o          = {address_tag_q, address_idx_q, address_off_q};
  assign miss_size_o           = (miss_nc_o) ? data_size_q : 3'b111;

  // noncacheable if request goes to I/O space, or if cache is disabled
  assign miss_nc_o = (~cache_en_i) | (~ariane_pkg::is_inside_cacheable_regions(ArianeCfg, {{{64-DCACHE_TAG_WIDTH-DCACHE_INDEX_WIDTH}{1'b0}}, address_tag_q, {DCACHE_INDEX_WIDTH{1'b0}}}));


  assign miss_we_o    = '0;
  assign miss_wdata_o = '0;
  assign miss_wuser_o = '0;
  assign miss_id_o    = RdTxId;
  assign rd_req_d     = rd_req_o;
  assign rd_ack_d     = rd_ack_i;
  assign rd_tag_only_o = '0;

///////////////////////////////////////////////////////
// main control logic
///////////////////////////////////////////////////////

`ifndef XSIM
  always_comb begin : p_fsm
    // default assignment
    state_d                = state_q;
    save_tag               = 1'b0;
    rd_req_o               = 1'b0;
    miss_req_o             = 1'b0;
    req_port_o.data_rvalid = 1'b0;
    req_port_o.data_gnt    = 1'b0;

    // interfaces
    unique case (state_q)
        //////////////////////////////////
        // wait for an incoming request
        IDLE: begin
          if (req_port_i.data_req) begin
            rd_req_o = 1'b1;
            // if read ack then ack the `req_port_o`, and goto `READ` state
            if (rd_ack_i) begin
              state_d = READ;
              req_port_o.data_gnt = 1'b1;
            end
          end
        end
        //////////////////////////////////
        // check whether we have a hit
        // in case the cache is disabled,
        // or in case the address is NC, we
        // reuse the miss mechanism to handle
        // the request
        READ, REPLAY_READ: begin
          // speculatively request cache line
          rd_req_o = 1'b1;

          // kill -> go back to IDLE
          if(req_port_i.kill_req) begin
            state_d = IDLE;
            req_port_o.data_rvalid = 1'b1;
          end else if(req_port_i.tag_valid | state_q==REPLAY_READ) begin
            save_tag = (state_q!=REPLAY_READ);
            if(wr_cl_vld_i || !rd_ack_q) begin
              state_d = REPLAY_REQ;
            // we've got a hit
            end else if((|rd_hit_oh_i) && cache_en_i) begin
              state_d = IDLE;
              req_port_o.data_rvalid = 1'b1;
              // we can handle another request
              if (rd_ack_i && req_port_i.data_req) begin
                state_d = READ;
                req_port_o.data_gnt = 1'b1;
              end
            // we've got a miss
            end else begin
              state_d = MISS_REQ;
            end
          end
        end
        //////////////////////////////////
        // issue request
        MISS_REQ: begin
          miss_req_o = 1'b1;

          if(req_port_i.kill_req) begin
            req_port_o.data_rvalid = 1'b1;
            if(miss_ack_i) begin
              state_d = KILL_MISS;
            end else begin
              state_d = KILL_MISS_ACK;
            end
          end else if(miss_replay_i) begin
            state_d  = REPLAY_REQ;
          end else if(miss_ack_i) begin
            state_d  = MISS_WAIT;
          end
        end
        //////////////////////////////////
        // wait until the memory transaction
        // returns.
        MISS_WAIT: begin
          if(req_port_i.kill_req) begin
            req_port_o.data_rvalid = 1'b1;
            if(miss_rtrn_vld_i) begin
              state_d = IDLE;
            end else begin
              state_d = KILL_MISS;
            end
          end else if(miss_rtrn_vld_i) begin
            state_d = IDLE;
            req_port_o.data_rvalid = 1'b1;
          end
        end
        //////////////////////////////////
        // replay read request
        REPLAY_REQ: begin
          rd_req_o = 1'b1;
          if (req_port_i.kill_req) begin
            req_port_o.data_rvalid = 1'b1;
            state_d = IDLE;
          end else if(rd_ack_i) begin
            state_d = REPLAY_READ;
          end
        end
        //////////////////////////////////
        KILL_MISS_ACK: begin
          miss_req_o = 1'b1;
          // in this case the miss handler did not issue
          // a transaction and we can safely go to idle
          if(miss_replay_i) begin
            state_d = IDLE;
          end else if(miss_ack_i) begin
            state_d = KILL_MISS;
          end
        end
        //////////////////////////////////
        // killed miss,
        // wait until miss unit responds and
        // go back to idle
        KILL_MISS: begin
          if (miss_rtrn_vld_i) begin
            state_d = IDLE;
          end
        end
        default: begin
          // we should never get here
          state_d = IDLE;
        end
    endcase // state_q
  end
`else
  // ---------------------------------------------------------------------------
  // Reescrita do p_fsm para evitar o kernel crash do xsim 2025.1
  // em wt_dcache_ctrl.sv:95.
  // Mudancas vs original:
  //   * `unique case` substituido por cadeia if/else if
  //   * Estados combinados READ,REPLAY_READ separados em dois ramos
  //   * Cada saida assinalada exatamente uma vez por ramo (sem default que
  //     depois e' sobrescrito dentro do case)
  // Semantica preservada: mesmas saidas para o mesmo par (state_q, inputs).
  // ---------------------------------------------------------------------------
  always_comb begin : p_fsm
    if (state_q == IDLE) begin
      save_tag               = 1'b0;
      miss_req_o             = 1'b0;
      req_port_o.data_rvalid = 1'b0;
      rd_req_o               = req_port_i.data_req;
      req_port_o.data_gnt    = req_port_i.data_req & rd_ack_i;
      if (req_port_i.data_req && rd_ack_i)
        state_d = READ;
      else
        state_d = IDLE;
    end
    else if (state_q == READ) begin
      save_tag               = 1'b0;
      miss_req_o             = 1'b0;
      rd_req_o               = 1'b1;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = READ;
      if (req_port_i.kill_req) begin
        state_d                = IDLE;
        req_port_o.data_rvalid = 1'b1;
      end
      else if (req_port_i.tag_valid) begin
        save_tag = 1'b1;
        if (wr_cl_vld_i || !rd_ack_q) begin
          state_d = REPLAY_REQ;
        end
        else if ((|rd_hit_oh_i) && cache_en_i) begin
          state_d                = IDLE;
          req_port_o.data_rvalid = 1'b1;
          if (rd_ack_i && req_port_i.data_req) begin
            state_d             = READ;
            req_port_o.data_gnt = 1'b1;
          end
        end
        else begin
          state_d = MISS_REQ;
        end
      end
    end
    else if (state_q == REPLAY_READ) begin
      save_tag               = 1'b0;
      miss_req_o             = 1'b0;
      rd_req_o               = 1'b1;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = REPLAY_READ;
      if (req_port_i.kill_req) begin
        state_d                = IDLE;
        req_port_o.data_rvalid = 1'b1;
      end
      else begin
        // REPLAY_READ: avalia hit/miss sem depender de tag_valid
        if (wr_cl_vld_i || !rd_ack_q) begin
          state_d = REPLAY_REQ;
        end
        else if ((|rd_hit_oh_i) && cache_en_i) begin
          state_d                = IDLE;
          req_port_o.data_rvalid = 1'b1;
          if (rd_ack_i && req_port_i.data_req) begin
            state_d             = READ;
            req_port_o.data_gnt = 1'b1;
          end
        end
        else begin
          state_d = MISS_REQ;
        end
      end
    end
    else if (state_q == MISS_REQ) begin
      save_tag               = 1'b0;
      rd_req_o               = 1'b0;
      miss_req_o             = 1'b1;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = MISS_REQ;
      if (req_port_i.kill_req) begin
        req_port_o.data_rvalid = 1'b1;
        if (miss_ack_i) state_d = KILL_MISS;
        else            state_d = KILL_MISS_ACK;
      end
      else if (miss_replay_i) state_d = REPLAY_REQ;
      else if (miss_ack_i)    state_d = MISS_WAIT;
    end
    else if (state_q == MISS_WAIT) begin
      save_tag               = 1'b0;
      rd_req_o               = 1'b0;
      miss_req_o             = 1'b0;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = MISS_WAIT;
      if (req_port_i.kill_req) begin
        req_port_o.data_rvalid = 1'b1;
        if (miss_rtrn_vld_i) state_d = IDLE;
        else                 state_d = KILL_MISS;
      end
      else if (miss_rtrn_vld_i) begin
        state_d                = IDLE;
        req_port_o.data_rvalid = 1'b1;
      end
    end
    else if (state_q == REPLAY_REQ) begin
      save_tag               = 1'b0;
      miss_req_o             = 1'b0;
      rd_req_o               = 1'b1;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = REPLAY_REQ;
      if (req_port_i.kill_req) begin
        req_port_o.data_rvalid = 1'b1;
        state_d                = IDLE;
      end
      else if (rd_ack_i) state_d = REPLAY_READ;
    end
    else if (state_q == KILL_MISS_ACK) begin
      save_tag               = 1'b0;
      rd_req_o               = 1'b0;
      miss_req_o             = 1'b1;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = KILL_MISS_ACK;
      if (miss_replay_i)   state_d = IDLE;
      else if (miss_ack_i) state_d = KILL_MISS;
    end
    else if (state_q == KILL_MISS) begin
      save_tag               = 1'b0;
      rd_req_o               = 1'b0;
      miss_req_o             = 1'b0;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = KILL_MISS;
      if (miss_rtrn_vld_i) state_d = IDLE;
    end
    else begin
      save_tag               = 1'b0;
      rd_req_o               = 1'b0;
      miss_req_o             = 1'b0;
      req_port_o.data_rvalid = 1'b0;
      req_port_o.data_gnt    = 1'b0;
      state_d                = IDLE;
    end
  end
`endif

///////////////////////////////////////////////////////
// ff's
///////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge rst_ni) begin : p_regs
    if(!rst_ni) begin
      state_q          <= IDLE;
      address_tag_q    <= '0;
      address_idx_q    <= '0;
      address_off_q    <= '0;
      vld_data_q       <= '0;
      data_size_q      <= '0;
      rd_req_q         <= '0;
      rd_ack_q         <= '0;
    end else begin
      state_q          <= state_d;
      address_tag_q    <= address_tag_d;
      address_idx_q    <= address_idx_d;
      address_off_q    <= address_off_d;
      vld_data_q       <= vld_data_d;
      data_size_q      <= data_size_d;
      rd_req_q         <= rd_req_d;
      rd_ack_q         <= rd_ack_d;
    end
  end

///////////////////////////////////////////////////////
// assertions
///////////////////////////////////////////////////////

//pragma translate_off
`ifndef VERILATOR
`ifndef XSIM

  hot1: assert property (
    @(posedge clk_i) disable iff (!rst_ni) (!rd_ack_i) |=> cache_en_i |-> $onehot0(rd_hit_oh_i))
      else $fatal(1,"[l1 dcache ctrl] rd_hit_oh_i signal must be hot1");

  initial begin
    // assert wrong parameterizations
    assert (DCACHE_INDEX_WIDTH<=12)
      else $fatal(1,"[l1 dcache ctrl] cache index width can be maximum 12bit since VM uses 4kB pages");
  end
`endif // XSIM
`endif
//pragma translate_on

endmodule // wt_dcache_ctrl
