-- Listing 12.5
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

entity screen_unit is 
   port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(1 downto 0);
        video_on: in std_logic; -- from vga_sunc_unit 
        pixel_x,pixel_y: in std_logic_vector(9 downto 0); -- from vga_sunc_unit
        graph_rgb: out std_logic_vector(2 downto 0);
		  led: out std_logic_vector(7 downto 0);
		  sw: in std_logic_vector(2 downto 0);
		  ps2d, ps2c: inout std_logic;	-- Mouse inputs
		  -- I/O linked to main.vhdl
		  player_grid: in std_logic_vector(63 downto 0); -- grid with player boats
		  cube_row: out std_logic_vector(3 downto 0); -- what cube is the mouse overlapping
		  cube_col: out std_logic_vector(4 downto 0); -- what cube is the mouse overlapping
		  cpu_grid: in std_logic_vector(127 downto 0); -- 8x8 grid with two bits per position, represents the enemy's grid
				-- '00' default value, '01' position shot but has nothing, '10' position shot and hit, '11' boat destroyed in this position
		  player_hit_grid: in std_logic_vector(63 downto 0); -- 8x8 grid with the places the CPU shot
		  mouse_x_out, mouse_y_out: out std_logic_vector(9 downto 0);	-- Mouse outputs
		  btnm_out: out std_logic_vector(2 downto 0);
		  result: in std_logic_vector(1 downto 0);
		  main_menu_active: in std_logic
   );
end screen_unit;

