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
    input  [3:0] usr_sw,
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
wire [11:0] game_color_out;


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

localparam PHY_CLK = 25000000;

localparam beach_W = 320; // video buffer width
localparam beach_H = 240; // video buffer height
localparam player_W = 64; // Width of the fish.
localparam player_H  = 64; // Height of the fish.
localparam ball_W = 40; // Width of the fish.
localparam ball_H  = 40; // Height of the fish.
localparam options_W = 100;
localparam options_H = 30;
localparam score_W = 21;
localparam score_H = 27;
localparam announce_W = 100;
localparam announce_H = 30;
localparam instruct_W = 200;
localparam instruct_H = 30;

localparam net_W = 5;
localparam net_H = 80;

// declare SRAM control signals
wire [17:0] sram_addr[0:6];
wire [11:0] data_in;
wire [11:0] data_out[0:6];
wire sram_we, sram_en;

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
sram_options #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(options_W*options_H*4))
  s_opt (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[3]), .data_i(data_in), .data_o(data_out[3]));
sram_score #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(score_W*score_H*10))
  s_score (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[4]), .data_i(data_in), .data_o(data_out[4]));       
sram_announce #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(announce_W*announce_H*5))
  s_announce (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[5]), .data_i(data_in), .data_o(data_out[5]));       
sram_instruct #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(instruct_W*instruct_H*4))
  s_instruct (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[6]), .data_i(data_in), .data_o(data_out[6]));    
assign sram_we = usr_led[3]; 
assign sram_en = 1;  
assign data_in = 12'h000; 

reg  [17:0] beach_loc;
reg [2:0] P, P_next; // start menu
//reg [2:0] Q,Q_next; // skin menu

localparam [2:0]  START_SCENE=0, SKIN_SCENE=1, GAME_START_SCENE=2, READY_SCENE=3, GAME_SCENE=4, GAME_SET=5, PLAYER_WIN=6, PLAYER_LOSE=7;

// player variables
reg  [17:0] player_loc;
reg [17:0] player_addr[0:3];   // Address array for up to 8 fish images.
reg  [32:0] player_x_clock;
reg  [32:0] player_y_clock;
wire  [9:0] player_xpos[1:5];
wire  [9:0] player_ypos[1:5];
wire player_region[1:5];
wire player_green[1:5];

// ai variables
reg  [17:0] ai_loc;
reg [17:0] ai_addr[0:3];   // Address array for up to 8 fish images.
reg  [32:0] ai_x_clock;
reg  [32:0] ai_y_clock;
wire [9:0]  ai_xpos[1:5];
wire [9:0]  ai_ypos[1:5];
wire ai_region[1:5];
wire ai_green[1:5];

// ball variables
reg  [17:0] ball_loc;
reg [17:0] ball_addr[0:3];   // Address array for up to 8 fish images.
reg  [32:0] ball_x_clock;
reg  [32:0] ball_y_clock;
wire [9:0]  ball_xpos[1:5];
wire [9:0]  ball_ypos[1:5];
wire ball_region[1:5];
wire ball_green[1:5];

// options variables
reg  [17:0] options_start_loc;
reg  [17:0] options_skin_loc;
reg [17:0] options_addr[0:3];   // Address array for up to 8 fish images.
wire [9:0]  options_xpos[1:5];
wire [9:0]  options_ypos[1:5];
wire options_start_region[1:5];
wire options_skin_region[1:5];
wire options_start_green[1:5];
wire options_skin_green[1:5];

// score variables
reg [17:0] score_loc[1:2];
reg [17:0] score_addr[0:9];   // Address array for up to 8 fish images.
wire [9:0]  score_xpos[1:5];
wire [9:0]  score_ypos[1:5];
wire score_region[1:5];
wire score_green[1:5];

// pikachu skin variables
reg  [17:0] skin_loc[1:3];
reg  [17:0] skin_addr[0:3];   // Address array for up to 8 fish images.
reg  [32:0] skin_x_clock;
reg  [32:0] skin_y_clock;
wire [9:0]  skin_xpos[1:5];
wire [9:0]  skin_ypos[1:5];
wire skin_region[1:5];
wire skin_green[1:5];

// announce variables
reg [17:0]  announce_loc[1:5];
reg [17:0]  announce_addr[0:4];
wire [9:0]  announce_xpos[1:5];
wire [9:0]  announce_ypos[1:5];
wire announce_region[1:5];
wire announce_green[1:5];

// announce variables
reg [17:0]  instruct_loc[1:5];
reg [17:0]  instruct_addr[0:4];
wire [9:0]  instruct_xpos[1:5];
wire [9:0]  instruct_ypos[1:5];
wire instruct_region[1:5];
wire instruct_green[1:5];

// ------------------------------------------------------------------------

