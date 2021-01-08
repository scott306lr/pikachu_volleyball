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

localparam beach_W = 320; // video buffer width
localparam beach_H = 240; // video buffer height
localparam player_W = 64; // Width of the fish.
localparam player_H  = 64; // Height of the fish.
localparam ball_W = 50; // Width of the fish.
localparam ball_H = 50; // Height of the fish.
// declare SRAM control signals
wire [17:0] sram_addr[0:5];
wire [11:0] data_in;
wire [11:0] data_out[0:5];
wire sram_we, sram_en;
reg  [17:0] loc[0:5];
reg  [17:0] beach_loc;
reg  [17:0] ball_loc;
reg  [17:0] player_loc;
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram_sea #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(beach_W*beach_H))
  s_sea (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[0]), .data_i(data_in), .data_o(data_out[0]));
sram_player #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(player_W*player_H*4))
  s_player (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[1]), .data_i(data_in), .data_o(data_out[1]));
sram_ball #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(ball_W*ball_H*4))
  s_ball (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[2]), .data_i(data_in), .data_o(data_out[2]));
assign sram_we = usr_led[3]; 
assign sram_en = 1;  
assign data_in = 12'h000; 


// Declare system variables
reg  [32:0] player_x_clock;
reg  [32:0] player_y_clock;
wire [9:0]  player_xpos[1:5];
wire [9:0]  player_ypos[1:5];
wire player_region[1:5];
wire player_green[1:5];

// Declare system variables
reg  [32:0] ball_x_clock;
reg  [32:0] ball_y_clock;
wire [9:0]  ball_xpos[1:5];
wire [9:0]  ball_ypos[1:5];
wire ball_region[1:5];
wire ball_green[1:5];

// Additional functions
reg player_ground;


//additional function fin
// ------------------------------------------------------------------------




reg [17:0] player_addr[0:3];   // Address array for up to 8 fish images.
initial begin
  player_x_clock <= 100<<20;
  player_y_clock <= 160<<20; 
  // each fish gif picture's address
  player_addr[0] <= 18'd0;         
  player_addr[1] <= player_W*player_H; 
  player_addr[2] <= player_W*player_H*2; 
  player_addr[3] <= player_W*player_H*3;
end

reg [17:0] ball_addr[0:3];   // Address array for up to 8 fish images.
initial begin
  ball_x_clock <= 200<<20;
  ball_y_clock <= 200<<20; 
  // each fish gif picture's address
  ball_addr[0] <= 18'd0;         
  ball_addr[1] <= ball_W*ball_H; 
  ball_addr[2] <= ball_W*ball_H*2; 
  ball_addr[3] <= ball_W*ball_H*3;
end

assign player_xpos[1] = player_x_clock[31:20];
assign player_ypos[1] = player_y_clock[31:20];
assign ball_xpos[1] = ball_x_clock[31:20];
assign ball_ypos[1] = ball_y_clock[31:20];
// ------------------------------------------------------------------------


reg [30:0] player_phy_clk;
integer player_x_v, player_y_v;

reg [30:0] ball_phy_clk;
integer ball_x_v, ball_y_v;

//wire net_bord;
wire [11:0] floor = 2*beach_H - 30;

//assign net_bord=(	310<ball_x_clock[31:20] &&
//									ball_x_clock[31:20]<330 &&
//									160<ball_y_clock[31:20] &&
//									ball_y_clock[31:20]<320
//									);
//wire ball_net_left_bord, ball_net_up_bord, ball_net_right_bord;
//assign ball_net_left_bord=(			310<ball_x_clock[31:20] &&
//									ball_x_clock[31:20]<315&&
//									160<ball_y_clock[31:20] &&
//									ball_y_clock[31:20]<320
//									);
//assign ball_net_up_bord=(			315<ball_x_clock[31:20] &&
//									ball_x_clock[31:20]<325 &&
//									160<ball_y_clock[31:20] &&
//									ball_y_clock[31:20]<320
//									);
//assign ball_net_right_bord=(		325<ball_x_clock[31:20] &&
//									ball_x_clock[31:20]<330 &&
//									160<ball_y_clock[31:20] &&
//									ball_y_clock[31:20]<320
//									);
wire player_top_bord, player_l_bord, player_r_bord, player_down_bord;
assign player_l_bord = player_x_clock[31:20] < 2*player_W ;
assign player_r_bord = player_x_clock[31:20] > 2*beach_W ;
assign player_top_bord = player_y_clock[31:20] < 2*player_H;
assign player_bot_bord = player_y_clock[31:20] > floor;

wire ball_top_bord, ball_l_bord, ball_r_bord, ball_bot_bord;
assign ball_l_bord = ball_x_clock[31:20] < 2*ball_W ;
assign ball_r_bord = ball_x_clock[31:20] > 2*beach_W ;
assign ball_top_bord = ball_y_clock[31:20] < 2*ball_H;
assign ball_bot_bord = ball_y_clock[31:20] > floor;

//0716241


