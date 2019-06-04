/*
 *  - UART发送模块 -
 *
 * 无奇偶校验位,8数据位,1停止位
 *
 */

// 注:参数可用代码结尾的MATLAB或Python程序生成

module uart_tx #(
    parameter   SYSCLOCK=100000000, // <Hz>
    parameter   BAUDRATE=12000000,
    parameter   CLKPERFRM=16'd84, // ceil(SYSCLOCK/BAUDRATE*10)
    // bit order is lsb-msb
    parameter   TBITAT=16'd1, // starT bit, round(SYSCLOCK/BAUDRATE*0)+1
    parameter   BIT0AT=16'd9, // round(SYSCLOCK/BAUDRATE*1)+1
    parameter   BIT1AT=16'd18, // round(SYSCLOCK/BAUDRATE*2)+1
    parameter   BIT2AT=16'd26, // round(SYSCLOCK/BAUDRATE*3)+1
    parameter   BIT3AT=16'd34, // round(SYSCLOCK/BAUDRATE*4)+1
    parameter   BIT4AT=16'd43, // round(SYSCLOCK/BAUDRATE*5)+1
    parameter   BIT5AT=16'd51, // round(SYSCLOCK/BAUDRATE*6)+1
    parameter   BIT6AT=16'd59, // round(SYSCLOCK/BAUDRATE*7)+1
    parameter   BIT7AT=16'd68, // round(SYSCLOCK/BAUDRATE*8)+1
    parameter   PBITAT=16'd76 // stoP bit, round(SYSCLOCK/BAUDRATE*9)+1
)(
    input wire          clk,
    input wire          rstn,
    
    output reg          tx=1'b1,
    
    output reg          tx_bsy,
    input wire          send_trig, // 每个时钟高电平有效一次
    input wire  [7:0]   send_data
);

    // tx flow control
    reg     [15:0]  tx_cnt;
    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            tx_cnt<=16'd0;
            tx_bsy<=1'b0;
        end else begin
            if(send_trig & (~tx_bsy)/* 2nd condition is vital */)
                tx_bsy<=1'b1;
            
            if(tx_bsy)begin
                if(tx_cnt==CLKPERFRM)begin
                    tx_cnt<=16'd0;
                    tx_bsy<=1'b0;
                end else
                    tx_cnt<=tx_cnt+1'b1;
            end
        end
    end

    // tx data control
    reg     [7:0]   data2send;
    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            data2send<=8'd0;
            tx<=1'b1; // init val should be 1
        end else begin
            if(send_trig & (~tx_bsy)/* 2nd condition is vital */)
                data2send<=send_data;

            case(tx_cnt)
                TBITAT: tx<=1'b0;
                BIT0AT: tx<=data2send[0];
                BIT1AT: tx<=data2send[1];
                BIT2AT: tx<=data2send[2];
                BIT3AT: tx<=data2send[3];
                BIT4AT: tx<=data2send[4];
                BIT5AT: tx<=data2send[5];
                BIT6AT: tx<=data2send[6];
                BIT7AT: tx<=data2send[7];
                PBITAT: tx<=1'b1;
            endcase
        end
    end

endmodule

/*

%% 串口模块参数生成
% Matlab script for uart_tx
% (C) 2014 , Ricyn Lee

%%
BITWIDTH=16;

prompt = {'系统时钟<MHz>:','波特率<Baud>:'};
dlg_title = '参数设置';
num_lines = 1;
def = {'100','115200'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

SYSCLOCK=fix(str2double(answer{1})*1e6);
BAUDRATE=fix(str2double(answer{2}));

fprintf('    parameter   SYSCLOCK=%d, // <Hz>\n',SYSCLOCK);
fprintf('    parameter   BAUDRATE=%d,\n',BAUDRATE);
CLKPERFRM=ceil(SYSCLOCK/BAUDRATE*10);
fprintf('    parameter   CLKPERFRM=%d''d%d, // ceil(SYSCLOCK/BAUDRATE*10)\n',BITWIDTH,CLKPERFRM);
fprintf('    // bit order is lsb-msb\n');
TBITAT=round(SYSCLOCK/BAUDRATE*0)+1;
fprintf('    parameter   TBITAT=%d''d%d, // starT bit, round(SYSCLOCK/BAUDRATE*0)+1\n',BITWIDTH,TBITAT);
for i=0:7
    BITxAT=round(SYSCLOCK/BAUDRATE*(i+1))+1;
    fprintf('    parameter   BIT%dAT=%d''d%d, // round(SYSCLOCK/BAUDRATE*%d)+1\n',i,BITWIDTH,BITxAT,i+1);
end
PBITAT=round(SYSCLOCK/BAUDRATE*9)+1;
fprintf('    parameter   PBITAT=%d''d%d // stoP bit, round(SYSCLOCK/BAUDRATE*9)+1\n',BITWIDTH,PBITAT);

if(CLKPERFRM>2^BITWIDTH-1)
    msgbox('计数器tx_cnt位宽不足,输出参数无效!','位宽错误','error');
end

 */

/*

# UART module parameter generator
# Python 2 script for uart_tx
# (C) 2018 , Ricyn Lee

import sys
printf = lambda txt:sys.stdout.write(txt)
from math import ceil, floor

##
BITWIDTH=16

print('\033[41;30mParameter configuration\033[0m')

try:
    SYSCLOCK=int(input('System clock freq in MHz:'))*1e6
except:
    SYSCLOCK=100e6
    
try:
    BAUDRATE=int(input('Baudrate:'))
except:
    BAUDRATE=115200

printf('    parameter   SYSCLOCK=%d, // <Hz>\n' % SYSCLOCK)
printf('    parameter   BAUDRATE=%d,\n' % BAUDRATE)
CLKPERFRM=ceil(SYSCLOCK/BAUDRATE*10)
printf('    parameter   CLKPERFRM=%d\'d%d, // ceil(SYSCLOCK/BAUDRATE*10)\n' % (BITWIDTH,CLKPERFRM))
printf('    // bit order is lsb-msb\n')
TBITAT=round(SYSCLOCK/BAUDRATE*0)+1
printf('    parameter   TBITAT=%d\'d%d, // starT bit, round(SYSCLOCK/BAUDRATE*0)+1\n' % (BITWIDTH,TBITAT))
for i in xrange(7+1):
    BITxAT=round(SYSCLOCK/BAUDRATE*(i+1))+1
    printf('    parameter   BIT%dAT=%d\'d%d, // round(SYSCLOCK/BAUDRATE*%d)+1\n' % (i,BITWIDTH,BITxAT,i+1))

PBITAT=round(SYSCLOCK/BAUDRATE*9)+1
printf('    parameter   PBITAT=%d\'d%d // stoP bit, round(SYSCLOCK/BAUDRATE*9)+1\n' % (BITWIDTH,PBITAT))

if CLKPERFRM>2**BITWIDTH-1:
    print('\033[41;30mError: inadequate bitwidth!\033[0m')

 */