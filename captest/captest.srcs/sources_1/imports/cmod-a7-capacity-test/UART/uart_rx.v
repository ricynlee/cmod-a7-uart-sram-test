/*
 *  - UART接收模块 -
 *
 * 无奇偶校验位
 *
 * Ver1.0 2014.09
 * Ver1.1 2015.07:增强启动边沿检测稳定性
 */

// 注:参数可用代码结尾的MATLAB或Python程序生成

module uart_rx #(
    parameter   SYSCLOCK=100000000, // <Hz>
    parameter   BAUDRATE=12000000,
    parameter   NEDORD=6, // Nedge Detector order
    parameter   NEDPAT=7'b1110000, // Nedge Detector pattern
    parameter   NEDDLY=3, // Nedge Detector delay
    parameter   CLKPERFRM=16'd79, // floor(SYSCLOCK/BAUDRATE*10)-NEDDLY-1
    // bit order is lsb-msb
    parameter   TBITAT=16'd1, // starT bit, round(SYSCLOCK/BAUDRATE*.5)-NEDDLY
    parameter   BIT0AT=16'd10, // round(SYSCLOCK/BAUDRATE*1.5)-NEDDLY
    parameter   BIT1AT=16'd18, // round(SYSCLOCK/BAUDRATE*2.5)-NEDDLY
    parameter   BIT2AT=16'd26, // round(SYSCLOCK/BAUDRATE*3.5)-NEDDLY
    parameter   BIT3AT=16'd35, // round(SYSCLOCK/BAUDRATE*4.5)-NEDDLY
    parameter   BIT4AT=16'd43, // round(SYSCLOCK/BAUDRATE*5.5)-NEDDLY
    parameter   BIT5AT=16'd51, // round(SYSCLOCK/BAUDRATE*6.5)-NEDDLY
    parameter   BIT6AT=16'd60, // round(SYSCLOCK/BAUDRATE*7.5)-NEDDLY
    parameter   BIT7AT=16'd68, // round(SYSCLOCK/BAUDRATE*8.5)-NEDDLY
    parameter   PBITAT=16'd76 // stoP bit, round(SYSCLOCK/BAUDRATE*9.5)-NEDDLY
)(
    input wire          clk,
    input wire          rstn,
    
    input wire          rx,
    
    output reg          fetch_trig, // 每收到一字节数据,输出一个时钟高电平
    output reg  [7:0]   fetch_data
);

    // reception start detect
    reg     [NEDORD:1]      prev_rx;
    reg                     rx_nedge; // reception starts at nedge of rx
    wire    [NEDORD+1:1]    prev_rx_tmp;
    assign                  prev_rx_tmp={prev_rx[NEDORD:1],rx};
    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            prev_rx<={NEDORD{1'b1}}; // init val should be all 1s
            rx_nedge<=1'b0;
        end else begin
            prev_rx<=prev_rx_tmp[NEDORD:1];
            if({prev_rx,rx}==NEDPAT)
                rx_nedge<=1'b1;
            else
                rx_nedge<=1'b0;
        end
    end
    
    // rx flow control
    reg     [15:0]  rx_cnt;
    reg             rx_bsy;

    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            rx_cnt<=16'd0;
            rx_bsy<=1'b0;
            fetch_trig<=1'b0;
        end else begin
            if(rx_nedge & (~rx_bsy)/* 2nd condition is vital */)
                rx_bsy<=1'b1;

            if(rx_bsy)begin
                rx_cnt<=rx_cnt+1'b1;
                
                if(rx_cnt==TBITAT)begin
                    if(rx==1'b1) rx_bsy<=1'b0;
                end
                
                if(rx_cnt==PBITAT)begin
                    rx_bsy<=1'b0;
                    if(rx==1'b1) fetch_trig<=1'b1;
                end
            end else /*if(~rx_bsy)*/ begin
                rx_cnt<=16'd0;
            end
            
            if(fetch_trig)
                fetch_trig<=1'b0;
        end
    end

    // rx data control
    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            fetch_data<=8'd0;
        end else begin
            case(rx_cnt)
                BIT0AT: fetch_data[0]<=rx;
                BIT1AT: fetch_data[1]<=rx;
                BIT2AT: fetch_data[2]<=rx;
                BIT3AT: fetch_data[3]<=rx;
                BIT4AT: fetch_data[4]<=rx;
                BIT5AT: fetch_data[5]<=rx;
                BIT6AT: fetch_data[6]<=rx;
                BIT7AT: fetch_data[7]<=rx;
            endcase
        end
    end

endmodule

/*

%% 串口模块参数生成
% uart_rx
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
NEDORD=round(SYSCLOCK/10e6);
if NEDORD==0,NEDORD=1;end
NEDPAT=sprintf('%d''b%s%s',NEDORD+1, ...
    repmat('1',1,floor((NEDORD+1)/2)), ...
    repmat('0',1,ceil((NEDORD+1)/2)) ...
    );
NEDDLY=floor((NEDORD+1)/2);
fprintf('    parameter   NEDORD=%d, // Nedge Detector order\n',NEDORD);
fprintf('    parameter   NEDPAT=%s, // Nedge Detector pattern\n',NEDPAT);
fprintf('    parameter   NEDDLY=%d, // Nedge Detector delay\n',NEDDLY);

CLKPERFRM=floor(SYSCLOCK/BAUDRATE*10)-NEDDLY-1;
fprintf('    parameter   CLKPERFRM=%d''d%d, // floor(SYSCLOCK/BAUDRATE*10)-NEDDLY-1\n',BITWIDTH,CLKPERFRM);

fprintf('    // bit order is lsb-msb\n');
TBITAT=round(SYSCLOCK/BAUDRATE*.5)-NEDDLY;
fprintf('    parameter   TBITAT=%d''d%d, // starT bit, round(SYSCLOCK/BAUDRATE*.5)-NEDDLY\n',BITWIDTH,TBITAT);
for i=0:7
    BITxAT=round(SYSCLOCK/BAUDRATE*(i+1.5))-NEDDLY;
    fprintf('    parameter   BIT%dAT=%d''d%d, // round(SYSCLOCK/BAUDRATE*%.1f)-NEDDLY\n',i,BITWIDTH,BITxAT,i+1.5);
end
PBITAT=round(SYSCLOCK/BAUDRATE*9.5)-NEDDLY;
fprintf('    parameter   PBITAT=%d''d%d // stoP bit, round(SYSCLOCK/BAUDRATE*9.5)-NEDDLY\n',BITWIDTH,PBITAT);

if(CLKPERFRM>2^BITWIDTH-1)
    msgbox('计数器rx_cnt位宽不足,输出参数无效!','位宽错误','error');
end

 */

/*

# UART module parameter generator
# Python 2 script for uart_rx
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
NEDORD=round(SYSCLOCK/10e6)
if NEDORD==0:
    NEDORD=1
NEDPAT='%d\'b%s%s' % \
    ( NEDORD+1, \
    '1'*int(floor((NEDORD+1)/2)), \
    '0'*int(ceil((NEDORD+1)/2)) )

NEDDLY=floor((NEDORD+1)/2)
printf('    parameter   NEDORD=%d, // Nedge Detector order\n' % NEDORD)
printf('    parameter   NEDPAT=%s, // Nedge Detector pattern\n' % NEDPAT)
printf('    parameter   NEDDLY=%d, // Nedge Detector delay\n' % NEDDLY)

CLKPERFRM=floor(SYSCLOCK/BAUDRATE*10)-NEDDLY-1
printf('    parameter   CLKPERFRM=%d\'d%d, // floor(SYSCLOCK/BAUDRATE*10)-NEDDLY-1\n' % (BITWIDTH,CLKPERFRM))
printf('    // bit order is lsb-msb\n')
TBITAT=round(SYSCLOCK/BAUDRATE*.5)-NEDDLY
printf('    parameter   TBITAT=%d\'d%d, // starT bit, round(SYSCLOCK/BAUDRATE*.5)-NEDDLY\n' % (BITWIDTH,TBITAT))
for i in xrange(7+1):
    BITxAT=round(SYSCLOCK/BAUDRATE*(i+1.5))-NEDDLY
    printf('    parameter   BIT%dAT=%d\'d%d, // round(SYSCLOCK/BAUDRATE*%.1f)-NEDDLY\n' % (i,BITWIDTH,BITxAT,i+1.5))
PBITAT=round(SYSCLOCK/BAUDRATE*9.5)-NEDDLY
printf('    parameter   PBITAT=%d\'d%d // stoP bit, round(SYSCLOCK/BAUDRATE*9.5)-NEDDLY\n' % (BITWIDTH,PBITAT))

if CLKPERFRM>2**BITWIDTH-1:
    print('\033[41;30mError: inadequate bitwidth!\033[0m')

 */