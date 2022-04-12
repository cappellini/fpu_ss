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
      // fp to fp
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
      fpu_ss_instr_pkg::FNMADD_S,
      fpu_ss_instr_pkg::VFADD_S,
      fpu_ss_instr_pkg::VFADD_R_S,
      fpu_ss_instr_pkg::VFSUB_S,
      fpu_ss_instr_pkg::VFSUB_R_S,
      fpu_ss_instr_pkg::VFMUL_S,
      fpu_ss_instr_pkg::VFMUL_R_S,
      fpu_ss_instr_pkg::VFDIV_S,
      fpu_ss_instr_pkg::VFDIV_R_S,
      fpu_ss_instr_pkg::VFMIN_S,
      fpu_ss_instr_pkg::VFMIN_R_S,
      fpu_ss_instr_pkg::VFMAX_S,
      fpu_ss_instr_pkg::VFMAX_R_S,
      fpu_ss_instr_pkg::VFSQRT_S,
      fpu_ss_instr_pkg::VFMAC_S,
      fpu_ss_instr_pkg::VFMAC_R_S,
      fpu_ss_instr_pkg::VFMRE_S,
      fpu_ss_instr_pkg::VFMRE_R_S,
      fpu_ss_instr_pkg::VFSGNJ_S,
      fpu_ss_instr_pkg::VFSGNJ_R_S,
      fpu_ss_instr_pkg::VFSGNJN_S,
      fpu_ss_instr_pkg::VFSGNJN_R_S,
      fpu_ss_instr_pkg::VFSGNJX_S,
      fpu_ss_instr_pkg::VFSGNJX_R_S,
      fpu_ss_instr_pkg::VFSUM_S,
      fpu_ss_instr_pkg::VFNSUM_S,
      fpu_ss_instr_pkg::FADD_H,
      fpu_ss_instr_pkg::FSUB_H,
      fpu_ss_instr_pkg::FMUL_H,
      fpu_ss_instr_pkg::FSGNJ_H,
      fpu_ss_instr_pkg::FSGNJN_H,
      fpu_ss_instr_pkg::FSGNJX_H,
      fpu_ss_instr_pkg::FMIN_H,
      fpu_ss_instr_pkg::FMAX_H,
      fpu_ss_instr_pkg::FSQRT_H,
      fpu_ss_instr_pkg::FMADD_H,
      fpu_ss_instr_pkg::FMSUB_H,
      fpu_ss_instr_pkg::FNMSUB_H,
      fpu_ss_instr_pkg::FNMADD_H,
      fpu_ss_instr_pkg::VFSUM_H,
      fpu_ss_instr_pkg::VFNSUM_H,
      fpu_ss_instr_pkg::FMULEX_S_H,
      fpu_ss_instr_pkg::FMACEX_S_H,
      fpu_ss_instr_pkg::FCVT_S_H,
      fpu_ss_instr_pkg::FCVT_H_S,
      fpu_ss_instr_pkg::FCVT_H_H,
      fpu_ss_instr_pkg::VFADD_H,
      fpu_ss_instr_pkg::VFADD_R_H,
      fpu_ss_instr_pkg::VFSUB_H,
      fpu_ss_instr_pkg::VFSUB_R_H,
      fpu_ss_instr_pkg::VFMUL_H,
      fpu_ss_instr_pkg::VFMUL_R_H,
      fpu_ss_instr_pkg::VFMIN_H,
      fpu_ss_instr_pkg::VFMIN_R_H,
      fpu_ss_instr_pkg::VFMAX_H,
      fpu_ss_instr_pkg::VFMAX_R_H,
      fpu_ss_instr_pkg::VFSQRT_H,
      fpu_ss_instr_pkg::VFMAC_H,
      fpu_ss_instr_pkg::VFMAC_R_H,
      fpu_ss_instr_pkg::VFMRE_H,
      fpu_ss_instr_pkg::VFMRE_R_H,
      fpu_ss_instr_pkg::VFSGNJ_H,
      fpu_ss_instr_pkg::VFSGNJ_R_H,
      fpu_ss_instr_pkg::VFSGNJN_H,
      fpu_ss_instr_pkg::VFSGNJN_R_H,
      fpu_ss_instr_pkg::VFSGNJX_H,
      fpu_ss_instr_pkg::VFSGNJX_R_H,
      fpu_ss_instr_pkg::VFCPKA_H_S,
      fpu_ss_instr_pkg::VFCVT_S_H,
      fpu_ss_instr_pkg::VFCVTU_S_H,
      fpu_ss_instr_pkg::VFCVT_H_S,
      fpu_ss_instr_pkg::VFCVTU_H_S,
      fpu_ss_instr_pkg::VFDOTPEX_S_H,
      fpu_ss_instr_pkg::VFDOTPEX_S_R_H,
      fpu_ss_instr_pkg::VFNDOTPEX_S_H,
      fpu_ss_instr_pkg::VFNDOTPEX_S_R_H,
      fpu_ss_instr_pkg::VFSUMEX_S_H,
      fpu_ss_instr_pkg::VFNSUMEX_S_H,
      fpu_ss_instr_pkg::FADD_B,
      fpu_ss_instr_pkg::FSUB_B,
      fpu_ss_instr_pkg::FMUL_B,
      fpu_ss_instr_pkg::FSGNJ_B,
      fpu_ss_instr_pkg::FSGNJN_B,
      fpu_ss_instr_pkg::FSGNJX_B,
      fpu_ss_instr_pkg::FMIN_B,
      fpu_ss_instr_pkg::FMAX_B,
      fpu_ss_instr_pkg::FSQRT_B,
      fpu_ss_instr_pkg::FMADD_B,
      fpu_ss_instr_pkg::FMSUB_B,
      fpu_ss_instr_pkg::FNMSUB_B,
      fpu_ss_instr_pkg::FNMADD_B,
      fpu_ss_instr_pkg::VFSUM_B,
      fpu_ss_instr_pkg::VFNSUM_B,
      fpu_ss_instr_pkg::FMULEX_S_B,
      fpu_ss_instr_pkg::FMACEX_S_B,
      fpu_ss_instr_pkg::FCVT_S_B,
      fpu_ss_instr_pkg::FCVT_B_S,
      fpu_ss_instr_pkg::FCVT_H_B,
      fpu_ss_instr_pkg::FCVT_B_H,
      fpu_ss_instr_pkg::VFADD_B,
      fpu_ss_instr_pkg::VFADD_R_B,
      fpu_ss_instr_pkg::VFSUB_B,
      fpu_ss_instr_pkg::VFSUB_R_B,
      fpu_ss_instr_pkg::VFMUL_B,
      fpu_ss_instr_pkg::VFMUL_R_B,
      fpu_ss_instr_pkg::VFMIN_B,
      fpu_ss_instr_pkg::VFMIN_R_B,
      fpu_ss_instr_pkg::VFMAX_B,
      fpu_ss_instr_pkg::VFMAX_R_B,
      fpu_ss_instr_pkg::VFSQRT_B,
      fpu_ss_instr_pkg::VFMAC_B,
      fpu_ss_instr_pkg::VFMAC_R_B,
      fpu_ss_instr_pkg::VFMRE_B,
      fpu_ss_instr_pkg::VFMRE_R_B,
      fpu_ss_instr_pkg::VFSGNJ_B,
      fpu_ss_instr_pkg::VFSGNJ_R_B,
      fpu_ss_instr_pkg::VFSGNJN_B,
      fpu_ss_instr_pkg::VFSGNJN_R_B,
      fpu_ss_instr_pkg::VFSGNJX_B,
      fpu_ss_instr_pkg::VFSGNJX_R_B,
      fpu_ss_instr_pkg::VFCPKA_B_S,
      fpu_ss_instr_pkg::VFCPKB_B_S,
      fpu_ss_instr_pkg::VFCVT_S_B,
      fpu_ss_instr_pkg::VFCVTU_S_B,
      fpu_ss_instr_pkg::VFCVT_B_S,
      fpu_ss_instr_pkg::VFCVTU_B_S,
      fpu_ss_instr_pkg::VFCVT_H_H,
      fpu_ss_instr_pkg::VFCVTU_H_H,
      fpu_ss_instr_pkg::VFCVT_H_B,
      fpu_ss_instr_pkg::VFCVTU_H_B,
      fpu_ss_instr_pkg::VFCVT_B_H,
      fpu_ss_instr_pkg::VFCVTU_B_H,
      fpu_ss_instr_pkg::VFCVT_B_B,
      fpu_ss_instr_pkg::VFCVTU_B_B,
      fpu_ss_instr_pkg::VFDOTPEX_H_B,
      fpu_ss_instr_pkg::VFDOTPEX_H_R_B,
      fpu_ss_instr_pkg::VFNDOTPEX_H_B,
      fpu_ss_instr_pkg::VFNDOTPEX_H_R_B,
      fpu_ss_instr_pkg::VFSUMEX_H_B,
      fpu_ss_instr_pkg::VFNSUMEX_H_B: begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b0;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b000;
      end

      // fp to int
      fpu_ss_instr_pkg::FLE_S,
      fpu_ss_instr_pkg::FLT_S,
      fpu_ss_instr_pkg::FEQ_S,
      fpu_ss_instr_pkg::FCLASS_S,
      fpu_ss_instr_pkg::FCVT_W_S,
      fpu_ss_instr_pkg::FCVT_WU_S,
      fpu_ss_instr_pkg::FMV_X_W,
      fpu_ss_instr_pkg::VFEQ_S,
      fpu_ss_instr_pkg::VFEQ_R_S,
      fpu_ss_instr_pkg::VFNE_S,
      fpu_ss_instr_pkg::VFNE_R_S,
      fpu_ss_instr_pkg::VFLT_S,
      fpu_ss_instr_pkg::VFLT_R_S,
      fpu_ss_instr_pkg::VFGE_S,
      fpu_ss_instr_pkg::VFGE_R_S,
      fpu_ss_instr_pkg::VFLE_S,
      fpu_ss_instr_pkg::VFLE_R_S,
      fpu_ss_instr_pkg::VFGT_S,
      fpu_ss_instr_pkg::VFGT_R_S,
      fpu_ss_instr_pkg::VFCLASS_S,
      fpu_ss_instr_pkg::FLE_H,
      fpu_ss_instr_pkg::FLT_H,
      fpu_ss_instr_pkg::FEQ_H,
      fpu_ss_instr_pkg::FCLASS_H,
      fpu_ss_instr_pkg::FCVT_W_H,
      fpu_ss_instr_pkg::FCVT_WU_H,
      fpu_ss_instr_pkg::FMV_X_H,
      fpu_ss_instr_pkg::VFEQ_H,
      fpu_ss_instr_pkg::VFEQ_R_H,
      fpu_ss_instr_pkg::VFNE_H,
      fpu_ss_instr_pkg::VFNE_R_H,
      fpu_ss_instr_pkg::VFLT_H,
      fpu_ss_instr_pkg::VFLT_R_H,
      fpu_ss_instr_pkg::VFGE_H,
      fpu_ss_instr_pkg::VFGE_R_H,
      fpu_ss_instr_pkg::VFLE_H,
      fpu_ss_instr_pkg::VFLE_R_H,
      fpu_ss_instr_pkg::VFGT_H,
      fpu_ss_instr_pkg::VFGT_R_H,
      fpu_ss_instr_pkg::VFCLASS_H,
      fpu_ss_instr_pkg::VFMV_X_H,
      fpu_ss_instr_pkg::VFCVT_X_H,
      fpu_ss_instr_pkg::VFCVT_XU_H,
      fpu_ss_instr_pkg::FLE_B,
      fpu_ss_instr_pkg::FLT_B,
      fpu_ss_instr_pkg::FEQ_B,
      fpu_ss_instr_pkg::FCLASS_B,
      fpu_ss_instr_pkg::FCVT_W_B,
      fpu_ss_instr_pkg::FCVT_WU_B,
      fpu_ss_instr_pkg::FMV_X_B,
      fpu_ss_instr_pkg::VFEQ_B,
      fpu_ss_instr_pkg::VFEQ_R_B,
      fpu_ss_instr_pkg::VFNE_B,
      fpu_ss_instr_pkg::VFNE_R_B,
      fpu_ss_instr_pkg::VFLT_B,
      fpu_ss_instr_pkg::VFLT_R_B,
      fpu_ss_instr_pkg::VFGE_B,
      fpu_ss_instr_pkg::VFGE_R_B,
      fpu_ss_instr_pkg::VFLE_B,
      fpu_ss_instr_pkg::VFLE_R_B,
      fpu_ss_instr_pkg::VFGT_B,
      fpu_ss_instr_pkg::VFGT_R_B,
      fpu_ss_instr_pkg::VFCLASS_B,
      fpu_ss_instr_pkg::VFMV_X_B,
      fpu_ss_instr_pkg::VFCVT_X_B,
      fpu_ss_instr_pkg::VFCVT_XU_B,
      fpu_ss_instr_pkg::CSRRWI_FSRMI,
      fpu_ss_instr_pkg::CSRRWI_FSFLAGSI: begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b1;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b000;
      end

      // int to fp
      fpu_ss_instr_pkg::FMV_W_X,
      fpu_ss_instr_pkg::FCVT_S_W,
      fpu_ss_instr_pkg::FCVT_S_WU,
      fpu_ss_instr_pkg::FMV_H_X,
      fpu_ss_instr_pkg::FCVT_H_W,
      fpu_ss_instr_pkg::FCVT_H_WU,
      fpu_ss_instr_pkg::VFMV_H_X,
      fpu_ss_instr_pkg::VFCVT_H_X,
      fpu_ss_instr_pkg::VFCVT_H_XU,
      fpu_ss_instr_pkg::FMV_B_X,
      fpu_ss_instr_pkg::FCVT_B_W,
      fpu_ss_instr_pkg::FCVT_B_WU,
      fpu_ss_instr_pkg::VFMV_B_X,
      fpu_ss_instr_pkg::VFCVT_B_X,
      fpu_ss_instr_pkg::VFCVT_B_XU: begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b0;
        prd_rsp_o.p_is_mem_op = 1'b0;
        prd_rsp_o.p_use_rs    = 3'b001;
      end

      // memory instructions
      fpu_ss_instr_pkg::FLW,
      fpu_ss_instr_pkg::FSW,
      fpu_ss_instr_pkg::FLH,
      fpu_ss_instr_pkg::FSH,
      fpu_ss_instr_pkg::FLB,
      fpu_ss_instr_pkg::FSB:
      begin
        prd_rsp_o.p_accept    = 1'b1;
        prd_rsp_o.p_writeback = 1'b0;
        prd_rsp_o.p_is_mem_op = 1'b1;
        prd_rsp_o.p_use_rs    = 3'b001;
      end

      // csr instructions with writeback
      fpu_ss_instr_pkg::CSRRW_FSCSR,
      fpu_ss_instr_pkg::CSRRS_FRCSR,
      fpu_ss_instr_pkg::CSRRW_FSRM,
      fpu_ss_instr_pkg::CSRRS_FRRM,
      fpu_ss_instr_pkg::CSRRW_FSFLAGS,
      fpu_ss_instr_pkg::CSRRS_FRFLAGS: begin
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