`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/03/2019 12:12:17 PM
// Design Name:
// Module Name: main
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module main(
    input wire          sys_clk     ,
    input wire          uart_rx     ,
    output wire         uart_tx     ,
    output wire         sram_ce_bar ,
    output wire         sram_oe_bar ,
    output wire         sram_we_bar ,
    inout wire  [7:0]   sram_data   ,
    output wire [18:0]  sram_addr
);
    wire    clk,
            rstn;

    clk_wiz_0   clk_gen_inst(
        .clk_out(clk),      // output clk_out
        .locked(rstn),      // output locked
        .clk_in(sys_clk)    // input clk_in
    );

    (* mark_debug="true" *)
    wire            loopback_data_vld;
    (* mark_debug="true" *)
    wire    [7:0]   loopback_data;
    uart_transceiver uart_tr_inst(
        .clk       (clk),
        .rstn      (rstn),
        .rx        (uart_rx),
        .fetch_trig(loopback_data_vld),
        .fetch_data(loopback_data),
        .tx        (uart_tx),
        .buf_full  (),
        .send_req  (loopback_data_vld),
        .send_data (loopback_data),
        //
        .sram_ce_bar(sram_ce_bar),
        .sram_oe_bar(sram_oe_bar),
        .sram_we_bar(sram_we_bar),
        .sram_data  (sram_data  ),
        .sram_addr  (sram_addr  )
    );

endmodule
