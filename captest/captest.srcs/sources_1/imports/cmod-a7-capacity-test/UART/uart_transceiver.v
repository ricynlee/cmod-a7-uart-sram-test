`timescale 1ns / 1ps

/*
Encoding:ANSI

Date:2014 Oct 11
Author:Ricyn Lee
Description:UART收发模块
*/

module uart_transceiver(
    input wire          clk,
    input wire          rstn,
    
    // Rx
    input wire          rx,
    output wire         fetch_trig, // 正边沿有效,后级取数据fetch_data
    output wire [7:0]   fetch_data,
    
    // Tx
    output wire         tx,
    output wire         buf_full, // 高电平有效,有效时表示Tx FIFO满,不应继续发送
    input wire          send_req, // 高电平有效,有效时每个时钟采集数据send_data
    input wire  [7:0]   send_data,
    
    // SRAM physical
    output wire         sram_ce_bar ,
    output wire         sram_oe_bar ,
    output wire         sram_we_bar ,
    inout wire  [7:0]   sram_data   ,
    output wire [18:0]  sram_addr
);

    // Receiver
    uart_rx ur(
        .clk(clk),
        .rstn(rstn),
        .rx(rx),
        .fetch_trig(fetch_trig),
        .fetch_data(fetch_data)
    );

    // Transmitter
    reg             tx_trig; // uart_tx 发送数据触发
    wire    [7:0]   tx_data;
    wire            buf_empty, // FIFO 空
                    tx_bsy;
    
    // // 需要添加FIFO IP核,以Xilinx FIFO Generator 9.3为基准
    // // 使用First Word Fall Through类型FIFO
    // uart_tx_fifo uart_tx_fifo_inst( // First Word Fall Through FIFO
    //     .clk(clk), // input clk
    //     .srst(~rstn), // input rst, ASYNC
    //     .din(send_data), // input [7 : 0] din
    //     .wr_en(send_req), // input wr_en
    //     .rd_en(tx_trig), // input rd_en
    //     .dout(tx_data), // output [7 : 0] dout
    //     .full(buf_full), // output full
    //     .empty(buf_empty) // output empty
    // );
    fifo_by_sram uart_tx_fifo_inst(
        .clk(clk), // input clk
        .srst(~rstn), // input rst, ASYNC
        .din(send_data), // input [7 : 0] din
        .wr_en(send_req), // input wr_en
        .rd_en(tx_trig), // input rd_en
        .dout(tx_data), // output [7 : 0] dout
        .full(buf_full), // output full
        .empty(buf_empty), // output empty
        //
        .sram_ce_bar(sram_ce_bar),
        .sram_oe_bar(sram_oe_bar),
        .sram_we_bar(sram_we_bar),
        .sram_data  (sram_data  ),
        .sram_addr  (sram_addr  )
    );
    
    uart_tx ut(
        .clk(clk),
        .rstn(rstn),
        .tx(tx),
        .tx_bsy(tx_bsy),
        .send_trig(tx_trig),
        .send_data(tx_data)
    );
    
    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            tx_trig<=1'b0;
        end else begin
            tx_trig<=~(tx_trig|buf_empty|tx_bsy);
        end
    end
    
endmodule