architecture arch of screen_unit is
   signal refr_tick: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer:=640;
   constant MAX_Y: integer:=480;
   ----------------------------------------------
   -- GRID's
   ----------------------------------------------
	-- grid with 8x8 25px blocs, having 3 px walls between each
	-- total size = 35*8 +5 = 285 -> squre's will have 35px dim with a 8px border
	constant GRID_SIZE: integer:=288;
	constant GRID_Y_T: integer:=100;
	constant GRID_Y_B: integer:=GRID_Y_T + 288;
	constant GRID_X_L: integer:=2;
	constant GRID_X_R: integer:=GRID_X_L + 288;
	-- Same values for Y axis
	constant GRID2_X_L: integer:=2 + 288 + 10; -- left gap + grid size + middle gap
	constant GRID2_X_R: integer:=GRID2_X_L + 288;
   ----------------------------------------------
   -- Square's drawn on top of the grid, squre's have 35px dim with a 8px border
   ----------------------------------------------
	constant SQ_XY_DIM: integer:=30;
	constant SQ_BORDER: integer:=2;
	constant ORIG_OFFSET: integer:= SQ_XY_DIM + SQ_BORDER;
	constant GRID_TO_CUBE_OFFSET: integer:=16;
	
	--	Column 	 -\
	-- row. 1 . -> O O O O O O O O .... O O O O O O O O
	-- .....2..... O O O O O O O O .... O O O O O O O O
	-- .....3..... O O O O O O O O .... O O O O O O O O
	-- .....4..... O O O O O O O O .... O O O O O O O O
	-- .....5..... O O O O O O O O .... O O O O O O O O
	-- .....6..... O O O O O O O O .... O O O O O O O O
	-- .....7..... O O O O O O O O .... O O O O O O O O
	-- .....8..... O O O O O O O O .... O O O O O O O O
	
	constant SQ_X_1: integer:=GRID_X_L +2 + GRID_TO_CUBE_OFFSET;
	constant SQ_X_2: integer:=SQ_X_1 + ORIG_OFFSET;
	constant SQ_X_3: integer:=SQ_X_2 + ORIG_OFFSET;
	constant SQ_X_4: integer:=SQ_X_3 + ORIG_OFFSET;
	constant SQ_X_5: integer:=SQ_X_4 + ORIG_OFFSET;
	constant SQ_X_6: integer:=SQ_X_5 + ORIG_OFFSET;
	constant SQ_X_7: integer:=SQ_X_6 + ORIG_OFFSET;
	constant SQ_X_8: integer:=SQ_X_7 + ORIG_OFFSET;
	--
	constant SQ_X_9: integer:= GRID2_X_L +2 + GRID_TO_CUBE_OFFSET;
	constant SQ_X_10: integer:=SQ_X_9 + ORIG_OFFSET;
	constant SQ_X_11: integer:=SQ_X_10 + ORIG_OFFSET;
	constant SQ_X_12: integer:=SQ_X_11 + ORIG_OFFSET;
	constant SQ_X_13: integer:=SQ_X_12 + ORIG_OFFSET;
	constant SQ_X_14: integer:=SQ_X_13 + ORIG_OFFSET;
	constant SQ_X_15: integer:=SQ_X_14 + ORIG_OFFSET;
	constant SQ_X_16: integer:=SQ_X_15 + ORIG_OFFSET;
	--
	constant SQ_Y_1: integer:=GRID_Y_T + GRID_TO_CUBE_OFFSET;
	constant SQ_Y_2: integer:=SQ_Y_1 + ORIG_OFFSET;
	constant SQ_Y_3: integer:=SQ_Y_2 + ORIG_OFFSET;
	constant SQ_Y_4: integer:=SQ_Y_3 + ORIG_OFFSET;
	constant SQ_Y_5: integer:=SQ_Y_4 + ORIG_OFFSET;
	constant SQ_Y_6: integer:=SQ_Y_5 + ORIG_OFFSET;
	constant SQ_Y_7: integer:=SQ_Y_6 + ORIG_OFFSET;
	constant SQ_Y_8: integer:=SQ_Y_7 + ORIG_OFFSET;
	
   ----------------------------------------------
   -- menu text
   ----------------------------------------------
	-- constant vars for the title
   constant TITLE_CHARS: integer:= 10*8; -- size for all chars, 10 chars, 8pix each
   constant TITLE_X_L: integer:= 255;
   constant TITLE_X_R: integer:= TITLE_X_L + TITLE_CHARS;
   constant TITLE_Y_T: integer:= 63;
   constant TITLE_Y_B: integer:= TITLE_Y_T + 8;
	-- constant vars for the button
   constant CLICK_CHARS: integer:= 18*8; -- size for all chars
   constant CLICK_X_L: integer:= 223;
   constant CLICK_X_R: integer:= CLICK_X_L + CLICK_CHARS;
   constant CLICK_Y_T: integer:= 439;
   constant CLICK_Y_B: integer:= CLICK_Y_T + 8;
	-- constant vars for the result
   constant RESULT_CHARS: integer:= 8*8; -- size for all chars
   constant RESULT_X_L: integer:= 263; -- 301 - 4*8 = 269, num + prox=264
   constant RESULT_X_R: integer:= RESULT_X_L + RESULT_CHARS;
   constant RESULT_Y_T: integer:= 199;
   constant RESULT_Y_B: integer:= RESULT_Y_T + 8;
	
	constant WBOX_X_BORDER: integer:= 15;
	constant WBOX_Y_BORDER: integer:= 15;
   constant WBOX_X_L: integer:= CLICK_X_L - WBOX_X_BORDER;
   constant WBOX_X_R: integer:= CLICK_X_R + WBOX_X_BORDER;
   constant WBOX_Y_T: integer:= CLICK_Y_T - WBOX_Y_BORDER;
   constant WBOX_Y_B: integer:= CLICK_Y_B + WBOX_Y_BORDER;
	
	constant YBOX_X_BORDER: integer:= 5;
	constant YBOX_Y_BORDER: integer:= 5;
   constant YBOX_X_L: integer:= WBOX_X_L - YBOX_X_BORDER;
   constant YBOX_X_R: integer:= WBOX_X_R + YBOX_X_BORDER;
   constant YBOX_Y_T: integer:= WBOX_Y_T - YBOX_Y_BORDER;
   constant YBOX_Y_B: integer:= WBOX_Y_B + YBOX_Y_BORDER;
	constant YBOX_RGB: std_logic_vector(2 downto 0):="110";
	
   ----------------------------------------------
   -- square ball
   ----------------------------------------------
   constant BALL_SIZE: integer:=8; -- 8
   -- ball left, right boundary
   signal ball_x_l, ball_x_r: unsigned(9 downto 0);
   -- ball top, bottom boundary
   signal ball_y_t, ball_y_b: unsigned(9 downto 0);
   -- reg to track left, top boundary
   signal ball_x_reg, ball_x_next: unsigned(9 downto 0);
   signal ball_y_reg, ball_y_next: unsigned(9 downto 0);
   -- ball velocity can be pos or neg)
   constant BALL_V_P: unsigned(9 downto 0)
            :=to_unsigned(2,10);
   constant BALL_V_N: unsigned(9 downto 0)
            :=unsigned(to_signed(-2,10));
   ----------------------------------------------
   -- round ball image ROM, mouse pointer
   ----------------------------------------------
   type rom_type is array (0 to 7)
        of std_logic_vector(0 to 7);
   -- ROM definition
	constant BALL_ROM: rom_type := -- 8x8 px
   (
      "00011111", -- **    
      "00111111", -- ****   
      "00000111", -- *****   
      "00001011", -- ******  
      "00010011", -- ******* 
      "00100010", -- *  **   
      "01000000", --    *** 
      "00000000"  --     **  
   );
   signal rom_addr, rom_col: unsigned(2 downto 0);
   signal rom_data: std_logic_vector(7 downto 0);
   signal rom_bit: std_logic;
	----------------------------------------------
   -- round ball image ROM
   ----------------------------------------------
   type rom_type_boat is array (0 to 19)
        of std_logic_vector(0 to 19);
   -- ROM definition
	constant BOAT_MISS_ROM: rom_type_boat := -- 
   (
      "00000000000000000000",
		"00000001111110000000",
		"00000111111111100000",
		"00001111111111110000",
		"00011111000011111000",
		"00111100000000111100",
		"00111000000000011100",
		"01111000000000011110",
		"01110000000000001110",
		"01110000000000001110",
		"01110000000000001110",
		"01110000000000001110",
		"01111000000000011110",
		"00111000000000011100",
		"00111100000000111100",
		"00011111000011111000",
		"00001111111111110000",
		"00000111111111100000",
		"00000001111110000000",
		"00000000000000000000"
   );
   signal rom_data_boat_miss: std_logic_vector(19 downto 0);
   signal rom_bit_boat_miss: std_logic;
   -- ROM definition
	constant BOAT_HIT_ROM: rom_type_boat := -- 
   (
		"00000000000000000000",
		"00000001111110000000",
		"00000111111111100000",
		"00001111111111110000",
		"00011111111111111000",
		"00111111111111111100",
		"00111111111111111100",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"00111111111111111100",
		"00111111111111111100",
		"00011111111111111000",
		"00001111111111110000",
		"00000111111111100000",
		"00000001111110000000",
		"00000000000000000000"
   );
   signal rom_data_boat_hit: std_logic_vector(19 downto 0);
   signal rom_bit_boat_hit: std_logic;
   -- ROM definition
