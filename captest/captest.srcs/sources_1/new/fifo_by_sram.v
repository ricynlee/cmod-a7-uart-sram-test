`timescale 1ns / 1ps

// this is a synchronous first-word-fall-through fifo
module fifo_by_sram(
    input wire          clk         , // 100MHz
    input wire          srst        , // async
    input wire  [7:0]   din         ,
    input wire          wr_en       ,
    output reg  [7:0]   dout        ,
    input wire          rd_en       ,
    output reg          full  = 1'b0,
    output reg          empty = 1'b1,
    output wire         sram_ce_bar ,
    output wire         sram_oe_bar ,
    output wire         sram_we_bar ,
    inout wire  [7:0]   sram_data   ,
    output wire [18:0]  sram_addr
);
    // does not support consecutive r/w accesses
    reg prev_wr_en = 1'b0, prev_rd_en = 1'b0;
    always@(posedge clk, posedge srst)begin
        if(srst)begin
            prev_wr_en <= 1'b0;
            prev_rd_en <= 1'b0;
        end else begin
            prev_wr_en <= wr_en;
            prev_rd_en <= rd_en;
        end
    end

    wire    wr_en_pulse = (~prev_wr_en) & wr_en;
    wire    rd_en_pulse = (~prev_rd_en) & rd_en;

    // cached write access
    reg         wr_en_pulse_cached = 1'b0;
    reg [7:0]   din_cached;

    always@(posedge clk, posedge srst)begin
        if(srst)begin
            wr_en_pulse_cached <= 1'b0;
        end else if(wr_en_pulse & rd_en_pulse)begin
            wr_en_pulse_cached <= 1'b1;
            din_cached <= din;
        end else begin
            wr_en_pulse_cached <= 1'b0;
        end
    end

    // insts
    reg     [18:0]  sram_ui_addr;
    reg     [7:0]   sram_ui_wr_data;
    wire    [7:0]   sram_ui_rd_data;
    wire            sram_ui_rd_vld;
    reg             sram_ui_req = 1'b0;
    reg             sram_ui_wrrd_bar;
    sram_controller_full_speed sram_controller_full_speed_inst(
        .sys_clk    (clk), // 100MHz
        .sys_rst    (srst), // async
        .req        (sram_ui_req),
        .wrrd_bar   (sram_ui_wrrd_bar),
        .addr       (sram_ui_addr),
        .wr_data    (sram_ui_wr_data),
        .rd_data    (sram_ui_rd_data),
        .rd_vld     (sram_ui_rd_vld),
        .sram_ce_bar(sram_ce_bar),
        .sram_oe_bar(sram_oe_bar),
        .sram_we_bar(sram_we_bar),
        .sram_data  (sram_data  ),
        .sram_addr  (sram_addr  )
    );

    // cyclic queue (fifo control)
    reg [18:0]  wr_ptr = 0,
                rd_ptr = 0;
    always@(posedge clk, posedge srst)begin
        if(srst)begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 1'b0;
            empty <= 1'b1;
            sram_ui_req <= 1'b0;
        end else begin
            sram_ui_wrrd_bar <= ~rd_en_pulse;

            if(!empty && rd_en_pulse)begin
                rd_ptr <= rd_ptr+1;
                sram_ui_req <= 1'b1;
                sram_ui_addr <= rd_ptr+1;
                if(rd_ptr+1 == wr_ptr)begin
                    empty <= 1'b1;
                end
                full <= 1'b0;
            end else if(!full && wr_en_pulse)begin
                wr_ptr <= wr_ptr+1;
                sram_ui_req <= 1'b1;
                sram_ui_addr <= wr_ptr;
                sram_ui_wr_data <= din;
                if(empty)begin
                    dout <= din;
                end
                if(wr_ptr+1 == rd_ptr)begin
                    full <= 1'b1;
                end
                empty <= 1'b0;
            end else if(!full && wr_en_pulse_cached)begin
                wr_ptr <= wr_ptr+1;
                sram_ui_req <= 1'b1;
                sram_ui_addr <= wr_ptr;
                sram_ui_wr_data <= din_cached;
                if(empty)begin
                    dout <= din_cached;
                end
                if(wr_ptr+1 == rd_ptr)begin
                    full <= 1'b1;
                end
                empty <= 1'b0;
            end
            if(sram_ui_rd_vld)begin
                dout <= sram_ui_rd_data;
            end
        end
    end

endmodule
