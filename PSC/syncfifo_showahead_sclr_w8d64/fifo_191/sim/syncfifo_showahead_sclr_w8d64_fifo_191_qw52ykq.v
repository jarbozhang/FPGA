// (C) 2001-2019 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  syncfifo_showahead_sclr_w8d64_fifo_191_qw52ykq  (
    clock,
    data,
    rdreq,
    sclr,
    wrreq,
    almost_empty,
    empty,
    full,
    q,
    usedw);

    input    clock;
    input  [7:0]  data;
    input    rdreq;
    input    sclr;
    input    wrreq;
    output   almost_empty;
    output   empty;
    output   full;
    output [7:0]  q;
    output [5:0]  usedw;

    wire  sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [7:0] sub_wire3;
    wire [5:0] sub_wire4;
    wire  almost_empty = sub_wire0;
    wire  empty = sub_wire1;
    wire  full = sub_wire2;
    wire [7:0] q = sub_wire3[7:0];
    wire [5:0] usedw = sub_wire4[5:0];

    scfifo  scfifo_component (
                .clock (clock),
                .data (data),
                .rdreq (rdreq),
                .sclr (sclr),
                .wrreq (wrreq),
                .almost_empty (sub_wire0),
                .empty (sub_wire1),
                .full (sub_wire2),
                .q (sub_wire3),
                .usedw (sub_wire4),
                .aclr (),
                .almost_full (),
                .eccstatus ());
    defparam
        scfifo_component.add_ram_output_register  = "OFF",
        scfifo_component.almost_empty_value  = 2,
        scfifo_component.enable_ecc  = "FALSE",
        scfifo_component.intended_device_family  = "Arria 10",
        scfifo_component.lpm_numwords  = 64,
        scfifo_component.lpm_showahead  = "ON",
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_width  = 8,
        scfifo_component.lpm_widthu  = 6,
        scfifo_component.overflow_checking  = "ON",
        scfifo_component.underflow_checking  = "ON",
        scfifo_component.use_eab  = "ON";


endmodule


