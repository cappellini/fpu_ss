// Copyright 2022 ETH Zurich.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// FPU Subsystem Predecoder
// Contributor: Fabio Cappellini <fcappellini@ethz.ch>



module fpu_ss_predecoder (
    input  fpu_ss_pkg::acc_prd_req_t prd_req_i,
    output fpu_ss_pkg::acc_prd_rsp_t prd_rsp_o
);

  always_comb begin
    prd_rsp_o.p_accept    = 1'b0;
    prd_rsp_o.p_writeback = 1'b0;
    prd_rsp_o.p_is_mem_op = 1'b0;
    prd_rsp_o.p_use_rs    = 3'b000;

    unique casez (prd_req_i.q_instr_data)
      fpu_ss_instr_pkg::FADD_S,
      fpu_ss_instr_pkg::FSUB_S,
      fpu_ss_instr_pkg::FMUL_S,
      fpu_ss_instr_pkg::FDIV_S,
      fpu_ss_instr_pkg::FSGNJ_S,
      fpu_ss_instr_pkg::FSGNJN_S,
      fpu_ss_instr_pkg::FSGNJX_S,
      fpu_ss_instr_pkg::FMIN_S,
      fpu_ss_instr_pkg::FMAX_S,
      fpu_ss_instr_pkg::FSQRT_S,
      fpu_ss_instr_pkg::FMADD_S,
      fpu_ss_instr_pkg::FMSUB_S,
      fpu_ss_instr_pkg::FNMSUB_S,
      fpu_ss_instr_pkg::FNMADD_S: begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b0;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b000;
      end

      fpu_ss_instr_pkg::FLE_S,
      fpu_ss_instr_pkg::FLT_S,
      fpu_ss_instr_pkg::FEQ_S,
      fpu_ss_instr_pkg::FCLASS_S,
      fpu_ss_instr_pkg::FCVT_W_S,
      fpu_ss_instr_pkg::FCVT_WU_S,
      fpu_ss_instr_pkg::FMV_X_W,
      fpu_ss_instr_pkg::CSRRWI_FSRMI,
      fpu_ss_instr_pkg::CSRRWI_FSFLAGSI:
      begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b1;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b000;
      end

      fpu_ss_instr_pkg::FMV_W_X,
      fpu_ss_instr_pkg::FCVT_S_W,
      fpu_ss_instr_pkg::FCVT_S_WU: begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b0;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b001;
      end

      fpu_ss_instr_pkg::FLW,
      fpu_ss_instr_pkg::FSW: begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b0;
        prd_rsp_o.p_is_mem_op = 1'b1;
        prd_rsp_o.p_use_rs    = 3'b001;
      end

      fpu_ss_instr_pkg::CSRRW_FSCSR,
      fpu_ss_instr_pkg::CSRRS_FRCSR,
      fpu_ss_instr_pkg::CSRRW_FSRM,
      fpu_ss_instr_pkg::CSRRS_FRRM,
      fpu_ss_instr_pkg::CSRRW_FSFLAGS,
      fpu_ss_instr_pkg::CSRRS_FRFLAGS:
      begin:
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b1;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b001;
      end

      default: begin
        prd_rsp_o.p_accept    = 1'b0;
        prd_rsp_o.p_writeback = 1'b0;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b000;
      end
      
    endcase
  end

endmodule // fpu_ss_predecoder