--	constant BOAT_SUNK_ROM: rom_type_boat := -- 
--   (
--		"00000000000000000000",
--		"00000001111110000000",
--		"00000111111111100000",
--		"00001111111111110000",
--		"00011111011011111000",
--		"00111100011000111100",
--		"00111000011000011100",
--		"01111000011000011110",
--		"01110000011000001110",
--		"01111111111111111110",
--		"01111111111111111110",
--		"01110000011000001110",
--		"01111000011000011110",
--		"00111000011000011100",
--		"00111100011000111100",
--		"00011111011011111000",
--		"00001111111111110000",
--		"00000111111111100000",
--		"00000001111110000000",
--		"00000000000000000000"
--   );
--   signal rom_data_boat_sunk: std_logic_vector(19 downto 0);
--   signal rom_bit_boat_sunk: std_logic;
   -- ROM definition
	constant BOAT_ICON_ROM: rom_type_boat := -- 
   (
		"00000000000000000000",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"01111111111111111110",
		"00000000000000000000"
   );
   signal rom_data_boat_icon: std_logic_vector(19 downto 0);
   signal rom_bit_boat_icon: std_logic;
	
   signal rom_addr_boat, rom_col_boat: unsigned(4 downto 0); -- 4 bits
	signal grid_pos: integer;
	signal object_x_pos, object_y_pos:  std_logic_vector(9 downto 0);
	signal boat_icon_on, boat_hit_on, boat_miss_on: std_logic; --boat_sunk_on
	signal boat_icon_sq, boat_hit_sq, boat_miss_sq: std_logic; --boat_sunk_sq
	signal boat_icon_rgb, boat_hit_rgb, boat_miss_rgb: std_logic_vector(2 downto 0);  --boat_sunk_rgb 
   ----------------------------------------------
   -- object output signals
   ----------------------------------------------
   signal  wall_on,  block_on, sq_ball_on, rd_ball_on: std_logic;
   signal wall_rgb, block_rgb, ball_rgb, menu_font_rgb:
          std_logic_vector(2 downto 0);
   ----------------------------------------------
   -- Mouse inputs
   ----------------------------------------------
   signal xm_c_reg,xm_c_next,ym_c_reg,ym_c_next: std_logic_vector(9 downto 0);
   signal ym: std_logic_vector(8 downto 0);
   signal xm: std_logic_vector(8 downto 0);
   signal btnm: std_logic_vector(2 downto 0);   
   signal m_done_tick: std_logic;
   ----------------------------------------------
   -- Menu vars
   ----------------------------------------------
    signal font_addr: std_logic_vector(8 downto 0);
    signal font_data: std_logic_vector(0 to 7);
	 signal text_font_addr: std_logic_vector(8 downto 0);
    signal text_enable, font_pixel, text_en2, text_en3, menu_font_on: std_logic;
	 -- for the box behind the text
	 signal menu_wbox_on: std_logic;
	 signal wbox_rgb: std_logic_vector(2 downto 0);
   ----------------------------------------------
   -- Game, square's vars
   ----------------------------------------------
	 signal sq_row: std_logic_vector(3 downto 0); -- 8 posicoes + 1 bit para informar que nao estao a ser desenhados os cubos
	 signal ms_row: std_logic_vector(3 downto 0); -- 
	 signal sq_col: std_logic_vector(4 downto 0); -- 16 posicoes + 1 bit para informar que nao estao a ser desenhados os cubos
	 signal ms_col: std_logic_vector(4 downto 0);
	 signal sw012: std_logic_vector(2 downto 0);
begin
   -- instantiation
   mouse_unit: entity work.mouse(arch)
      port map(clk=>clk, reset=>reset,
               ps2d=>ps2d, ps2c=>ps2c,
               xm=>xm, ym=>ym, btnm=>btnm,
               m_done_tick=>m_done_tick);
	
	-- export btnm, used by main_unit
	btnm_out <= btnm;
