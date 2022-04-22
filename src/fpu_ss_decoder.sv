// Copyright 2022 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// FPU Subsystem Decoder
// Contributor: Moritz Imfeld <moimfeld@student.ethz.ch>
// Based on: https://github.com/pulp-platform/snitch/blob/master/hw/ip/snitch_cluster/src/snitch_fp_ss.sv

module fpu_ss_decoder #(
    parameter PULP_ZFINX = 0
) (
    input  logic                   [31:0] instr_i,
    input  fpnew_pkg::roundmode_e         fpu_rnd_mode_i,
    input  fpnew_pkg::fmt_mode_t          fpu_fmt_mode,
    output fpnew_pkg::operation_e         fpu_op_o,
    output fpu_ss_pkg::op_select_e [ 2:0] op_select_o,
    output fpnew_pkg::roundmode_e         fpu_rnd_mode_o,
    output logic                          set_dyn_rm_o,
    output fpnew_pkg::fp_format_e         src_fmt_o,
    output fpnew_pkg::fp_format_e         dst_fmt_o,
    output fpnew_pkg::int_format_e        int_fmt_o,
    output logic                          rd_is_fp_o,
    output logic                          vectorial_op_o,
    output logic                          op_mode_o,
    output logic                          use_fpu_o,
    output logic                          is_store_o,
    output logic                          is_load_o,
    output fpu_ss_pkg::ls_size_e          ls_size_o
);
  logic rd_is_fp_dec;

  assign rd_is_fp_o = PULP_ZFINX ? 1'b0 : rd_is_fp_dec;
  assign fpu_fmt_mode = {1'b0, 1'b0};

  always_comb begin

    fpu_op_o = fpnew_pkg::ADD;
    use_fpu_o = 1'b1;
    fpu_rnd_mode_o = (fpnew_pkg::roundmode_e'(instr_i[14:12]) == fpnew_pkg::DYN)
                   ? fpu_rnd_mode_i
                   : fpnew_pkg::roundmode_e'(instr_i[14:12]);

    set_dyn_rm_o = 1'b0;

    src_fmt_o = fpnew_pkg::FP32;
    dst_fmt_o = fpnew_pkg::FP32;
    int_fmt_o = fpnew_pkg::INT32;

    op_select_o[0] = fpu_ss_pkg::None;
    op_select_o[1] = fpu_ss_pkg::None;
    op_select_o[2] = fpu_ss_pkg::None;

    vectorial_op_o = 1'b0;
    op_mode_o = 1'b0;

    is_store_o = 1'b0;
    is_load_o = 1'b0;
    ls_size_o = fpu_ss_pkg::Word;

    // Destination register is in FPR
    rd_is_fp_dec = 1'b1;

    unique casez (instr_i)
      // FP - FP Operations
      // Single Precision
      fpu_ss_instr_pkg::FADD_S: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
      end
      fpu_ss_instr_pkg::FSUB_S: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::FMUL_S: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
      end
      fpu_ss_instr_pkg::FDIV_S: begin  // currently illegal
        fpu_op_o = fpnew_pkg::DIV;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
      end
      fpu_ss_instr_pkg::FSGNJ_S,
      fpu_ss_instr_pkg::FSGNJN_S,
      fpu_ss_instr_pkg::FSGNJX_S: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
      end
      fpu_ss_instr_pkg::FMIN_S,
      fpu_ss_instr_pkg::FMAX_S: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
      end
      fpu_ss_instr_pkg::FSQRT_S: begin  // currently illegal
        fpu_op_o = fpnew_pkg::SQRT;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegA;
      end
      fpu_ss_instr_pkg::FMADD_S: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
      end
      fpu_ss_instr_pkg::FMSUB_S: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        op_mode_o      = 1'b1;
      end
      fpu_ss_instr_pkg::FNMSUB_S: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
      end
      fpu_ss_instr_pkg::FNMADD_S: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        op_mode_o      = 1'b1;
      end
      // Vectorial Single Precision
      fpu_ss_instr_pkg::VFADD_S,
      fpu_ss_instr_pkg::VFADD_R_S: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFADD_R_S}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSUB_S,
      fpu_ss_instr_pkg::VFSUB_R_S: begin
        fpu_op_o  = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        op_mode_o      = 1'b1;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSUB_R_S}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMUL_S,
      fpu_ss_instr_pkg::VFMUL_R_S: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMUL_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFDIV_S,
      fpu_ss_instr_pkg::VFDIV_R_S: begin  // currently illegal
        fpu_op_o = fpnew_pkg::DIV;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFDIV_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMIN_S,
      fpu_ss_instr_pkg::VFMIN_R_S: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RNE;
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMIN_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMAX_S,
      fpu_ss_instr_pkg::VFMAX_R_S: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RTZ;
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMAX_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSQRT_S: begin // currently illegal
        fpu_op_o = fpnew_pkg::SQRT;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegA;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
      end
      fpu_ss_instr_pkg::VFMAC_S,
      fpu_ss_instr_pkg::VFMAC_R_S: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMAC_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMRE_S,
      fpu_ss_instr_pkg::VFMRE_R_S: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMRE_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJ_S,
      fpu_ss_instr_pkg::VFSGNJ_R_S: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RNE;
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJ_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJN_S,
      fpu_ss_instr_pkg::VFSGNJN_R_S: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RTZ;
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJN_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJX_S,
      fpu_ss_instr_pkg::VFSGNJX_R_S: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RDN;
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJX_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSUM_S,
      fpu_ss_instr_pkg::VFNSUM_S: begin
        fpu_op_o = fpnew_pkg::VSUM;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP32;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFNSUM_S}) op_mode_o = 1'b1;
      end
      // [Alternate] Half Precision
      fpu_ss_instr_pkg::FADD_H: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FSUB_H: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        op_mode_o = 1'b1;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FMUL_H: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FSGNJ_H,
      fpu_ss_instr_pkg::FSGNJN_H,
      fpu_ss_instr_pkg::FSGNJX_H: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FMIN_H,
      fpu_ss_instr_pkg::FMAX_H: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FSQRT_H: begin
        fpu_op_o = fpnew_pkg::SQRT;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegA;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FMADD_H: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FMSUB_H: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FNMSUB_H: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FNMADD_H: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::VFSUM_H,
      fpu_ss_instr_pkg::VFNSUM_H: begin
        fpu_op_o = fpnew_pkg::VSUM;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFNSUM_H}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::FMULEX_S_H: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP32;
      end
      fpu_ss_instr_pkg::FMACEX_S_H: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP32;
      end
      fpu_ss_instr_pkg::FCVT_S_H: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP32;
      end
      fpu_ss_instr_pkg::FCVT_H_S: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP16;
      end
      fpu_ss_instr_pkg::FCVT_H_H: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
      end
      // Vectorial [alternate] Half Precision
      fpu_ss_instr_pkg::VFADD_H,
      fpu_ss_instr_pkg::VFADD_R_H: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFADD_R_H}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSUB_H,
      fpu_ss_instr_pkg::VFSUB_R_H: begin
        fpu_op_o  = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSUB_R_H}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMUL_H,
      fpu_ss_instr_pkg::VFMUL_R_H: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMUL_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMIN_H,
      fpu_ss_instr_pkg::VFMIN_R_H: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RNE;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMIN_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMAX_H,
      fpu_ss_instr_pkg::VFMAX_R_H: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        fpu_rnd_mode_o = fpnew_pkg::RTZ;
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMAX_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSQRT_H: begin
        fpu_op_o = fpnew_pkg::SQRT;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegA;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
      end
      fpu_ss_instr_pkg::VFMAC_H,
      fpu_ss_instr_pkg::VFMAC_R_H: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMAC_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMRE_H,
      fpu_ss_instr_pkg::VFMRE_R_H: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMRE_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJ_H,
      fpu_ss_instr_pkg::VFSGNJ_R_H: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RNE;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJ_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJN_H,
      fpu_ss_instr_pkg::VFSGNJN_R_H: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RTZ;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJN_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJX_H,
      fpu_ss_instr_pkg::VFSGNJX_R_H: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RDN;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJX_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFCPKA_H_S: begin
        fpu_op_o = fpnew_pkg::CPKAB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_S_H,
      fpu_ss_instr_pkg::VFCVTU_S_H: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP32;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_S_H}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_H_S,
      fpu_ss_instr_pkg::VFCVTU_H_S: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_H_S}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFDOTPEX_S_H,
      fpu_ss_instr_pkg::VFDOTPEX_S_R_H: begin
        fpu_op_o = fpnew_pkg::SDOTP;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP32;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFDOTPEX_S_R_H}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFNDOTPEX_S_H,
      fpu_ss_instr_pkg::VFNDOTPEX_S_R_H: begin
        fpu_op_o = fpnew_pkg::SDOTP;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP32;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFNDOTPEX_S_R_H}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSUMEX_S_H,
      fpu_ss_instr_pkg::VFNSUMEX_S_H: begin
        fpu_op_o = fpnew_pkg::EXVSUM;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP32;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFNSUMEX_S_H}) op_mode_o = 1'b1;
      end
      // [Alternate] Quarter Precision
      fpu_ss_instr_pkg::FADD_B: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FSUB_B: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        op_mode_o = 1'b1;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FMUL_B: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FSGNJ_B,
      fpu_ss_instr_pkg::FSGNJN_B,
      fpu_ss_instr_pkg::FSGNJX_B: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FMIN_B,
      fpu_ss_instr_pkg::FMAX_B: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FSQRT_B: begin
        fpu_op_o = fpnew_pkg::SQRT;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegA;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FMADD_B: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FMSUB_B: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FNMSUB_B: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FNMADD_B: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegC;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::VFSUM_B,
      fpu_ss_instr_pkg::VFNSUM_B: begin
        fpu_op_o = fpnew_pkg::VSUM;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFNSUM_B}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::FMULEX_S_B: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP32;
      end
      fpu_ss_instr_pkg::FMACEX_S_B: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP32;
      end
      fpu_ss_instr_pkg::FCVT_S_B: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP32;
      end
      fpu_ss_instr_pkg::FCVT_B_S: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP8;
      end
      fpu_ss_instr_pkg::FCVT_H_B: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP16;
      end
      fpu_ss_instr_pkg::FCVT_B_H: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP8;
      end
      // Vectorial [alternate] Quarter Precision
      fpu_ss_instr_pkg::VFADD_B,
      fpu_ss_instr_pkg::VFADD_R_B: begin
        fpu_op_o = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFADD_R_B}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSUB_B,
      fpu_ss_instr_pkg::VFSUB_R_B: begin
        fpu_op_o  = fpnew_pkg::ADD;
        op_select_o[1] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegB;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSUB_R_B}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMUL_B,
      fpu_ss_instr_pkg::VFMUL_R_B: begin
        fpu_op_o = fpnew_pkg::MUL;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMUL_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMIN_B,
      fpu_ss_instr_pkg::VFMIN_R_B: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RNE;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMIN_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMAX_B,
      fpu_ss_instr_pkg::VFMAX_R_B: begin
        fpu_op_o = fpnew_pkg::MINMAX;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        fpu_rnd_mode_o = fpnew_pkg::RTZ;
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMAX_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSQRT_B: begin
        fpu_op_o = fpnew_pkg::SQRT;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegA;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
      end
      fpu_ss_instr_pkg::VFMAC_B,
      fpu_ss_instr_pkg::VFMAC_R_B: begin
        fpu_op_o = fpnew_pkg::FMADD;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMAC_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFMRE_B,
      fpu_ss_instr_pkg::VFMRE_R_B: begin
        fpu_op_o = fpnew_pkg::FNMSUB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFMRE_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJ_B,
      fpu_ss_instr_pkg::VFSGNJ_R_B: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RNE;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJ_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJN_B,
      fpu_ss_instr_pkg::VFSGNJN_R_B: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RTZ;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJN_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSGNJX_B,
      fpu_ss_instr_pkg::VFSGNJX_R_B: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o = fpnew_pkg::RDN;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFSGNJX_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFCPKA_B_S,
      fpu_ss_instr_pkg::VFCPKB_B_S: begin
        fpu_op_o = fpnew_pkg::CPKAB;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP8;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCPKB_B_S}) op_mode_o = 1;
      end
      fpu_ss_instr_pkg::VFCVT_S_B,
      fpu_ss_instr_pkg::VFCVTU_S_B: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP32;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_S_B}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_B_S,
      fpu_ss_instr_pkg::VFCVTU_B_S: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP8;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_B_S}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_H_H,
      fpu_ss_instr_pkg::VFCVTU_H_H: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_H_H}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_H_B,
      fpu_ss_instr_pkg::VFCVTU_H_B: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_H_B}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_B_H,
      fpu_ss_instr_pkg::VFCVTU_B_H: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP8;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_B_H}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_B_B,
      fpu_ss_instr_pkg::VFCVTU_B_B: begin
        fpu_op_o = fpnew_pkg::F2F;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVTU_B_B}) op_mode_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFDOTPEX_H_B,
      fpu_ss_instr_pkg::VFDOTPEX_H_R_B: begin
        fpu_op_o = fpnew_pkg::SDOTP;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFDOTPEX_H_R_B}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFNDOTPEX_H_B,
      fpu_ss_instr_pkg::VFNDOTPEX_H_R_B: begin
        fpu_op_o = fpnew_pkg::SDOTP;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[1] = fpu_ss_pkg::RegB;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        op_mode_o      = 1'b1;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFNDOTPEX_H_R_B}) op_select_o[2] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFSUMEX_H_B,
      fpu_ss_instr_pkg::VFNSUMEX_H_B: begin
        fpu_op_o = fpnew_pkg::EXVSUM;
        op_select_o[0] = fpu_ss_pkg::RegA;
        op_select_o[2] = fpu_ss_pkg::RegDest;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFNSUMEX_H_B}) op_mode_o = 1'b1;
      end
      // -------------------
      // From float to int
      // -------------------
      // Single Precision Floating-Point
      fpu_ss_instr_pkg::FLE_S,
      fpu_ss_instr_pkg::FLT_S,
      fpu_ss_instr_pkg::FEQ_S: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::FCLASS_S: begin
        fpu_op_o = fpnew_pkg::CLASSIFY;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::FCVT_W_S,
      fpu_ss_instr_pkg::FCVT_WU_S: begin
        fpu_op_o = fpnew_pkg::F2I;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::FCVT_WU_S}) op_mode_o = 1'b1; // unsigned
      end
      fpu_ss_instr_pkg::FMV_X_W: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        fpu_rnd_mode_o   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        op_mode_o        = 1'b1; // sign-extend result
        op_select_o[0]   = fpu_ss_pkg::RegA;
        rd_is_fp_dec       = 1'b0;
      end
      // Vectorial Single Precision
      fpu_ss_instr_pkg::VFEQ_S,
      fpu_ss_instr_pkg::VFEQ_R_S: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RDN;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFEQ_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFNE_S,
      fpu_ss_instr_pkg::VFNE_R_S: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RDN;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFNE_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFLT_S,
      fpu_ss_instr_pkg::VFLT_R_S: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RTZ;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFLT_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFGE_S,
      fpu_ss_instr_pkg::VFGE_R_S: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RTZ;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFGE_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFLE_S,
      fpu_ss_instr_pkg::VFLE_R_S: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFLE_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFGT_S,
      fpu_ss_instr_pkg::VFGT_R_S: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFGT_R_S}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFCLASS_S: begin
        fpu_op_o = fpnew_pkg::CLASSIFY;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP32;
        dst_fmt_o        = fpnew_pkg::FP32;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
      end
      // [Alternate] Half Precision Floating-Point
      fpu_ss_instr_pkg::FLE_H,
      fpu_ss_instr_pkg::FLT_H,
      fpu_ss_instr_pkg::FEQ_H: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::FCLASS_H: begin
        fpu_op_o = fpnew_pkg::CLASSIFY;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::FCVT_W_H,
      fpu_ss_instr_pkg::FCVT_WU_H: begin
        fpu_op_o = fpnew_pkg::F2I;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::FCVT_WU_H}) op_mode_o = 1'b1; // unsigned
      end
      fpu_ss_instr_pkg::FMV_X_H: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        fpu_rnd_mode_o   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        op_mode_o        = 1'b1; // sign-extend result
        op_select_o[0]   = fpu_ss_pkg::RegA;
        rd_is_fp_dec       = 1'b0;
      end
      // Vectorial [alternate] Half Precision
      fpu_ss_instr_pkg::VFEQ_H,
      fpu_ss_instr_pkg::VFEQ_R_H: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RDN;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFEQ_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFNE_H,
      fpu_ss_instr_pkg::VFNE_R_H: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RDN;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFNE_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFLT_H,
      fpu_ss_instr_pkg::VFLT_R_H: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RTZ;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFLT_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFGE_H,
      fpu_ss_instr_pkg::VFGE_R_H: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RTZ;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFGE_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFLE_H,
      fpu_ss_instr_pkg::VFLE_R_H: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFLE_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFGT_H,
      fpu_ss_instr_pkg::VFGT_R_H: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFGT_R_H}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFCLASS_H: begin
        fpu_op_o = fpnew_pkg::CLASSIFY;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::VFMV_X_H: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        fpu_rnd_mode_o   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        op_mode_o        = 1'b1; // sign-extend result
        op_select_o[0]   = fpu_ss_pkg::RegA;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::VFCVT_X_H,
      fpu_ss_instr_pkg::VFCVT_XU_H: begin
        fpu_op_o = fpnew_pkg::F2I;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        src_fmt_o        = fpnew_pkg::FP16;
        dst_fmt_o        = fpnew_pkg::FP16;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP16ALT;
          dst_fmt_o      = fpnew_pkg::FP16ALT;
        end
        int_fmt_o        = fpnew_pkg::INT16;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        set_dyn_rm_o     = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVT_XU_H}) op_mode_o = 1'b1; // upper
      end
      // [Alternate] Quarter Precision Floating-Point
      fpu_ss_instr_pkg::FLE_B,
      fpu_ss_instr_pkg::FLT_B,
      fpu_ss_instr_pkg::FEQ_B: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::FCLASS_B: begin
        fpu_op_o = fpnew_pkg::CLASSIFY;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::FCVT_W_B,
      fpu_ss_instr_pkg::FCVT_WU_B: begin
        fpu_op_o = fpnew_pkg::F2I;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::FCVT_WU_B}) op_mode_o = 1'b1; // unsigned
      end
      fpu_ss_instr_pkg::FMV_X_B: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        fpu_rnd_mode_o   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        op_mode_o        = 1'b1; // sign-extend result
        op_select_o[0]   = fpu_ss_pkg::RegA;
        rd_is_fp_dec       = 1'b0;
      end
      // Vectorial Quarter Precision
      fpu_ss_instr_pkg::VFEQ_B,
      fpu_ss_instr_pkg::VFEQ_R_B: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RDN;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFEQ_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFNE_B,
      fpu_ss_instr_pkg::VFNE_R_B: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RDN;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFNE_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFLT_B,
      fpu_ss_instr_pkg::VFLT_R_B: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RTZ;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFLT_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFGE_B,
      fpu_ss_instr_pkg::VFGE_R_B: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RTZ;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFGE_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFLE_B,
      fpu_ss_instr_pkg::VFLE_R_B: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFLE_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFGT_B,
      fpu_ss_instr_pkg::VFGT_R_B: begin
        fpu_op_o = fpnew_pkg::CMP;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        op_select_o[1]   = fpu_ss_pkg::RegB;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        op_mode_o        = 1'b1;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        if (instr_i inside {fpu_ss_instr_pkg::VFGT_R_B}) op_select_o[1] = fpu_ss_pkg::RegBRep;
      end
      fpu_ss_instr_pkg::VFCLASS_B: begin
        fpu_op_o = fpnew_pkg::CLASSIFY;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        fpu_rnd_mode_o   = fpnew_pkg::RNE;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::VFMV_X_B: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        fpu_rnd_mode_o   = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        op_mode_o        = 1'b1; // sign-extend result
        op_select_o[0]   = fpu_ss_pkg::RegA;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
      end
      fpu_ss_instr_pkg::VFCVT_X_B,
      fpu_ss_instr_pkg::VFCVT_XU_B: begin
        fpu_op_o = fpnew_pkg::F2I;
        op_select_o[0]   = fpu_ss_pkg::RegA;
        src_fmt_o        = fpnew_pkg::FP8;
        dst_fmt_o        = fpnew_pkg::FP8;
        if (fpu_fmt_mode.src == 1'b1) begin
          src_fmt_o      = fpnew_pkg::FP8ALT;
          dst_fmt_o      = fpnew_pkg::FP8ALT;
        end
        int_fmt_o        = fpnew_pkg::INT8;
        vectorial_op_o   = 1'b1;
        rd_is_fp_dec       = 1'b0;
        set_dyn_rm_o     = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVT_XU_B}) op_mode_o = 1'b1; // upper
      end
      // -------------------
      // From int to float
      // -------------------
      // Single Precision Floating-Point
      fpu_ss_instr_pkg::FMV_W_X: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        fpu_rnd_mode_o = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o      = fpnew_pkg::FP32;
        dst_fmt_o      = fpnew_pkg::FP32;
      end
      fpu_ss_instr_pkg::FCVT_S_W,
      fpu_ss_instr_pkg::FCVT_S_WU: begin
        fpu_op_o = fpnew_pkg::I2F;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        dst_fmt_o      = fpnew_pkg::FP32;
        if (instr_i inside {fpu_ss_instr_pkg::FCVT_S_WU}) op_mode_o = 1'b1; // unsigned
      end
      // [Alternate] Half Precision Floating-Point
      fpu_ss_instr_pkg::FMV_H_X: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        fpu_rnd_mode_o = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
      end
      fpu_ss_instr_pkg::FCVT_H_W,
      fpu_ss_instr_pkg::FCVT_H_WU: begin
        fpu_op_o = fpnew_pkg::I2F;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        if (instr_i inside {fpu_ss_instr_pkg::FCVT_H_WU}) op_mode_o = 1'b1; // unsigned
      end
      // Vectorial Half Precision Floating-Point
      fpu_ss_instr_pkg::VFMV_H_X: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        fpu_rnd_mode_o = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        vectorial_op_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_H_X,
      fpu_ss_instr_pkg::VFCVT_H_XU: begin
        fpu_op_o = fpnew_pkg::I2F;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        src_fmt_o      = fpnew_pkg::FP16;
        dst_fmt_o      = fpnew_pkg::FP16;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP16ALT;
          dst_fmt_o    = fpnew_pkg::FP16ALT;
        end
        int_fmt_o      = fpnew_pkg::INT16;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVT_H_XU}) op_mode_o = 1'b1; // upper
      end
      // [Alternate] Quarter Precision Floating-Point
      fpu_ss_instr_pkg::FMV_B_X: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        fpu_rnd_mode_o = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (fpu_fmt_mode.dst == 1'b1) begin
          src_fmt_o    = fpnew_pkg::FP8ALT;
          dst_fmt_o    = fpnew_pkg::FP8ALT;
        end
      end
      fpu_ss_instr_pkg::FCVT_B_W,
      fpu_ss_instr_pkg::FCVT_B_WU: begin
        fpu_op_o = fpnew_pkg::I2F;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        if (instr_i inside {fpu_ss_instr_pkg::FCVT_B_WU}) op_mode_o = 1'b1; // unsigned
      end
      // Vectorial Quarter Precision Floating-Point
      fpu_ss_instr_pkg::VFMV_B_X: begin
        fpu_op_o = fpnew_pkg::SGNJ;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        fpu_rnd_mode_o = fpnew_pkg::RUP; // passthrough without checking nan-box
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        vectorial_op_o = 1'b1;
      end
      fpu_ss_instr_pkg::VFCVT_B_X,
      fpu_ss_instr_pkg::VFCVT_B_XU: begin
        fpu_op_o = fpnew_pkg::I2F;
        op_select_o[0] = fpu_ss_pkg::AccBus;
        src_fmt_o      = fpnew_pkg::FP8;
        dst_fmt_o      = fpnew_pkg::FP8;
        int_fmt_o      = fpnew_pkg::INT8;
        vectorial_op_o = 1'b1;
        set_dyn_rm_o   = 1'b1;
        if (instr_i inside {fpu_ss_instr_pkg::VFCVT_B_XU}) op_mode_o = 1'b1; // upper
      end
      // -------------
      // Load / Store
      // -------------
      // Single Precision Floating-Point
      fpu_ss_instr_pkg::FLW: begin
        is_load_o = 1'b1;
        use_fpu_o = 1'b0;
      end
      fpu_ss_instr_pkg::FSW: begin
        is_store_o = 1'b1;
        op_select_o[1] = fpu_ss_pkg::RegB;
        use_fpu_o = 1'b0;
        rd_is_fp_dec = 1'b0;
      end
      // [Alternate] Half Precision Floating-Point
      fpu_ss_instr_pkg::FLH: begin
        is_load_o = 1'b1;
        ls_size_o = fpu_ss_pkg::HalfWord;
        use_fpu_o = 1'b0;
      end
      fpu_ss_instr_pkg::FSH: begin
        is_store_o = 1'b1;
        op_select_o[1] = fpu_ss_pkg::RegB;
        ls_size_o = fpu_ss_pkg::HalfWord;
        use_fpu_o = 1'b0;
        rd_is_fp_dec = 1'b0;
      end
      // [Alternate] Quarter Precision Floating-Point
      fpu_ss_instr_pkg::FLB: begin
        is_load_o = 1'b1;
        ls_size_o = fpu_ss_pkg::Byte;
        use_fpu_o = 1'b0;
      end
      fpu_ss_instr_pkg::FSB: begin
        is_store_o = 1'b1;
        op_select_o[1] = fpu_ss_pkg::RegB;
        ls_size_o = fpu_ss_pkg::Byte;
        use_fpu_o = 1'b0;
        rd_is_fp_dec = 1'b0;
      end
      default: begin
        use_fpu_o = 1'b0;
        rd_is_fp_dec = 1'b0;
      end
    endcase
    // fix round mode for vectors and fp16alt
    if (set_dyn_rm_o) fpu_rnd_mode_o = fpu_rnd_mode_i;
  end
endmodule // fpu_ss_decoder
