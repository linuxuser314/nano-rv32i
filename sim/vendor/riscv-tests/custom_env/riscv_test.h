/* /workspaces/nano-rv32i/sim/custom_env/riscv_test.h */
#ifndef _ENV_PHYSICAL_SINGLE_CORE_H
#define _ENV_PHYSICAL_SINGLE_CORE_H

#define TESTNUM gp

#define rvtest_rv32u                                    \
  .section .text.init;                                  \
  .globl _start;                                        \
  _start:                                               \
  li x1, 0; li x2, 0; li x3, 0; li x4, 0;               \
  li x5, 0; li x6, 0; li x7, 0; li x8, 0;               \
  li x9, 0; li x10, 0; li x11, 0; li x12, 0;            \
  li x13, 0; li x14, 0; li x15, 0; li x16, 0;           \
  li x17, 0; li x18, 0; li x19, 0; li x20, 0;           \
  li x21, 0; li x22, 0; li x23, 0; li x24, 0;           \
  li x25, 0; li x26, 0; li x27, 0; li x28, 0;           \
  li x29, 0; li x30, 0; li x31, 0;                      \

#define rvtest_code_begin                               \
  .text;                                                \

#define rvtest_code_end                                 \
  nop;                                                  \

#define rvtest_pass                                     \
  li t0, 0x80000000;                                    \
  li t1, 1;                                             \
  sw t1, 0(t0);                                         \
  1: j 1b;                                              \

#define rvtest_fail                                     \
  li t0, 0x80000000;                                    \
  slli t1, gp, 1;                                       \
  ori t1, t1, 1;                                        \
  sw t1, 0(t0);                                         \
  1: j 1b;                                              \

#define rvtest_data_begin .data
#define rvtest_data_end

/* Aliases for uppercase compatibility just in case */
#define RVTEST_RV32U       rvtest_rv32u
#define RVTEST_CODE_BEGIN  rvtest_code_begin
#define RVTEST_CODE_END    rvtest_code_end
#define RVTEST_PASS        rvtest_pass
#define RVTEST_FAIL        rvtest_fail
#define RVTEST_DATA_BEGIN  rvtest_data_begin
#define RVTEST_DATA_END    rvtest_data_end

#endif