initial begin
  player_x_clock <= 100<<20;
  player_y_clock <= 160<<20; 
  player_addr[0] <= 18'd0;         
  player_addr[1] <= player_W*player_H; 
  player_addr[2] <= player_W*player_H*2; 
  player_addr[3] <= player_W*player_H*3;

  ai_x_clock <= 100<<20;
  ai_y_clock <= 160<<20; 
  ai_addr[0] <= 18'd0;         
  ai_addr[1] <= player_W*player_H; 
  ai_addr[2] <= player_W*player_H*2; 
  ai_addr[3] <= player_W*player_H*3;

  ball_x_clock <= 200<<20;
  ball_y_clock <= 200<<20; 
  ball_addr[0] <= 18'd0;         
  ball_addr[1] <= ball_W*ball_H; 
  ball_addr[2] <= ball_W*ball_H*2; 
  ball_addr[3] <= ball_W*ball_H*3;
  
  options_addr[0] <= 18'd0;         
  options_addr[1] <= options_W*options_H; 
  
  score_addr[0] <= 18'd0;         
  score_addr[1] <= score_W*score_H; 
  score_addr[2] <= score_W*score_H*2; 
  score_addr[3] <= score_W*score_H*3;
  score_addr[4] <= score_W*score_H*4; 
  score_addr[5] <= score_W*score_H*5; 
  score_addr[6] <= score_W*score_H*6;
  score_addr[7] <= score_W*score_H*7; 
  score_addr[8] <= score_W*score_H*8; 
  score_addr[9] <= score_W*score_H*9;
 
  skin_addr[0] <= 18'd0;         
  skin_addr[1] <= player_W*player_H; 
  skin_addr[2] <= player_W*player_H*2; 
  skin_addr[3] <= player_W*player_H*3;
  
  announce_addr[0] <= 18'd0;         
  announce_addr[1] <= announce_W*announce_H; 
  announce_addr[2] <= announce_W*announce_H*2; 
  announce_addr[3] <= announce_W*announce_H*3;
  announce_addr[4] <= announce_W*announce_H*4;
  
  instruct_addr[0] <= 18'd0;         
  instruct_addr[1] <= instruct_W*instruct_H; 
  instruct_addr[2] <= instruct_W*instruct_H*2; 
  instruct_addr[3] <= instruct_W*instruct_H*3;
end

// physics
// ------------------------------------------------------------------------------------------------------------------------------------------------

//position
assign player_xpos[1] = player_x_clock[31:20];
assign player_ypos[1] = player_y_clock[31:20];
assign ball_xpos[1] = ball_x_clock[31:20];
assign ball_ypos[1] = ball_y_clock[31:20];
assign ai_xpos[1] = ai_x_clock[31:20];
assign ai_ypos[1] = ai_y_clock[31:20];
assign options_xpos[1] = beach_W+options_W;
assign options_ypos[1] = 200+options_H*2;
assign options_xpos[2] = beach_W+options_W;
assign options_ypos[2] = 300+options_H*2;
assign score_xpos[1] = score_W*2 + 10;
assign score_ypos[1] = score_H*2 + 10;
assign score_xpos[2] = beach_W*2 - 10;
assign score_ypos[2] = score_H*2 + 10;
assign skin_xpos[1] = player_W + beach_W - 200;
assign skin_ypos[1] = player_H  + beach_H;
assign skin_xpos[2] = player_W + beach_W;
assign skin_ypos[2] = player_H  + beach_H;
assign skin_xpos[3] = player_W + beach_W + 200;
assign skin_ypos[3] = player_H  + beach_H;
//
assign announce_xpos[1] = player_W + beach_W + 50;
assign announce_ypos[1] = player_H  + 50;
assign instruct_xpos[1] = beach_W*2 - 10;
assign instruct_ypos[1] = beach_H*2  - 10;

//ball start
reg last_score; // 0 == cpu, 1 == player

//check whether can jump
reg player_can_jump;
reg ai_can_jump;

//speed
integer player_x_v, player_y_v;
integer ball_x_v, ball_y_v; 
integer ai_x_v, ai_y_v;

// gravity
reg [30:0] player_phy_clk, ball_phy_clk, ai_phy_clk;

//floor
wire [11:0] floor = 2*beach_H - 45;

//border
wire ball_l_bord = ball_xpos[1] < 2*ball_W ;
wire ball_r_bord = ball_xpos[1] > 2*beach_W ;
wire ball_top_bord = ball_ypos[1] < 2*ball_H;
wire ball_bot_bord = ball_ypos[1] > floor;

wire ball_net_left_bord=(			ball_xpos[1] > beach_W-net_W &&
									ball_xpos[1] < beach_W &&
									ball_ypos[1] < floor &&
									ball_ypos[1] > floor-net_H*2
									);
wire ball_net_up_bord=(			ball_xpos[1] > beach_W-net_W -3 &&
									ball_xpos[1]< beach_W + net_W*2 + ball_W*2 -3 &&
									ball_ypos[1] < floor-net_H*2 + 5 &&
									ball_ypos[1] > floor-net_H*2 
									);
wire ball_net_right_bord=(		ball_xpos[1] > beach_W + net_W + ball_W*2  &&
									ball_xpos[1]< beach_W + net_W*2 + ball_W*2 &&
									ball_ypos[1] < floor &&
									ball_ypos[1] > floor - net_H*2
									);
									
wire player_l_bord = player_x_clock[31:20] < 2*player_W+beach_W ;
wire player_r_bord = player_x_clock[31:20] > 2*beach_W ;
wire player_top_bord = player_y_clock[31:20] < 2*player_H;
wire player_bot_bord = player_y_clock[31:20] > floor;