--	led <= "11110000" when btnm(0)='1' else -- left
--			 "00001111" when btnm(1)='1' else -- right
--			 "00011000" when btnm(2)='1' else -- midle
--			 "10000001";
	 
	-- instantiation characters
	char_rom: entity work.char_rom(content)
		port map(addr => font_addr, data => font_data);
		
   -- registers @clock updater
   process (clk,reset)
   begin
      if reset='1' then
         ball_x_reg <= (others=>'0');
         ball_y_reg <= (others=>'0');
			xm_c_reg <= (others=>'0');
			ym_c_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         ball_x_reg <= ball_x_next;
         ball_y_reg <= ball_y_next;
			xm_c_reg <= xm_c_next;
			ym_c_reg <= ym_c_next;
      end if;
   end process;
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
   ----------------------------------------------
   --  Title(menu)
   ----------------------------------------------
	text_enable <= '1' when ((TITLE_X_L<=pix_x) and (pix_x<=TITLE_X_R) and	-- set where the text should be draw
									 (TITLE_Y_T<=pix_y) and (pix_y<=TITLE_Y_B)) else
						'0';
	text_en2 <= '1' when (CLICK_X_L<=pix_x) and (pix_x<=CLICK_X_R) and	-- 18 chars, "Click here to play"
								(CLICK_Y_T<=pix_y) and (pix_y<=CLICK_Y_B) else
					'0';
	text_en3 <= '1' when (RESULT_X_L<=pix_x) and (((pix_x<=(RESULT_X_R-8)) and result="01") or ((pix_x<=RESULT_X_R) and result="10")) and	-- 8 chars, "You won!" or "You lost"
								(RESULT_Y_T<=pix_y) and (pix_y<=RESULT_Y_B) else -- and not(result="00")
					'0';
	menu_font_on <= '1' when (text_enable='1' or text_en2='1' or text_en3='1') and font_pixel='1' and rd_ball_on='0' else -- enable text whitin limits when it has a pixel at '1'
						 '0';
	-- B is 13th position, i.e. position 12 (starting from 0). 12 base10 = 1100 base2
	text_font_addr <= "001100000" when pix_x(9 downto 3)= "0100000" and text_enable='1' else -- B -- 12 -- SUBTRAIR 54 na tabela ASCII para os caracteres
							"001011000" when pix_x(9 downto 3)= "0100001" and text_enable='1'  else -- A -- 11 
							"011110000" when pix_x(9 downto 3)= "0100010" and text_enable='1'  else -- T -- 30
							"011110000" when pix_x(9 downto 3)= "0100011" and text_enable='1'  else -- T -- 30
							"010110000" when pix_x(9 downto 3)= "0100100" and text_enable='1'  else -- L -- 22
							"001111000" when pix_x(9 downto 3)= "0100101" and text_enable='1'  else -- E -- 15
							"011101000" when pix_x(9 downto 3)= "0100110" and text_enable='1'  else -- S -- 29
							"010010000" when pix_x(9 downto 3)= "0100111" and text_enable='1'  else -- H -- 18
							"010011000" when pix_x(9 downto 3)= "0101000" and text_enable='1'  else -- I -- 19
							"011010000" when pix_x(9 downto 3)= "0101001" and text_enable='1'  else -- P -- 26
							"001101000" when pix_x(9 downto 3)= "0011100" and text_en2='1'  else -- C -- 13
							"010110000" when pix_x(9 downto 3)= "0011101" and text_en2='1'  else -- L -- 22
							"010011000" when pix_x(9 downto 3)= "0011110" and text_en2='1'  else -- I -- 19
							"001101000" when pix_x(9 downto 3)= "0011111" and text_en2='1'  else -- C -- 13
							"010101000" when pix_x(9 downto 3)= "0100000" and text_en2='1'  else -- K -- 21
							"100101000" when pix_x(9 downto 3)= "0100001" and text_en2='1'  else -- 36
							"010010000" when pix_x(9 downto 3)= "0100010" and text_en2='1'  else -- H -- 18 
							"001111000" when pix_x(9 downto 3)= "0100011" and text_en2='1'  else -- E -- 15
							"011100000" when pix_x(9 downto 3)= "0100100" and text_en2='1'  else -- R -- 28
							"001111000" when pix_x(9 downto 3)= "0100101" and text_en2='1'  else -- E -- 15
							"100101000" when pix_x(9 downto 3)= "0100110" and text_en2='1'  else -- 36
							"011110000" when pix_x(9 downto 3)= "0100111" and text_en2='1'  else -- T -- 30
							"011001000" when pix_x(9 downto 3)= "0101000" and text_en2='1'  else -- O -- 25
							"100101000" when pix_x(9 downto 3)= "0101001" and text_en2='1'  else -- 36
							"011010000" when pix_x(9 downto 3)= "0101010" and text_en2='1'  else -- P -- 26
							"010110000" when pix_x(9 downto 3)= "0101011" and text_en2='1'  else -- L -- 22
							"001011000" when pix_x(9 downto 3)= "0101100" and text_en2='1'  else -- A -- 11
							"100011000" when pix_x(9 downto 3)= "0101101" and text_en2='1'  else -- Y -- 35
							"100011000" when pix_x(9 downto 3)= "0100001" and text_en3='1'   else -- Y -- 35
							"011001000" when pix_x(9 downto 3)= "0100010" and text_en3='1'   else -- O -- 25
							"011111000" when pix_x(9 downto 3)= "0100011" and text_en3='1'   else -- U -- 31
							"100101000" when pix_x(9 downto 3)= "0100100" and text_en3='1'   else -- 36
							"100001000" when pix_x(9 downto 3)= "0100101" and text_en3='1' and result="01" else -- W -- 33
							"011001000" when pix_x(9 downto 3)= "0100110" and text_en3='1' and result="01" else -- O -- 25
							"011000000" when pix_x(9 downto 3)= "0100111" and text_en3='1' and result="01" else -- N -- 24
							"010110000" when pix_x(9 downto 3)= "0100101" and text_en3='1' and result="10" else -- L -- 22
							"011001000" when pix_x(9 downto 3)= "0100110" and text_en3='1' and result="10" else -- O -- 25
							"011101000" when pix_x(9 downto 3)= "0100111" and text_en3='1' and result="10" else -- S -- 29
							"011110000" when pix_x(9 downto 3)= "0101000" and text_en3='1' and result="10" else -- T -- 30
							(others=>'0');

	menu_font_rgb <= "000" when text_en3='0' else -- text color
						  "010" when result="01" else -- green
						  "100";	-- red
	
   ----------------------------------------------
   --  Start button box (menu)
   ----------------------------------------------
   -- pixel within wall
   menu_wbox_on <=
      '1' when (rd_ball_on='0' and (font_pixel='0' or text_en2='0')) and 
					(((YBOX_X_L<=pix_x) and (pix_x<=YBOX_X_R) and (YBOX_Y_T<=pix_y) and (pix_y<=YBOX_Y_B)) ) else -- grid 2
      '0';
		-- usar cores diferentes para caixa e contorno, a dimensao e YBOX_X_L YBOX_X_R YBOX_Y_T YBOX_Y_B, WBOX e' mais pequena
	wbox_rgb <= "111" when (((WBOX_X_L<=pix_x)       and       (pix_x<=WBOX_X_R) and (WBOX_Y_T<=pix_y)       and       (pix_y<=WBOX_Y_B))) else -- white 
					"100" when (((WBOX_X_L<=ball_x_reg) and (ball_x_reg<=WBOX_X_R) and (WBOX_Y_T<=ball_y_reg) and (ball_y_reg<=WBOX_Y_B))) else -- red
					"000";
   ----------------------------------------------
   --  Shared code for printing characters
   ----------------------------------------------
	
	font_addr <= std_logic_vector(unsigned(pix_y(2 downto 0)) + unsigned(text_font_addr))   
						when   (text_enable = '1' or text_en2 = '1' or text_en3 = '1') else
						(others => '0');
					 
	font_pixel	<= std_logic(font_data(to_integer(pix_x(2 downto 0)))); -- is '1' if character pixel is defined as '1' in char_rom, otherwise '0'
	
   ----------------------------------------------
   -- ( ) block / cube ...
   ----------------------------------------------
	block_on <= '1' when not((sq_row="1000") or (sq_col="10000") or boat_miss_on='1' or boat_icon_on='1' or boat_hit_on='1') else -- or boat_sunk_on='1'
					'0';
	block_rgb <= "110" when (sq_row=ms_row) and (sq_col=ms_col) and sq_col<"01000" else	-- yellow
					 "011"; -- cyan
	-- @todo use this to detect the row being drawn, do something identical to the mouse, and also for x axis
	-- detetar qual dos cubos a ser atualmente desenhado, util para saber o que desenhar em cada cubo
	-- tambem para depois comparar se o rato esta sobreposto
	sq_row <=	-- what row of "cubes" being drawn?
      "0000" when ((SQ_Y_1<=pix_y) and (pix_y<=SQ_Y_1+SQ_XY_DIM-1)) else -- row 1
      "0001" when ((SQ_Y_2<=pix_y) and (pix_y<=SQ_Y_2+SQ_XY_DIM-1)) else -- row 2
      "0010" when ((SQ_Y_3<=pix_y) and (pix_y<=SQ_Y_3+SQ_XY_DIM-1)) else -- row 3
      "0011" when ((SQ_Y_4<=pix_y) and (pix_y<=SQ_Y_4+SQ_XY_DIM-1)) else -- row 4
      "0100" when ((SQ_Y_5<=pix_y) and (pix_y<=SQ_Y_5+SQ_XY_DIM-1)) else -- row 5
      "0101" when ((SQ_Y_6<=pix_y) and (pix_y<=SQ_Y_6+SQ_XY_DIM-1)) else -- row 6
      "0110" when ((SQ_Y_7<=pix_y) and (pix_y<=SQ_Y_7+SQ_XY_DIM-1)) else -- row 7
      "0111" when ((SQ_Y_8<=pix_y) and (pix_y<=SQ_Y_8+SQ_XY_DIM-1)) else -- row 8
      "1000" ;	-- not in the row
		
	sq_col <=	-- what column of "cubes" being drawn? 
      "00000" when ((SQ_X_1<=pix_x) and (pix_x<=SQ_X_1+SQ_XY_DIM-1)) else -- row 1
      "00001" when ((SQ_X_2<=pix_x) and (pix_x<=SQ_X_2+SQ_XY_DIM-1)) else -- row 2
      "00010" when ((SQ_X_3<=pix_x) and (pix_x<=SQ_X_3+SQ_XY_DIM-1)) else -- row 3
      "00011" when ((SQ_X_4<=pix_x) and (pix_x<=SQ_X_4+SQ_XY_DIM-1)) else -- row 4
      "00100" when ((SQ_X_5<=pix_x) and (pix_x<=SQ_X_5+SQ_XY_DIM-1)) else -- row 5
      "00101" when ((SQ_X_6<=pix_x) and (pix_x<=SQ_X_6+SQ_XY_DIM-1)) else -- row 6
      "00110" when ((SQ_X_7<=pix_x) and (pix_x<=SQ_X_7+SQ_XY_DIM-1)) else -- row 7
      "00111" when ((SQ_X_8<=pix_x) and (pix_x<=SQ_X_8+SQ_XY_DIM-1)) else -- row 8
      "01000" when ((SQ_X_9<=pix_x) and (pix_x<=SQ_X_9+SQ_XY_DIM-1)) else -- row 9
      "01001" when ((SQ_X_10<=pix_x) and (pix_x<=SQ_X_10+SQ_XY_DIM-1)) else -- row 10
      "01010" when ((SQ_X_11<=pix_x) and (pix_x<=SQ_X_11+SQ_XY_DIM-1)) else -- row 11
      "01011" when ((SQ_X_12<=pix_x) and (pix_x<=SQ_X_12+SQ_XY_DIM-1)) else -- row 12
      "01100" when ((SQ_X_13<=pix_x) and (pix_x<=SQ_X_13+SQ_XY_DIM-1)) else -- row 13
      "01101" when ((SQ_X_14<=pix_x) and (pix_x<=SQ_X_14+SQ_XY_DIM-1)) else -- row 14
      "01110" when ((SQ_X_15<=pix_x) and (pix_x<=SQ_X_15+SQ_XY_DIM-1)) else -- row 15
      "01111" when ((SQ_X_16<=pix_x) and (pix_x<=SQ_X_16+SQ_XY_DIM-1)) else -- row 16
      "10000" ;	-- not in the row
		
	ms_row <=	-- 
      "0000" when ((SQ_Y_1<=ball_y_next) and (ball_y_next<=SQ_Y_1+SQ_XY_DIM-1)) else -- row 1
      "0001" when ((SQ_Y_2<=ball_y_next) and (ball_y_next<=SQ_Y_2+SQ_XY_DIM-1)) else -- row 2
      "0010" when ((SQ_Y_3<=ball_y_next) and (ball_y_next<=SQ_Y_3+SQ_XY_DIM-1)) else -- row 3
      "0011" when ((SQ_Y_4<=ball_y_next) and (ball_y_next<=SQ_Y_4+SQ_XY_DIM-1)) else -- row 4
      "0100" when ((SQ_Y_5<=ball_y_next) and (ball_y_next<=SQ_Y_5+SQ_XY_DIM-1)) else -- row 5
      "0101" when ((SQ_Y_6<=ball_y_next) and (ball_y_next<=SQ_Y_6+SQ_XY_DIM-1)) else -- row 6
      "0110" when ((SQ_Y_7<=ball_y_next) and (ball_y_next<=SQ_Y_7+SQ_XY_DIM-1)) else -- row 7
      "0111" when ((SQ_Y_8<=ball_y_next) and (ball_y_next<=SQ_Y_8+SQ_XY_DIM-1)) else -- row 8
      "1000" ;	-- not in the row
		
	ms_col <=	-- 
      "00000" when ((SQ_X_1<=ball_x_next) and (ball_x_next<=SQ_X_1+SQ_XY_DIM-1)) else -- row 1
      "00001" when ((SQ_X_2<=ball_x_next) and (ball_x_next<=SQ_X_2+SQ_XY_DIM-1)) else -- row 2
      "00010" when ((SQ_X_3<=ball_x_next) and (ball_x_next<=SQ_X_3+SQ_XY_DIM-1)) else -- row 3
      "00011" when ((SQ_X_4<=ball_x_next) and (ball_x_next<=SQ_X_4+SQ_XY_DIM-1)) else -- row 4
      "00100" when ((SQ_X_5<=ball_x_next) and (ball_x_next<=SQ_X_5+SQ_XY_DIM-1)) else -- row 5
      "00101" when ((SQ_X_6<=ball_x_next) and (ball_x_next<=SQ_X_6+SQ_XY_DIM-1)) else -- row 6
      "00110" when ((SQ_X_7<=ball_x_next) and (ball_x_next<=SQ_X_7+SQ_XY_DIM-1)) else -- row 7
      "00111" when ((SQ_X_8<=ball_x_next) and (ball_x_next<=SQ_X_8+SQ_XY_DIM-1)) else -- row 8
      "01000" when ((SQ_X_9<=ball_x_next) and (ball_x_next<=SQ_X_9+SQ_XY_DIM-1)) else -- row 9
      "01001" when ((SQ_X_10<=ball_x_next) and (ball_x_next<=SQ_X_10+SQ_XY_DIM-1)) else -- row 10
      "01010" when ((SQ_X_11<=ball_x_next) and (ball_x_next<=SQ_X_11+SQ_XY_DIM-1)) else -- row 11
      "01011" when ((SQ_X_12<=ball_x_next) and (ball_x_next<=SQ_X_12+SQ_XY_DIM-1)) else -- row 12
      "01100" when ((SQ_X_13<=ball_x_next) and (ball_x_next<=SQ_X_13+SQ_XY_DIM-1)) else -- row 13
      "01101" when ((SQ_X_14<=ball_x_next) and (ball_x_next<=SQ_X_14+SQ_XY_DIM-1)) else -- row 14
      "01110" when ((SQ_X_15<=ball_x_next) and (ball_x_next<=SQ_X_15+SQ_XY_DIM-1)) else -- row 15
      "01111" when ((SQ_X_16<=ball_x_next) and (ball_x_next<=SQ_X_16+SQ_XY_DIM-1)) else -- row 16
      "10000" ;	-- not in the row
	cube_row <= ms_row;
	cube_col <= ms_col;
	
   ----------------------------------------------
   -- draw objects on grids
   ----------------------------------------------
	
	--led <= player_grid(7 downto 0); -- debug LED's
	grid_pos <=  to_integer(unsigned(sq_row))*8 + (to_integer(unsigned(sq_col)-8)) when (sq_col>"00111") else -- which cube is being drawn? (0 to 63) right grid only
					(to_integer(unsigned(sq_row))*8 + (to_integer(unsigned(sq_col))))*2;  -- left grid only, (0 to 126)
   -- draw player's boats
   boat_miss_sq <=
      '1' when player_grid(grid_pos)='0' and player_hit_grid(grid_pos)='1' and (sq_col>"00111") and not(sq_col="10000" or sq_row="1000") else	-- right grid
		'1' when cpu_grid(grid_pos)='0' and cpu_grid(grid_pos+1)='1' and (sq_col<"01000") and not(sq_col="10000" or sq_row="1000") else -- left grid, "01" player shot it its a miss
      '0';
	boat_hit_sq <=
      '1' when player_grid(grid_pos)='1' and player_hit_grid(grid_pos)='1' and (sq_col>"00111") and not(sq_col="10000" or sq_row="1000") else	-- right grid
		'1' when cpu_grid(grid_pos)='1' and cpu_grid(grid_pos+1)='0' and (sq_col<"01000") and not(sq_col="10000" or sq_row="1000") else -- left grid, "10" player shot and hit
      '0';
	boat_icon_sq <=	--	boat icon is for player's boats only
      '1' when player_grid(grid_pos)='1' and (sq_col>"00111") and not(sq_col="10000" or sq_row="1000") else	-- right grid
      '0';
