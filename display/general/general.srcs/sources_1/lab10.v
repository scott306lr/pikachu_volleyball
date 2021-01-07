`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );


// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
// Application-specific VGA signals
wire [11:0] color_out;


// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider #(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;
// ------------------------------------------------------------------------



//buttons
wire [3:0] btn_level,btn_pressed;
reg  [3:0] prev_btn_level;

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);
debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);
debounce btn_db2(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level[2])
);
debounce btn_db3(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level[3])
);

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level &  ~prev_btn_level);
// ------------------------------------------------------------------------


// declare SRAM control signals
wire [17:0] sram_addr[0:5];
wire [11:0] data_in;
wire [11:0] data_out[0:5];
wire sram_we, sram_en;
reg  [17:0] loc[0:5];

// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram_sea #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  s_sea (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[0]), .data_i(data_in), .data_o(data_out[0]));
          
sram_fish1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH1_W*FISH1_H*4))
  s_fish1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[1]), .data_i(data_in), .data_o(data_out[1]));

assign sram_we = usr_led[3]; 
assign sram_en = 1;  
assign data_in = 12'h000; 


// Declare system variables
reg  [32:0] x_clock;
reg  [32:0] y_clock;
wire [9:0]  xpos[1:5];
wire [9:0]  ypos[1:5];
wire fish_region[1:5];

// Additional functions
reg [26:0] counter;
reg  reverse[1:5];
wire green[1:5];
reg speedup =0;
reg chcolor;

always @(posedge clk) begin
    if (~reset_n)
        reverse[1] <= 1;
    else if (btn_pressed[0] || btn_pressed[2] )
        reverse[1] <= ~reverse[1];
end

always @(posedge clk) begin
    if (~reset_n)
        chcolor <= 0;
    else if (btn_pressed[1])
        chcolor <= ~chcolor;
end

always @(posedge clk) begin
    if (~reset_n || btn_pressed[2] ) 
        counter <= 1;
    else 
        counter <= counter+1;
end

always @(posedge clk) begin
    if (~reset_n || counter == 0 )
        speedup <= 0;
    else if (btn_pressed[2])
        speedup <=1;
end
//additional function fin
// ------------------------------------------------------------------------


localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height
localparam FISH1_W = 64; // Width of the fish.
localparam FISH1_H  = 32; // Height of the fish.


reg [17:0] fish_addr[0:3];   // Address array for up to 8 fish images.
initial begin
  reverse[1] <= 0;
  x_clock <= 100<<20;
  y_clock <= 160<<20; 
  // each fish gif picture's address
  fish_addr[0] <= 18'd0;         
  fish_addr[1] <= FISH1_W*FISH1_H; 
  fish_addr[2] <= FISH1_W*FISH1_H*2; 
  fish_addr[3] <= FISH1_W*FISH1_H*3;
end



// ------------------------------------------------------------------------

assign xpos[1] = x_clock[31:20];
assign ypos[1] = y_clock[31:20];
reg [30:0] phy_clk;
integer x_v, y_v;

wire top_bord, l_bord, r_bord, bot_bord;
assign l_bord = x_clock[31:20] < 2*FISH1_W ;
assign r_bord = x_clock[31:20] > 2*VBUF_W ;
assign top_bord = y_clock[31:20] < 2*FISH1_H;
assign bot_bord = y_clock[31:20] > 2*VBUF_H;


always @(posedge clk) begin
    if (~reset_n || usr_btn [3] )
        x_clock <= 100<<20; 
    else if (l_bord)
        x_clock[31:0] <= { 2*FISH1_W, 20'd0 };
    else if (r_bord)
        x_clock[31:0] <= { 2*VBUF_W, 20'd0 };
    else
        x_clock <= x_clock + x_v;
end

always @(posedge clk) begin
    if (~reset_n || usr_btn [3] ) 
        y_clock <= 160<<20; 
    else if (top_bord)
        y_clock[31:0] <= { 2*FISH1_H, 20'd0 };   
    else if (down_bord)
        y_clock[31:0] <= { 2*VBUF_H, 20'd0 };     
    else
        y_clock <= y_clock + y_v;
end


always @(posedge clk) begin
    if(~reset_n)
        x_v <= 0;
    else if ( l_bord|| r_bord )
        x_v <= -x_v;
    else if (usr_btn [0])
        x_v <= 4;
    else if (usr_btn [1])
        x_v <= -4;
end

always @(posedge clk) begin
    if(~reset_n || usr_btn [3]) 
        y_v <= 0;
    else begin
        if( top_bord|| bot_bord )
            y_v <= -y_v;
        else if (phy_clk==27'd25000000)
            y_v <= y_v+1;
    end
end     

// phy_clk for gravity
always @(posedge clk) begin
    if(~reset_n)
        phy_clk <= 0;
    else if ( top_bord|| bot_bord )
        phy_clk[27:0] <= 27'd25000000 - phy_clk[27:0];
    else
        phy_clk <= (phy_clk==27'd25000000) ? 0 : phy_clk+1;
end

// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign sram_addr[0] = loc[0];
assign sram_addr[1] = loc[1];

always @ (posedge clk) begin
    if (~reset_n)
        loc[1] <= 0;
    else  if (fish_region[1])
        if ( !reverse[1] )
            loc[1] <= fish_addr[x_clock[24:23]] + ((pixel_y - ypos[1] + 2*FISH1_H - 1)>>1)*FISH1_W + ((xpos[1] - pixel_x)>>1);
        else
            loc[1] <= fish_addr[x_clock[24:23]] + ((pixel_y - ypos[1] + 2*FISH1_H - 1)>>1)*FISH1_W + ((pixel_x - xpos[1] + 2*FISH1_W - 1)>>1);
end

always @ (posedge clk) begin
    if (~reset_n)
        loc[0] <= 0;
    else 
        loc[0] <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
end

wire body[1:5];
assign green[1] = (data_out[1]==12'h0f0);

assign fish_region[1] = (
            pixel_x + FISH1_W*2 > xpos[1] && pixel_x <= xpos[1] &&
            pixel_y + FISH1_H*2 > ypos[1] && pixel_y <= ypos[1] 
        );

assign body[1] = fish_region[1] && ~green[1] ;
assign color_out = (body[1]) ? data_out[1] : data_out[0];

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if (chcolor && ~body[1] )
    rgb_next = ~color_out;
  else
    rgb_next = color_out; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