always @(posedge clk) begin
    if (~reset_n )
        player_x_clock <= 300<<20; 
    else if (player_l_bord)
        player_x_clock[31:0] <= { 2*player_W, 20'd0 };
    else if (player_r_bord)
        player_x_clock[31:0] <= { 2*beach_W, 20'd0 };
    else
        player_x_clock <= player_x_clock + player_x_v;
end
always @(posedge clk) begin
    if (~reset_n || usr_btn [3] )
        ball_x_clock <= 200<<20; 
    else if (ball_l_bord)
        ball_x_clock[31:0] <= { 2*ball_W, 20'd0 };
    else if (ball_r_bord)
        ball_x_clock[31:0] <= { 2*beach_W, 20'd0 };
    else
        ball_x_clock <= ball_x_clock + ball_x_v;
end


always @(posedge clk) begin
    if (~reset_n ) 
        player_y_clock <= 160<<20; 
    else if (player_top_bord)
        player_y_clock[31:0] <= { 2*player_H, 20'd0 };   
    else if (player_bot_bord)
        player_y_clock[31:0] <= { floor, 20'd0 };     
    else
        player_y_clock <= player_y_clock + player_y_v;
end
always @(posedge clk) begin
    if (~reset_n || usr_btn [3] ) 
        ball_y_clock <= 160<<20; 
    else if (ball_top_bord)
        ball_y_clock[31:0] <= { 2*ball_H, 20'd0 };   
    else if (ball_bot_bord)
        ball_y_clock[31:0] <= { floor, 20'd0 };
    else
        ball_y_clock <= ball_y_clock + ball_y_v;
end

always @(posedge clk) begin
    if(~reset_n)
        player_x_v <= 0;
    else if (usr_btn [0])
        player_x_v <= 4;
    else if (usr_btn [2])
        player_x_v <= -4;
    else 
        player_x_v <= 0;
end

always @(posedge clk) begin
    if(~reset_n)
        ball_x_v <= 0;
    else if ( ball_l_bord|| ball_r_bord )
        ball_x_v <= -ball_x_v;
    /*
	else if (usr_btn [0])
        ball_x_v <= 4;
    else if (usr_btn [1])
        ball_x_v <= -4;
	*/
end

always @(posedge clk) begin
    if(~reset_n)
        player_y_v <= 0;
    else begin
        if (btn_pressed[1] && player_ground)
            player_y_v <= -4;
        if( player_bot_bord )
            player_y_v <=0;
        else if (player_phy_clk==27'd25000000)
            player_y_v <= player_y_v+1;
    end
end
always @(posedge clk) begin
    if(~reset_n || usr_btn[3] ) 
        ball_y_v <= 0;
    else begin
        if( ball_top_bord|| ball_bot_bord )
            ball_y_v <= -ball_y_v;
        else if (ball_phy_clk==27'd25000000)
            ball_y_v <= ball_y_v+1;
    end
end     

always @(posedge clk) begin
    if(~reset_n)
        player_ground <= 0;
    else if (btn_pressed[1] && player_ground)
        player_ground <= 0;
    else if( player_y_clock[31:20] > floor )
        player_ground <= 1;
end

// player_phy_clk for gravity
always @(posedge clk) begin
    if(~reset_n)
        player_phy_clk <= 0;
    else if ( player_top_bord || player_ground )
        player_phy_clk[27:0] <= 0;
    else
        player_phy_clk <= (player_phy_clk==27'd25000000) ? 0 : player_phy_clk+1;
end
// ball_phy_clk for gravity
always @(posedge clk) begin
    if(~reset_n)
        ball_phy_clk <= 0;
    else if ( ball_top_bord || ball_bot_bord )
        ball_phy_clk[27:0] <= 27'd25000000 - ball_phy_clk[27:0];
    else
        ball_phy_clk <= (ball_phy_clk==27'd25000000) ? 0 : ball_phy_clk+1;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign sram_addr[0] = beach_loc;
assign sram_addr[1] = player_loc;
assign sram_addr[2] = ball_loc;
always @ (posedge clk) begin
    if (~reset_n)
        player_loc <= 0;
    else  if (player_region[1])
            player_loc <= player_addr[player_x_clock[24:23]] + ((pixel_y - player_ypos[1] + 2*player_H - 1)>>1)*player_W + ((player_xpos[1] - pixel_x)>>1);
            //reversed pikachu (for cpu sid)
            //player_loc <= player_addr[player_x_clock[24:23]] + ((pixel_y - player_ypos[1] + 2*player_H - 1)>>1)*player_W + ((pixel_x - player_xpos[1] + 2*player_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        ball_loc <= 0;
    else  if (ball_region[1])
            ball_loc <= ball_addr[ball_x_clock[24:23]] + ((pixel_y - ball_ypos[1] + 2*ball_H - 1)>>1)*ball_W + ((ball_xpos[1] - pixel_x)>>1);
end

always @ (posedge clk) begin
    if (~reset_n)
        beach_loc <= 0;
    else 
        beach_loc <= (pixel_y >> 1) * beach_W + (pixel_x >> 1);
end

wire body[1:5];
assign player_green[1] = (data_out[1]==12'h0f0);

assign player_region[1] = (
            pixel_x + player_W*2 > player_xpos[1] && pixel_x <= player_xpos[1] &&
            pixel_y + player_H*2 > player_ypos[1] && pixel_y <= player_ypos[1] 
        );
assign ball_green[1] = (data_out[2]==12'h0f0);
assign ball_region[1] = (
            pixel_x + ball_W*2 > ball_xpos[1] && pixel_x <= ball_xpos[1] &&
            pixel_y + ball_H*2 > ball_ypos[1] && pixel_y <= ball_ypos[1] 
        );
		
assign body[1] = player_region[1] && ~player_green[1] ;
assign body[2] = ball_region[1] && ~ball_green[1] ;
assign color_out = (body[2]) ? data_out[2] : ((body[1]) ? data_out[1] : data_out[0]);
// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
//  else if (chcolor && ~body[1] )
//    rgb_next = ~color_out;
  else
    rgb_next = color_out; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