--	boat_sunk_sq <=	--	boat icon is for player's boats only
--      '1' when cpu_grid(grid_pos)='1' and cpu_grid(grid_pos+1)='1' and (sq_col<"01000") and not(sq_col="10000" or sq_row="1000") else -- left grid, "11" boat destroyed
--      '0';
   -- get XY coordinates of where the object should be drawn
	object_y_pos <= std_logic_vector( to_unsigned(116+5 +  to_integer(unsigned(sq_row))*32,10) ); -- row
	object_x_pos <= std_logic_vector( to_unsigned( 20+5 +  to_integer(unsigned(sq_col))*32,10) ) when sq_col<"01000" else -- left grid's column
						 std_logic_vector( to_unsigned(318+5 + (to_integer(unsigned(sq_col))-8)*32,10) ); -- right grid's column
   rom_addr_boat <= unsigned(pix_y(4 downto 0)) - unsigned(object_y_pos(4 downto 0));
   rom_col_boat  <= unsigned(pix_x(4 downto 0)) - unsigned(object_x_pos(4 downto 0));
	
   rom_data_boat_miss <= BOAT_MISS_ROM(to_integer(rom_addr_boat)); -- rom_addr bit pos inside matrix
   rom_bit_boat_miss  <= rom_data_boat_miss(to_integer(rom_col_boat));
	
   rom_data_boat_hit <= BOAT_HIT_ROM(to_integer(rom_addr_boat)); -- rom_addr bit pos inside matrix
   rom_bit_boat_hit  <= rom_data_boat_hit(to_integer(rom_col_boat));
	
   rom_data_boat_icon <= BOAT_ICON_ROM(to_integer(rom_addr_boat)); -- rom_addr bit pos inside matrix
   rom_bit_boat_icon  <= rom_data_boat_icon(to_integer(rom_col_boat));
	
