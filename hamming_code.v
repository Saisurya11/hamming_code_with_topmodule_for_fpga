module hamming_code(clk,en_data,en_hamming,ip_data,op_hammingcode,ip_hammingcode,op_data,op_errorbit,op_correctedcode);
input en_data,en_hamming,clk;
input [3:0]ip_data;
output reg [7:1]op_hammingcode;
input [7:1]ip_hammingcode;
output reg [3:0]op_data;
output reg [2:0]op_errorbit;
output reg [7:1]op_correctedcode;

reg [7:1]iphammingcode;
reg [2:0]temp;

always @(posedge clk)
begin
if(en_data)
begin 
op_hammingcode[3]=ip_data[0];
op_hammingcode[7:5]=ip_data[3:1];

case({op_hammingcode[3],op_hammingcode[5],op_hammingcode[7]})
0,3,5,6:op_hammingcode[1]=0;
default:op_hammingcode[1]=1; //1,2,4,7
endcase

case({op_hammingcode[3],op_hammingcode[6],op_hammingcode[7]})
0,3,5,6:op_hammingcode[2]=0;
default:op_hammingcode[2]=1; //1,2,4,7
endcase

case({op_hammingcode[5],op_hammingcode[6],op_hammingcode[7]})
0,3,5,6:op_hammingcode[4]=0;
default:op_hammingcode[4]=1; //1,2,4,7
endcase

end

if(en_hamming)
begin
iphammingcode[7:1]=ip_hammingcode[7:1];

case({iphammingcode[1],iphammingcode[3],iphammingcode[5],iphammingcode[7]})
0,3,5,6,9,10,12,15:temp[0]=0;
default:temp[0]=1;
endcase

case({iphammingcode[2],iphammingcode[3],iphammingcode[6],iphammingcode[7]})
0,3,5,6,9,10,12,15:temp[1]=0;
default:temp[1]=1;
endcase

case({iphammingcode[4],iphammingcode[5],iphammingcode[6],iphammingcode[7]})
0,3,5,6,9,10,12,15:temp[2]=0;
default:temp[2]=1;
endcase

if(iphammingcode[temp]==0)
iphammingcode[temp]=1;
else if(iphammingcode[temp]==1)
iphammingcode[temp]=0;

op_errorbit=temp;
op_correctedcode=iphammingcode;
op_data[0]=iphammingcode[3];
op_data[1]=iphammingcode[5];
op_data[2]=iphammingcode[6];
op_data[3]=iphammingcode[7];
end

if(!en_data && !en_hamming)
begin
op_correctedcode=0;
op_data=0;
op_errorbit=0;
op_hammingcode=0;
end

else if(!en_data)
begin
op_hammingcode=0;
end

else if(!en_hamming)
begin
op_correctedcode=0;
op_data=0;
op_errorbit=0;
end

end
endmodule

module refresh_counter(clk,out);
input clk;
output reg [2:0]out=0;
always @(posedge clk)
begin
if(out==6)
out<=0;
else
out<=out+1;
end
endmodule

module clock_divider(clk,newclk);
input clk;
output reg newclk=0;
integer count=0;
always@(posedge clk)
begin
if(count==50000000)
begin
newclk=~newclk;
count<=0;
end
else
count=count+1;
end
endmodule

module converter(clk,en_data,en_hamming,ip_data,ip_hammingcode,out,an,count,ip_sw);
input clk,en_data,en_hamming;
input [3:0]ip_data;
input [6:0]ip_hammingcode;
output reg [6:0]out;
output [2:0]count;
output reg [7:0]an;
input ip_sw;

wire [6:0]op_correctedcode,op_hammingcode;
wire [3:0]op_data;
wire [2:0]op_errorbit;

wire [2:0]out1;

reg [3:0]bcd;
wire nclk;
clock_divider d1(clk,nclk);
refresh_counter c1(nclk,out1);
hamming_code x1(nclk,en_data,en_hamming,ip_data,op_hammingcode,ip_hammingcode,op_data,op_errorbit,op_correctedcode);

assign count=out1;
always @(*)
begin
if(ip_sw)
begin
case(out1)
0:
begin
bcd=op_hammingcode[6];
an=8'b01111111;
end

1:begin
bcd=op_hammingcode[5];
an=8'b10111111;
end

2:begin
bcd=op_hammingcode[4];
an=8'b11011111;
end

3:begin
bcd=op_hammingcode[3];
an=8'b11101111;
end

4:begin
bcd=op_hammingcode[2];
an=8'b11110111;
end

5:begin
bcd=op_hammingcode[1];
an=8'b11111011;
end

6:begin
bcd=op_hammingcode[0];
an=8'b11111101;
end
endcase
end
else if(!ip_sw)
begin
case(out1)
0:
begin
bcd=op_correctedcode[6];
an=8'b01111111;
end

1:begin
bcd=op_correctedcode[5];
an=8'b10111111;
end

2:begin
bcd=op_correctedcode[4];
an=8'b11011111;
end

3:begin
bcd=op_correctedcode[3];
an=8'b11101111;
end

4:begin
bcd=op_correctedcode[2];
an=8'b11110111;
end

5:begin
bcd=op_correctedcode[1];
an=8'b11111011;
end

6:begin
bcd=op_correctedcode[0];
an=8'b11111101;
end
endcase
end
case(bcd)
0:out=7'b1000000;
1:out=7'b1111001;
default:out=7'b0111111;
endcase
end
endmodule


/*module test;
reg en1,en2,clk;
reg [3:0]ip_data;
wire [6:0]op_hammingcode;

reg [7:1]ip_hammingcode;
wire [3:0]op_data;
wire [2:0]op_errorbit;
wire [7:1]op_correctedcode;
hamming_code x1(clk,en1,en2,ip_data,op_hammingcode[6:0],ip_hammingcode,op_data,op_errorbit,op_correctedcode);

initial
begin
en1=0; en2=0; clk=1;
ip_data=4'b1101; ip_hammingcode=7'b1110110;
#4


en1=0; en2=0;
ip_data=4'b1100; ip_hammingcode=7'b1110110;
#4

en1=1; en2=0;
ip_data=4'b1101; ip_hammingcode=7'b1100010; #4

en1=0; en2=1;
ip_data=4'b1100; ip_hammingcode=7'b1100010; #4

en1=1; en2=1; 
ip_data=4'b0001;  ip_hammingcode=7'b0000110; #4

en1=0; en2=1;
ip_data=4'b0001;  ip_hammingcode=7'b1100110; #4
$stop;
end

always #2 clk=~clk;
endmodule

*/

module top(clk,sw,seg,an,led);
input clk;
input [13:0]sw;
output [6:0]seg;
output [7:0]an;
output [2:0]led;
converter  m1(clk,sw[0],sw[1],sw[5:2],sw[12:6],seg,an,led,sw[13]);
//converter(clk,en_data,en_hamming,ip_data,ip_hammingcode,out,an,count,ip_sw);
endmodule