wire ai_l_bord = ai_x_clock[31:20] < 2*player_W ;
wire ai_r_bord = ai_x_clock[31:20] > 2*beach_W ;
wire ai_top_bord = ai_y_clock[31:20] < 2*player_H;
wire ai_bot_bord = ai_y_clock[31:20] > floor;

wire ball_player_left_hit_bord=(	player_x_clock[31:20]-player_W<ball_x_clock[31:20] &&
									ball_x_clock[31:20]<player_x_clock[31:20]-player_W*2 &&
									player_y_clock[31:20]-player_H<ball_y_clock[31:20] &&
									ball_y_clock[31:20]<player_y_clock[31:20]
									);
wire ball_player_up_hit_bord=(	player_x_clock[31:20]<ball_x_clock[31:20] &&
									ball_x_clock[31:20]<player_x_clock[31:20]+player_W*2 &&
									player_y_clock[31:20]-player_H*2<ball_y_clock[31:20] &&
									ball_y_clock[31:20]<player_y_clock[31:20]
									);
wire ball_player_right_hit_bord=(	player_x_clock[31:20]+player_W<ball_x_clock[31:20] &&
									ball_x_clock[31:20]<player_x_clock[31:20]+ball_W*2 &&
									player_y_clock[31:20]-player_H<ball_y_clock[31:20] &&
									ball_y_clock[31:20]<player_y_clock[31:20]
									);

wire ball_ai_left_hit_bord=(	ai_x_clock[31:20]-player_W<ball_x_clock[31:20] &&
									ball_x_clock[31:20]<ai_x_clock[31:20] &&
									ai_y_clock[31:20]-player_H<ball_y_clock[31:20] &&
									ball_y_clock[31:20]<ai_y_clock[31:20]
									);
wire ball_ai_up_hit_bord=(	ai_x_clock[31:20]<ball_x_clock[31:20] &&
									ball_x_clock[31:20]<ai_x_clock[31:20]+player_W &&
									ai_y_clock[31:20]-player_H*2<ball_y_clock[31:20] &&
									ball_y_clock[31:20]<ai_y_clock[31:20]
									);
wire ball_ai_right_hit_bord=(	ai_x_clock[31:20]<ball_x_clock[31:20]+ball_W*2 &&
									ball_x_clock[31:20]<ai_x_clock[31:20]+2*player_W &&
									ai_y_clock[31:20]-player_H<ball_y_clock[31:20] &&
									ball_y_clock[31:20]<ai_y_clock[31:20]
									);