--   rom_data_boat_sunk <= BOAT_SUNK_ROM(to_integer(rom_addr_boat)); -- rom_addr bit pos inside matrix
--   rom_bit_boat_sunk  <= rom_data_boat_sunk(to_integer(rom_col_boat));
   -- icons, priority (lower at left): icon, hit, sunk
   boat_miss_on <=
      '1' when (boat_miss_sq='1') and (rom_bit_boat_miss='1') and (rom_col_boat<"10100") else
      '0';
   boat_hit_on <=
      '1' when (boat_hit_sq='1') and (rom_bit_boat_hit='1') and (rom_col_boat<"10100") else	--and boat_sunk_sq='0' --do not overlap or underlap "sunk" icon
      '0';
   boat_icon_on <=
      '1' when (boat_icon_sq='1') and (rom_bit_boat_icon='1') and (rom_col_boat<"10100") and not(boat_hit_on='1') else
      '0';
--   boat_sunk_on <=
--      '1' when (boat_sunk_sq='1') and (rom_bit_boat_sunk='1') and (rom_col_boat<"10100") else
--      '0';
   -- color
   boat_miss_rgb <= "111";   -- white
   boat_hit_rgb  <= "101";   -- mangenta
   boat_icon_rgb <= "111";   -- green
	
   ----------------------------------------------
   -- (grid's), not grids but just two background squares (less resources used)
   ----------------------------------------------
   -- pixel within wall
   wall_on <=
      '1' when (rd_ball_on='0' and block_on = '0' and boat_miss_on='0' and boat_hit_on='0' and boat_icon_on='0') and --and boat_sunk_on='0' --and boat_sunk_on='0'
					(((GRID_X_L<=pix_x) and (pix_x<=GRID_X_R) and (GRID_Y_T<=pix_y) and (pix_y<=GRID_Y_B)) or		-- grid 1
					 ((GRID2_X_L<=pix_x) and (pix_x<=GRID2_X_R) and (GRID_Y_T<=pix_y) and (pix_y<=GRID_Y_B)) ) else -- grid 2
      '0';
   -- wall rgb output
   wall_rgb <= "001"; -- blue

   ----------------------------------------------
   -- square ball & Mouse Pointer
   ----------------------------------------------
   --@nota as coordenadas do ponteiro sao aplicadas aos limites
   --		esquerdo e superior do ponteiro.
   --		Sendo que o tamanho do ponteoro e' 8x8 px
	
   -- boundary
   ball_x_l <= ball_x_reg; -- Ball X Left
   ball_y_t <= ball_y_reg;
   ball_x_r <= ball_x_l + BALL_SIZE - 1; -- Ball X Right
   ball_y_b <= ball_y_t + BALL_SIZE - 1;
   -- pixel within ball
   sq_ball_on <=
      '1' when (ball_x_l <= pix_x) and (pix_x <= ball_x_r) and
               (ball_y_t <= pix_y) and (pix_y <= ball_y_b) else
      '0';
   -- map current pixel location to ROM addr/col
   rom_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
   rom_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
   rom_data <= BALL_ROM(to_integer(rom_addr)); -- rom_addr bit pos inside matrix
   rom_bit <= rom_data(to_integer(rom_col));
   -- pixel within ball
   rd_ball_on <=
      '1' when (sq_ball_on='1') and (rom_bit='1') else
      '0';
   -- ball rgb output
   ball_rgb <= "100";   -- red
	
	--led <= (ym_c(9 downto 2));
   process(xm,ym,m_done_tick, xm_c_reg, ym_c_reg) -- "refr_tick" -> when the screen is refreshed
   begin
      ym_c_next <= ym_c_reg; -- no move
		xm_c_next <= xm_c_reg;
      if m_done_tick='1' then
			if xm(8)='0' then	-- 640 = 10 1000 0000, 600 = 10 0101 1000
				if std_logic_vector(unsigned(xm_c_reg) + unsigned(xm)) < "1001011100" then -- X move right
					xm_c_next <= std_logic_vector(unsigned(xm_c_reg) + unsigned(xm));	
				end if;
			else -- Ao inverter a direção do rato os bits recebidos são também invertidos, sendo necessário inverte-los de novo.
				if std_logic_vector(unsigned(xm_c_reg) - unsigned(xm xor "111111111")) < "1001011100" then -- X move left
					xm_c_next <=  std_logic_vector(unsigned(xm_c_reg) - unsigned(xm xor "111111111"));
				else
					xm_c_next <= "0000000000"; 
				end if;
				--xm_c_next <=  std_logic_vector(unsigned(xm_c_reg) - unsigned(xm xor "111111111"));
			end if;
			if ym(8)='0' then	-- 460 = 0111001100
				if std_logic_vector(unsigned(ym_c_reg) - unsigned(ym)) < "0111011011" then	-- Y move up
					ym_c_next <= std_logic_vector(unsigned(ym_c_reg) - unsigned(ym)); -- update position
				else 
					ym_c_next <= ym_c_reg; --  limit 
				end if;
			else
				if std_logic_vector(unsigned(ym_c_reg) + unsigned(ym xor "111111111")) < "0111011011" then -- Y move down
					ym_c_next <= std_logic_vector(unsigned(ym_c_reg) + unsigned(ym xor "111111111"));
				else 
					ym_c_next <= ym_c_reg;--"0111011010";
				end if;
				--ym_c_next <= std_logic_vector(unsigned(ym_c_reg) + unsigned(ym xor "111111111")); 
			end if;	
      end if;
   end process;
 
   ball_x_next <= unsigned(xm_c_reg) when refr_tick='1';
   ball_y_next <= unsigned(ym_c_reg) when refr_tick='1';
	
	mouse_x_out <= std_logic_vector(ball_x_reg);
	mouse_y_out <= std_logic_vector(ball_y_reg);
				
	--led(1 downto 0) <= result;
   ----------------------------------------------
   -- rgb multiplexing circuit
   ----------------------------------------------
	sw012 <= sw;
   process(video_on,wall_on,rd_ball_on,
           wall_rgb, ball_rgb, block_rgb, boat_miss_rgb, boat_hit_rgb, boat_icon_rgb)
   begin
      if video_on='0' then
          graph_rgb <= "000"; --blank
      elsif main_menu_active='0' then	--	 game ----------
			--	game
         if wall_on='1' then
            graph_rgb <= wall_rgb xor sw012;
         elsif rd_ball_on='1' then -- ponteiro
            graph_rgb <= ball_rgb xor sw012;
         elsif block_on='1' then -- cubes
            graph_rgb <= block_rgb xor sw012;
         elsif boat_miss_on='1' then -- miss
            graph_rgb <= boat_miss_rgb xor sw012;
         elsif boat_hit_on='1' then -- hit
            graph_rgb <= boat_hit_rgb xor sw012;
         elsif boat_icon_on='1' then -- icon
            graph_rgb <= boat_icon_rgb xor sw012;
         else
            graph_rgb <= "000" xor sw012; -- black background
         end if;
		else	--	 menu ----------
			if menu_font_on='1' then	-- texto
            graph_rgb <= menu_font_rgb xor sw012;
         elsif rd_ball_on='1' then -- ponteiro
            graph_rgb <= ball_rgb xor sw012;
         elsif menu_wbox_on='1' then -- caixa do botao
            graph_rgb <= wbox_rgb xor sw012;
         else
            graph_rgb <= "001" xor sw012; -- blue background
         end if;
      end if;
   end process;
end arch;
