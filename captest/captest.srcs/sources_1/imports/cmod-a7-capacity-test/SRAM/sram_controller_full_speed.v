// ISSI SRAM -10ns speed grade

module sram_controller_full_speed(
    input wire          sys_clk, // 100MHz
    input wire          sys_rst, // async

    // user interface            
    input wire          req,
    input wire          wrrd_bar,

    input wire  [18:0]  addr,
    input wire  [7:0]   wr_data,
    output reg  [7:0]   rd_data,
    output reg          rd_vld = 1'b0,
    
    // peripheral interface
    output wire         sram_ce_bar,
    output reg          sram_oe_bar = 1'b0,
    output reg          sram_we_bar = 1'b1,
    inout wire  [7:0]   sram_data,
    output reg  [18:0]  sram_addr
);

    reg  [7:0]  wr_sram_data;
    wire [7:0]  rd_sram_data;
    assign  sram_data = sram_oe_bar ? wr_sram_data : 8'hzz;
    assign  rd_sram_data = sram_oe_bar ? 8'h00 : sram_data;
    
    reg prev_req_is_rd = 1'b0;
    
    always@(posedge sys_clk, posedge sys_rst)begin
        if(sys_rst)begin
            sram_we_bar <= 1'b1;
            sram_oe_bar <= 1'b0;
            rd_vld <= 1'b0;
            prev_req_is_rd <= 1'b0;
        end else begin
            if(req)begin
                sram_addr <= addr;
                sram_oe_bar <= wrrd_bar;
                sram_we_bar <= ~wrrd_bar;
                wr_sram_data <= wr_data;
            end else begin
                sram_oe_bar <= 1'b0;
                sram_we_bar <= 1'b1;
            end
            
            if (req & ~wrrd_bar)begin
                prev_req_is_rd <= 1'b1;
            end else begin
                prev_req_is_rd <= 1'b0;
            end
            
            if (prev_req_is_rd)begin
                rd_vld <= 1'b1;
                rd_data <= rd_sram_data;
            end else begin
                rd_vld <= 1'b0;
            end
        end
    end

    assign sram_ce_bar = 1'b0;
    
endmodule