// shortcuts
wire touched_ground = ball_bot_bord;
wire player_smash = usr_btn[2];
wire ai_smash = !ai_can_jump && (ai_y_v > -3);
// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//0716241 
//ball 
reg [26:0] ball_player_cd;
always @(posedge clk)begin
	if(~reset_n || P != GAME_SCENE || touched_ground )
		ball_player_cd<=0;
	else if(ball_player_cd!=0)
		ball_player_cd<=ball_player_cd-1;
	else if(ball_player_cd==27'b0  )begin
		if ( (ball_player_left_hit_bord || ball_player_up_hit_bord ||ball_player_right_hit_bord) || (ball_ai_left_hit_bord || ball_ai_up_hit_bord ||ball_ai_right_hit_bord) )
			ball_player_cd<=27'd128000000;
		else
			ball_player_cd<=0;
	end
end

// player x,y clock
always @(posedge clk) begin
    if (~reset_n || P != GAME_SCENE || touched_ground )
        player_x_clock <= 600<<20; 
    else if (player_l_bord)
        player_x_clock[31:0] <= { 2*player_W+beach_W, 20'd0 };
    else if (player_r_bord)
        player_x_clock[31:0] <= { 2*beach_W, 20'd0 };
    else
        player_x_clock <= player_x_clock + player_x_v;
end

always @(posedge clk) begin
    if (~reset_n || P != GAME_SCENE || touched_ground ) 
        player_y_clock <= 430<<20; 
    else if (player_top_bord)
        player_y_clock[31:0] <= { 2*player_H, 20'd0 };   
    else if (player_bot_bord)
        player_y_clock[31:0] <= { floor, 20'd0 };     
        
    else
        player_y_clock <= player_y_clock + player_y_v;
end

// ai x,y clock
always @(posedge clk) begin
    if (~reset_n || P != GAME_SCENE || touched_ground )
        ai_x_clock <= 150<<20; 
    else if (ai_l_bord)
        ai_x_clock[31:0] <= { 2*player_W, 20'd0 };
    else
        ai_x_clock <= ai_x_clock + ai_x_v;
end

always @(posedge clk) begin
    if (~reset_n || P != GAME_SCENE || touched_ground ) 
        ai_y_clock <= 430<<20; 
    else if (ai_top_bord)
        ai_y_clock[31:0] <= { 2*player_H, 20'd0 };   
    else if (ai_bot_bord)
        ai_y_clock[31:0] <= { floor, 20'd0 };     
    else
        ai_y_clock <= ai_y_clock + ai_y_v;
end

// ball x,y clock
always @(posedge clk) begin
    if (~reset_n || P != GAME_SCENE || touched_ground )
        ball_x_clock <= (ball_W + beach_W + 1) <<20; 
    else if (ball_l_bord)
        ball_x_clock[31:0] <= { 2*ball_W, 20'd0 };
    else if (ball_r_bord)
        ball_x_clock[31:0] <= { 2*beach_W, 20'd0 };
    else if(ball_net_left_bord)
		ball_x_clock[31:0] <= { (beach_W-net_W), 20'd0};
    else if(ball_net_right_bord)
		ball_x_clock[31:0] <= { (beach_W + net_W*2 + ball_W*2), 20'd0};
    else if  ((ball_player_left_hit_bord || ball_player_up_hit_bord || ball_player_right_hit_bord )&& ball_player_cd==27'd0 )
        ball_x_clock[31:0] <= ball_x_clock[31:0];
	else if  ((ball_ai_left_hit_bord || ball_ai_up_hit_bord || ball_ai_right_hit_bord )&& ball_player_cd==27'd0 )  
		ball_x_clock[31:0] <= ball_x_clock[31:0];
    
    else
        ball_x_clock <= ball_x_clock + ball_x_v;
end

always @(posedge clk) begin
    if (~reset_n || P != GAME_SCENE || touched_ground ) 
        ball_y_clock <= 160<<20; 
    else if (ball_top_bord)
        ball_y_clock[31:0] <= { 2*ball_H, 20'd0 };   
    else if (ball_bot_bord)
        ball_y_clock[31:0] <= { floor, 20'd0 };
	else if ( ball_net_up_bord )
	   ball_y_clock[31:0] <= { floor-net_H*2, 20'd0 };
	   //
	else if  ((ball_player_left_hit_bord || ball_player_up_hit_bord || ball_player_right_hit_bord) && ball_player_cd==27'd0 )
        ball_y_clock[31:0] <= ball_y_clock[31:0];
	else if  ((ball_ai_left_hit_bord || ball_ai_up_hit_bord || ball_ai_right_hit_bord )&& ball_player_cd==27'd0 )  
		ball_y_clock[31:0] <= ball_y_clock[31:0];
    else
        ball_y_clock <= ball_y_clock + ball_y_v;
end

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// player x,y speed
always @(posedge clk) begin
    if(~reset_n || P != GAME_SCENE || touched_ground )
        player_x_v <= 0;
    else if (usr_btn [0])
        player_x_v <= 4;
    else if (usr_btn [1])
        player_x_v <= -3;
    else 
        player_x_v <= 0;
end

always @(posedge clk) begin
    if(~reset_n || P != GAME_SCENE || touched_ground )
        player_y_v <= 0;
    else begin
        if (btn_pressed[3] && player_can_jump)
            player_y_v <= -4;
        else if( player_bot_bord )
            player_y_v <=0;
        else if (player_phy_clk==27'd25000000)
            player_y_v <= player_y_v+1;
    end
end

// ai x,y speed
always @(posedge clk) begin
    if(~reset_n || P != GAME_SCENE || touched_ground )
        ai_x_v <= 0;
    else if (ball_xpos[1]<ai_xpos[1] )
        ai_x_v <= -2;
    else if (ball_xpos[1]>ai_xpos[1] && ball_xpos[1]<beach_W-10)
        ai_x_v <=  2;
    else 
        ai_x_v <= 0;
end

always @(posedge clk) begin
    if(~reset_n || P != GAME_SCENE || touched_ground )
        ai_y_v <= 0;
    else begin
        if (ball_ai_up_hit_bord && ai_can_jump)
            ai_y_v <= -4;
        else if( ai_bot_bord )
            ai_y_v <=0;
        else if (ai_phy_clk==27'd25000000)
            ai_y_v <= ai_y_v+1;
    end
end

// ball x,y speed
always @(posedge clk) begin
    if(~reset_n || P != GAME_SCENE || touched_ground )
        ball_x_v <= 2 - last_score*4;
    else if ( ball_l_bord|| ball_r_bord )
        ball_x_v <= -ball_x_v;
    else if(ball_net_left_bord)
        ball_x_v <= -4;
    else if(ball_net_right_bord)
        ball_x_v <=  4;
	else if(ball_player_left_hit_bord  || ball_player_left_hit_bord  && ball_player_cd==27'd0)
		ball_x_v <= (player_smash) ? -8 : -4;
	else if(ball_player_right_hit_bord  || ball_ai_right_hit_bord  && ball_player_cd==27'd0)
		ball_x_v <= (ai_smash) ? 8 : 4;
end

always @(posedge clk || touched_ground) begin
    if(~reset_n || P != GAME_SCENE || touched_ground ) 
        ball_y_v <= 0;
    else begin
        if( ball_top_bord)
            ball_y_v <= -ball_y_v;
        else if (ball_bot_bord )
            ball_y_v <= 0;
        else if (ball_net_up_bord)
            ball_y_v <= -ball_y_v+1;
        else if( (ball_player_up_hit_bord || ball_player_left_hit_bord || ball_player_right_hit_bord && !player_smash ) || (ball_ai_up_hit_bord || ball_ai_left_hit_bord || ball_ai_right_hit_bord && !ai_smash)  && ball_player_cd==27'd0 )
			ball_y_v <= -4;
	    else if ( (ball_player_up_hit_bord || ball_player_left_hit_bord || ball_player_right_hit_bord && player_smash) || (ball_ai_up_hit_bord || ball_ai_left_hit_bord || ball_ai_right_hit_bord && ai_smash) && ball_player_cd==27'd0 )
	        ball_y_v <= 2;
        else if (ball_phy_clk==27'd25000000)
            ball_y_v <= ball_y_v+1;
    end
end     

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// check if jumpable
always @(posedge clk) begin
    if(~reset_n || P != GAME_SCENE|| touched_ground )
        player_can_jump <= 0;
    else if (btn_pressed[3] && player_can_jump )
        player_can_jump <= 0;
    else if( player_bot_bord )
        player_can_jump <= 1;
end

always @(posedge clk) begin
    if(~reset_n || P != GAME_SCENE || touched_ground )
        ai_can_jump <= 0;
    else if ( ball_ai_up_hit_bord && ai_can_jump )
        ai_can_jump <= 0;
    else if( ai_bot_bord )
        ai_can_jump <= 1;
end

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// player_phy_clk for gravity
always @(posedge clk) begin
    if( ~reset_n || P != GAME_SCENE || touched_ground )
        player_phy_clk <= 0;
    else if ( player_top_bord || player_can_jump )
        player_phy_clk[27:0] <= 0;
    else
        player_phy_clk <= (player_phy_clk==27'd25000000) ? 0 : player_phy_clk+1;
end

// ai_phy_clk for gravity
always @(posedge clk) begin
    if( ~reset_n || P != GAME_SCENE || touched_ground )
        ai_phy_clk <= 0;
    else if ( ai_top_bord || ai_can_jump )
        ai_phy_clk[27:0] <= 0;
    else
        ai_phy_clk <= (ai_phy_clk==27'd25000000) ? 0 : ai_phy_clk+1;
end

// ball_phy_clk for gravity
always @(posedge clk) begin
    if( ~reset_n || P != GAME_SCENE || touched_ground )
        ball_phy_clk <= 0;
    else if ( ball_top_bord|| ball_bot_bord )
        ball_phy_clk[27:0] <= 27'd25000000 - ball_phy_clk[27:0];
	else if ( ball_player_left_hit_bord|| ball_player_up_hit_bord ||ball_player_right_hit_bord)
        ball_phy_clk[27:0] <= 27'd25000000 - ball_phy_clk[27:0];
    else
        ball_phy_clk <= (ball_phy_clk==27'd25000000) ? 0 : ball_phy_clk+1;
end

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------------------------------
// display

//start menu
reg[3:0] player_score;
reg[3:0] cpu_score;
reg[1:0] start_select, skin_select; 
wire [11:0] skin_chosed[1:3];
reg[3:0] show_msg;
reg[3:0] show_instruct;

// clocks
reg [32:0] pause_clk; // game_ready_clk
reg  [32:0] auto_clock; //auto clk

// game_ready_clk
always @(posedge clk)begin
	if( ~reset_n || P==START_SCENE || touched_ground  )
		pause_clk<=0;
	else
		pause_clk<= (pause_clk==200000000) ? 0 : pause_clk + 1;
end

//auto clk
always @(posedge clk) begin
    if ( ~reset_n )  auto_clock <= 0; 
    else auto_clock <= auto_clock + 1;
end

//assign sram_addr[1] = P == ? (skin_region[1] ? skin_loc[1] : skin_region[2] ? skin_loc[2] : skin_region[3] ? skin_loc[3]) : (player_region[1] ? player_loc : ai_loc);
//memory data location
assign sram_addr[0] = beach_loc;
assign sram_addr[1] = (P == SKIN_SCENE) ? (skin_region[1] ? skin_loc[1] : skin_region[2] ? skin_loc[2] : skin_loc[3]) : (player_region[1] ? player_loc : ai_loc);
assign sram_addr[2] = ball_loc;
assign sram_addr[3] = options_start_region[1] ? options_start_loc : options_skin_loc;
assign sram_addr[4] = score_region[1] ? score_loc[1] : score_loc[2];
assign sram_addr[5] = announce_loc[1];
assign sram_addr[6] = instruct_loc[1];

always @ (posedge clk) begin
    if (~reset_n)
        player_loc <= 0;
    else  if (player_region[1])
        player_loc <= player_addr[auto_clock[24:23]] + ((pixel_y - player_ypos[1] + 2*player_H - 1)>>1)*player_W + ((pixel_x - player_xpos[1] + 2*player_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        ai_loc <= 0;
    else  if (ai_region[1])
        ai_loc <= ai_addr[auto_clock[24:23]] + ((pixel_y - ai_ypos[1] + 2*player_H - 1)>>1)*player_W + ((ai_xpos[1] - pixel_x)>>1);
 end
always @ (posedge clk) begin
    if (~reset_n )
        ball_loc <= 0;
    else  if (ball_region[1])
        ball_loc <= ball_addr[ball_x_clock[25:24]] + ((pixel_y - ball_ypos[1] + 2*ball_H - 1)>>1)*ball_W + ((ball_xpos[1] - pixel_x)>>1);
end
always @ (posedge clk) begin
    if (~reset_n )
        options_start_loc <= 0;
    else  if (options_start_region[1])
        options_start_loc <= options_addr[0] + ((pixel_y - options_ypos[1] + 2*options_H - 1)>>1)*options_W + ((pixel_x - options_xpos[1] + 2*options_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n )
        options_skin_loc <= 0;
    else  if (options_skin_region[1])
        options_skin_loc <= options_addr[1] + ((pixel_y - options_ypos[2] + 2*options_H - 1)>>1)*options_W + ((pixel_x - options_xpos[2] + 2*options_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        beach_loc <= 0;
    else 
        beach_loc <= (pixel_y >> 1) * beach_W + (pixel_x >> 1);
end
always @ (posedge clk) begin
    if (~reset_n )
        score_loc[1] <= 0;
    else  if (score_region[1])
        score_loc[1] <= score_addr[cpu_score] + ((pixel_y - score_ypos[1] + 2*score_H - 1)>>1)*score_W + ((pixel_x - score_xpos[1] + 2*score_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n )
        score_loc[2] <= 0;
    else  if (score_region[2])
        score_loc[2] <= score_addr[player_score] + ((pixel_y - score_ypos[2] + 2*score_H - 1)>>1)*score_W + ((pixel_x - score_xpos[2] + 2*score_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        skin_loc[1] <= 0;
    else  if (skin_region[1])
        skin_loc[1] <= skin_addr[auto_clock[24:23]] + ((pixel_y - skin_ypos[1] + 2*player_H - 1)>>1)*player_W + ((pixel_x - skin_xpos[1] + 2*player_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        skin_loc[2] <= 0;
    else  if (skin_region[2])
        skin_loc[2] <= skin_addr[auto_clock[24:23]] + ((pixel_y - skin_ypos[2] + 2*player_H - 1)>>1)*player_W + ((pixel_x - skin_xpos[2] + 2*player_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        skin_loc[3] <= 0;
    else  if (skin_region[3])
        skin_loc[3] <= skin_addr[auto_clock[24:23]] + ((pixel_y - skin_ypos[3] + 2*player_H - 1)>>1)*player_W + ((pixel_x - skin_xpos[3] + 2*player_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        announce_loc[1] <= 0;
    else  if (announce_region[1])
        announce_loc[1] <= announce_addr[show_msg] + ((pixel_y - announce_ypos[1] + 2*announce_H - 1)>>1)*announce_W + ((pixel_x - announce_xpos[1] + 2*announce_W - 1)>>1);
end
always @ (posedge clk) begin
    if (~reset_n)
        instruct_loc[1] <= 0;
    else  if (instruct_region[1])
        instruct_loc[1] <= instruct_addr[show_instruct] + ((pixel_y - instruct_ypos[1] + 2*instruct_H - 1)>>1)*instruct_W + ((pixel_x - instruct_xpos[1] + 2*instruct_W - 1)>>1);
end


// ------------------------------------------------------------------------------------------------------------------------------------------------
// check display range (cutout green back)
assign player_green[1] = (data_out[1]==12'h0f0);
assign ai_green[1] = (data_out[1]==12'h0f0);
assign ball_green[1] = (data_out[2]==12'h0f0);
assign options_start_green[1] = (data_out[3]==12'h0f0);
assign options_skin_green[1] = (data_out[3]==12'h0f0);
assign score_green[1]  = (data_out[4]==12'h0f0);
assign score_green[2]  = (data_out[4]==12'h0f0);
assign skin_green[1] = (data_out[1]==12'h0f0);
assign skin_green[2] = (data_out[1]==12'h0f0);
assign skin_green[3] = (data_out[1]==12'h0f0);
assign announce_green[1] = (data_out[5]==12'h0f0);
assign instruct_green[1] = (data_out[6]==12'h0f0);

assign player_region[1] = (
            pixel_x + player_W*2 > player_xpos[1] && pixel_x <= player_xpos[1] &&
            pixel_y + player_H*2 > player_ypos[1] && pixel_y <= player_ypos[1] 
        );
assign ai_region[1] = (
            pixel_x + player_W*2 > ai_xpos[1] && pixel_x <= ai_xpos[1] &&
            pixel_y + player_H*2 > ai_ypos[1] && pixel_y <= ai_ypos[1] 
        );

assign ball_region[1] = (
            pixel_x + ball_W*2 > ball_xpos[1] && pixel_x <= ball_xpos[1] &&
            pixel_y + ball_H*2 > ball_ypos[1] && pixel_y <= ball_ypos[1] 
        );
        

assign options_start_region[1] = (
            pixel_x + options_W*2 > options_xpos[1] && pixel_x <= options_xpos[1] &&
            pixel_y + options_H*2 > options_ypos[1] && pixel_y <= options_ypos[1] 
        );
        
assign options_skin_region[1] = (
            pixel_x + options_W*2 > options_xpos[2] && pixel_x <= options_xpos[2] &&
            pixel_y + options_H*2 > options_ypos[2] && pixel_y <= options_ypos[2] 
        );
        
assign score_region[1] = (
            pixel_x + score_W*2 > score_xpos[1] && pixel_x <= score_xpos[1] &&
            pixel_y + score_H*2 > score_ypos[1] && pixel_y <= score_ypos[1] 
        );
        
assign score_region[2] = (
            pixel_x + score_W*2 > score_xpos[2] && pixel_x <= score_xpos[2] &&
            pixel_y + score_H*2 > score_ypos[2] && pixel_y <= score_ypos[2] 
        );
        
assign skin_region[1] = (
            pixel_x + player_W*2 > skin_xpos[1] && pixel_x <= skin_xpos[1] &&
            pixel_y + player_H*2 > skin_ypos[1] && pixel_y <= skin_ypos[1] 
        );
 
assign skin_region[2] = (
            pixel_x + player_W*2 > skin_xpos[2] && pixel_x <= skin_xpos[2] &&
            pixel_y + player_H*2 > skin_ypos[2] && pixel_y <= skin_ypos[2] 
        );
        
assign skin_region[3] = (
            pixel_x + player_W*2 > skin_xpos[3] && pixel_x <= skin_xpos[3] &&
            pixel_y + player_H*2 > skin_ypos[3] && pixel_y <= skin_ypos[3] 
        );
        
assign announce_region[1] = (
            pixel_x + announce_W*2 > announce_xpos[1] && pixel_x <= announce_xpos[1] &&
            pixel_y + announce_H*2  > announce_ypos[1] && pixel_y <= announce_ypos[1] 
        );
        
assign instruct_region[1] = (
            pixel_x + instruct_W*2 > instruct_xpos[1] && pixel_x <= instruct_xpos[1] &&
            pixel_y + instruct_H*2  > instruct_ypos[1] && pixel_y <= instruct_ypos[1] 
        );
 
        

wire body[1:11];
assign body[1] = player_region[1] && ~player_green[1] ; 
assign body[2] = ball_region[1] && ~ball_green[1] ;
assign body[5] = ai_region[1] && ~ai_green[1];
assign body[3] = options_start_region[1] && ~options_start_green[1] ;
assign body[4] = options_skin_region[1] && ~options_skin_green[1] ;
assign body[6] = score_region[1] && ~score_green[1] || score_region[2] && ~score_green[2];
assign body[7] = skin_region[1] && ~skin_green[1] ;
assign body[8] = skin_region[2] && ~skin_green[2] ;
assign body[9] = skin_region[3] && ~skin_green[3] ;
assign body[10]=announce_region[1] && ~announce_green[1] ;
assign body[11]=instruct_region[1] && ~instruct_green[1] ;

wire [11:0] ball_color;
wire [11:0] ball_display = ( (ball_x_v > 4) && (data_out[2]==12'he12) ) ? ball_color : data_out[2];
assign ball_color[3:0]  = ball_x_clock[31:28] > 4'h2 ? ball_x_clock[31:28] : 4'h2;
assign ball_color[7:4]  = ball_x_clock[27:24] > 4'h2 ? ball_x_clock[27:24] : 4'h2;
assign ball_color[11:8] = ball_x_clock[23:20] > 4'h2 ? ball_x_clock[23:20] : 4'h2;

wire [11:0] player_color[1:3];
assign player_color[1] = (data_out[1]==12'hff0) ?  12'hf00   :   (data_out[1]==12'hf00) ? 12'hff0   :   data_out[1];
assign player_color[2] = data_out[1];
assign player_color[3] = ~data_out[1];
assign game_color_out = ( body[6]  ?  data_out[4] : ( body[2] ?  ball_display :  ( body[5]? data_out[1]/2 :  ( body[1] ? player_color[skin_select]  : data_out[0] ) ) ) );
// ------------------------------------------------------------------------------------------------------------------------------------------------

//scoreboard
// ------------------------------------------------------------------------------------------------------------------------------------------------
//localparam [2:0]  START_SCENE=0, SKIN_SCENE=1, GAME_SCENE=2, PLAYER_WIN=3, PLAYER_LOSE=4;
//integer player_score;
//integer cpu_score;
//assign usr_led = P; 

//scoreboard
wire touched_player_ground = ball_bot_bord && ball_x_clock[31:20] > (beach_W + ball_W); 
wire touched_cpu_ground = ball_bot_bord && ball_x_clock[31:20] < (beach_W + ball_W); 

always @(posedge clk) begin
    if (~reset_n)
        P <= START_SCENE; 
    else
        P <= P_next;
end
//localparam [2:0]  START_SCENE=0, SKIN_SCENE=1, GAME_START_SCENE=2, READY_SCENE=3, GAME_SCENE=4, GAME_SET=5, PLAYER_WIN=6, PLAYER_LOSE=7;
always @(*) begin // FSM next-state logic
    case (P)
        START_SCENE: // send an address to the SRAM
            if(btn_pressed[0] && start_select == 0 ) P_next = GAME_START_SCENE;
            else if(btn_pressed[0] && start_select == 1 ) P_next = SKIN_SCENE;
            else P_next=START_SCENE;
        SKIN_SCENE: // fetch the sample from the SRAM
            if(btn_pressed[0]) P_next = START_SCENE;
            else P_next=SKIN_SCENE;
        GAME_START_SCENE:
            if( pause_clk==200000000 ) P_next = READY_SCENE;
            else P_next=GAME_START_SCENE;
        READY_SCENE:
            if( pause_clk==200000000 ) P_next = GAME_SCENE;
            else P_next=READY_SCENE;
        GAME_SCENE:
            if ( (player_score==4 && touched_cpu_ground) || (cpu_score==4 && touched_player_ground) ) P_next = GAME_SET;
            else if ( touched_ground ) P_next = READY_SCENE;
            else P_next=GAME_SCENE;
        GAME_SET:
                if ( pause_clk==200000000 && player_score==5) P_next = PLAYER_WIN;
                else if ( pause_clk==200000000 && cpu_score==5) P_next = PLAYER_LOSE;
            else P_next=GAME_SET;
        PLAYER_WIN:
            if (btn_pressed[0]) P_next = START_SCENE;
            else P_next = PLAYER_WIN;
        PLAYER_LOSE:
            if (btn_pressed[0]) P_next = START_SCENE;
            else P_next = PLAYER_LOSE;
    endcase
end

always @(posedge clk) begin
    if (~reset_n )
        show_msg <=1;
    else if (P==GAME_START_SCENE)
        show_msg<=1;
    else  if (P==READY_SCENE)
        show_msg<=0;
    else  if (P==GAME_SET)
        show_msg<=2;
    else  if (P==PLAYER_WIN)
        show_msg<=3;
     else  if (P==PLAYER_LOSE)
        show_msg<=4;
    else
        show_msg<=1;
end

always @(posedge clk) begin
    if (~reset_n )
        show_instruct <= 0;
    else if (P==START_SCENE)
        show_instruct<= 1;
    else  if (P==SKIN_SCENE)
        show_instruct<=2;
    else
        show_instruct<=3;
end

always @(posedge clk) begin
    if (~reset_n || P < GAME_START_SCENE ) 
        last_score<=0;  
    else if (touched_cpu_ground)
        last_score<=1;
    else if (touched_player_ground)
        last_score<=0;  
end

always @(posedge clk) begin
    if (~reset_n || P < GAME_START_SCENE ) begin
        player_score <= 0;
        cpu_score <= 0;
    end
    else if (touched_cpu_ground)
        player_score <= player_score + 1;
    else if (touched_player_ground)
        cpu_score <= cpu_score + 1;  
end

always @(posedge clk) begin
    if (~reset_n )
        start_select <= 0;
    else if (btn_pressed[2] && P==START_SCENE )
        start_select <= 0;
    else if (btn_pressed[1] && P==START_SCENE )
        start_select <= 1; 
end

always @(posedge clk) begin
    if (~reset_n)
        skin_select <= 2;
    else if (btn_pressed[3] && P == SKIN_SCENE )
        skin_select <= skin_select==1 ? skin_select : skin_select-1;
    else if (btn_pressed[2] && P == SKIN_SCENE )
        skin_select <= skin_select==3 ? skin_select : skin_select+1; 
end

//start menu display
assign skin_chosed[1] = skin_select==1 ? ( !skin_green[1] ? player_color[1] : 12'h556) : (!skin_green[1] ? player_color[1] : 12'h445);
assign skin_chosed[2] = skin_select==2 ? ( !skin_green[2] ? player_color[2] : 12'h556) : (!skin_green[2] ? player_color[2] : 12'h445);
assign skin_chosed[3] = skin_select==3 ? ( !skin_green[3] ? player_color[3] : 12'h556) : (!skin_green[3] ? player_color[3] : 12'h445);

wire [11:0] start_background;
assign  start_background[11:8] = data_out[0][11:8] >= 4'hc ? 4'hf  : data_out[0][11:8] + 3;
assign  start_background[7:4] = data_out[0][7:4] >= 4'hc ? 4'hf  : data_out[0][7:4] + 3;
assign  start_background[3:0] = data_out[0][3:0] >= 4'hc ? 4'hf  : data_out[0][3:0] + 3;

wire [11:0] start_menu_color_out = body[3] ? (!start_select ? ~data_out[3] : data_out[3] ) : body[4] ? (start_select ? ~data_out[3] : data_out[3] ) : start_background; //data_out[0];
wire [11:0] skin_menu_color_out = skin_region[1] ? (skin_chosed[1] )    :    skin_region[2] ? (skin_chosed[2])    :    skin_region[3]? (skin_chosed[3])    :   12'h445;

// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next <= 12'h000; // Synchronization period, must set RGB values to zero.
  else if (P==START_SCENE)
    rgb_next <= (body[11] && usr_sw[0]) ? data_out[6] : start_menu_color_out;
  else if (P==SKIN_SCENE)
    rgb_next <= (body[11] && usr_sw[0])? data_out[6] : skin_menu_color_out;
  else if (P==GAME_START_SCENE || P==READY_SCENE )
    rgb_next <= (body[11] && usr_sw[0])? data_out[6] : body[10] ? data_out[5] : game_color_out;
  else if ( P==GAME_SET || P==PLAYER_WIN || P==PLAYER_LOSE )
    rgb_next <= (body[11] && usr_sw[0])? data_out[6] : body[10] ? data_out[5] : start_background;
  else 
    rgb_next <= (body[11] && usr_sw[0])? data_out[6] : game_color_out; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------


endmodule