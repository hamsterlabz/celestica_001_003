module blinky (
  input  wire       sys_clk,   // 50 MHz, AA28
  output wire [2:0] led        // P30 M30 N30
);
  reg [25:0] cnt = 0;
  always @(posedge sys_clk) cnt <= cnt + 1;
  assign led = cnt[25:23];
endmodule
