-- Listing 12.6
library ieee;
use ieee.std_logic_1164.all;
entity battleship_top is
   port (
      clock,reset: in std_logic;
      btn: in std_logic_vector (1 downto 0);
      hsync, vsync: out  std_logic;
      outred: out std_logic_vector(2 downto 0);
	  outgreen: out std_logic_vector(2 downto 0);
	  outblue: out std_logic_vector(1 downto 0);
		  led: out std_logic_vector(7 downto 0);
		  ps2d, ps2c: inout std_logic	-- Mouse inputs
   );
end battleship_top;

architecture arch of battleship_top is
   signal pixel_x, pixel_y: std_logic_vector (9 downto 0);	-- from "vga_sync"
   signal video_on, pixel_tick, clk: std_logic;					-- from "vga_sync"
   signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);	-- from "vga_sync"
	
	-- I/O linked to main.vhdl
	signal  mouse_x_out, mouse_y_out: std_logic_vector(9 downto 0);	-- from "screen_unit" to "main_unit"
	signal  btnm_out: std_logic_vector(2 downto 0);							-- from "screen_unit" to "main_unit"
	--
	signal	xyfire: std_logic_vector(5 downto 0); 							-- from & to "main", "computer_unit" 
	signal	hit,boat_sunk,listen, ack, cpu_turn: std_logic;	-- from & to "main", "computer_unit" 
	signal	boat_xy: std_logic_vector(9 downto 0);							-- from & to "main", "computer_unit" 
	--
	signal	score_out: std_logic_vector(7 downto 0);			-- from "main_unit" to "screen_unit" 
	signal	cpu_grid: std_logic_vector(127 downto 0);			-- from "main_unit" to "screen_unit" 
	signal	player_hit_grid: std_logic_vector(63 downto 0);	-- from "main_unit" to "screen_unit" 
	signal	main_menu_active: std_logic;							-- from "main" to "screen_unit"
begin

  -- instantiate clock manager unit
	-- this unit converts the 25MHz input clock to the expected 50MHz clock
	clockmanager_unit: entity work.clockmanager 
	  port map(
		CLKIN_IN => clock,
		RST_IN => reset,
		CLK2X_OUT => clk,
		LOCKED_OUT => open);
		
   -- instantiate VGA sync 
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset,
               video_on=>video_on, p_tick=>pixel_tick,
               hsync=>hsync, vsync=>vsync,
               pixel_x=>pixel_x, pixel_y=>pixel_y);
   -- instantiate graphic generator, this unit also bridges the Mouse communication
   screen_unit: entity work.screen_unit
      port map (clk=>clk, reset=>reset,
                btn=>btn, video_on=>video_on,
                pixel_x=>pixel_x, pixel_y=>pixel_y,
                graph_rgb=>rgb_next,
					 led=>led,
					 ps2d=>ps2d, ps2c=>ps2c,
					 mouse_x_out=>mouse_x_out, mouse_y_out=>mouse_y_out,	-- mouse x and mouse y
					 btnm_out=>btnm_out,main_menu_active=>main_menu_active); -- mouse buttons
					  
	 main_unit: entity work.main_unit
		port map (clk=>clk, reset=>reset,
					 xyfire=>xyfire, 
					 hit=>hit,boat_sunk=>boat_sunk,
					 listen=>listen, ack=>ack, cpu_turn=>cpu_turn,
					 boat_xy=>boat_xy,
					 score_out=>score_out,
					 cpu_grid=>cpu_grid,
					 player_hit_grid=>player_hit_grid,
					 mouse_x=>mouse_x_out,mouse_y=>mouse_y_out,
					 btnm=>btnm_out,
					 main_menu_active=>main_menu_active);
					 
					 -- comments to delete:
--      clk, reset: in std_logic;
--		  xyfire: inout std_logic_vector(5 downto 0); -- 3 bit X, 3 bit Y
--		  hit,boat_sunk: inout std_logic_vector;
--		  boat_xy : inout std_logic_vector(9 downto 0); -- 3 bit X, 3 bit Y, 1 bit Horizontal, 3 bit XY coord (if it's horizontal then this is X, else it's Y)
--		  listen, ack, cpu_turn: inout std_logic;
--		  score_out: out std_logic_vector(7 downto 0); -- 4 bit cpu score, 4 bit player score
--        cpu_grid: out std_logic_vector(127 downto 0); -- 8x8 grid with two bits per position, represents the enemy's grid
--		  player_hit_grid: out std_logic_vector(63 downto 0); -- 8x8 grid with the places the CPU shot
--		  mouse_x, mouse_y: in unsigned(9 downto 0);	-- Mouse inputs
--		  btnm: in std_logic_vector(2 downto 0);
--		  main_menu_active: out std_logic
					 
   -- rgb buffer
   process (clk)
   begin
      if (clk'event and clk='1') then
         if (pixel_tick='1') then
            rgb_reg <= rgb_next;
         end if;
      end if;
   end process;
    outred <= rgb_reg(2) & rgb_reg(2) & rgb_reg(2);
	outgreen <= rgb_reg(1) & rgb_reg(1) & rgb_reg(1);
	outblue <= rgb_reg(0) & rgb_reg(0);
end arch;