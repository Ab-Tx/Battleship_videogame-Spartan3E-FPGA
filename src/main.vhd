----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:24:30 12/29/2022 
-- Design Name: 
-- Module Name:    main - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
   port(
        clk, reset: in std_logic;
		  --
		  xyfire: inout std_logic_vector(5 downto 0); -- 3 bit X, 3 bit Y
		  hit,boat_sunk: inout std_logic_vector;
		  boat_xy : inout std_logic_vector(9 downto 0); -- 3 bit X, 3 bit Y, 1 bit Horizontal, 3 bit XY coord (if it's horizontal then this is X, else it's Y)
		  listen, ack, cpu_turn: inout std_logic;
		  --	A usar linhas I/O para poupar recursos..
		  --	PROTOCOLO de comunicação:
		  --  -> jogador efetuou uma jogada (jogador comunica para o cpu)
		  --		1. escrever dados em xyfire
		  -- 		2. após escrever os dados colocar listen a '1'
		  --		-> O cpu ao detetar o listen:
		  --			1. escrever dados hit,boatxy,boatsunk
		  --			2. colocar ack a '1' até listen='0'
		  --		3. o bloco do jogador irá colocar listen='0' e cpu_turn='1' -> com. terminada
		  --		4. colocar cpu_turn='1' -> iniciar turno do cpu
		  --	Processo identico para quando o cpu efetua uma jogada
		  --
		  score_out: out std_logic_vector(7 downto 0); -- 4 bit cpu score, 4 bit player score
		  -- signals from ping_graph_an:
        cpu_grid: out std_logic_vector(127 downto 0); -- 8x8 grid with two bits per position, represents the enemy's grid
		  -- '00' default value, '01' position shot but has nothing, '10' position shot and hit, '11' boat destroyed in this position
		  player_hit_grid: out std_logic_vector(63 downto 0); -- 8x8 grid with the places the CPU shot
		  --
		  mouse_x, mouse_y: in unsigned(9 downto 0);	-- Mouse inputs
		  btnm: in std_logic_vector(2 downto 0);
		  main_menu_active: out std_logic
   );
end main;

architecture Behavioral of main is
	type fsm_state is (clear, menu, play);--,send_data,proc_data,is_hit,is_sunk,is_won,end_turn,end_turn_b,fsm_cpu_turn,end_cpu_turn,check_score,is_lost);
	signal state_reg: fsm_state;
	signal state_next: fsm_state;
   ----------------------------------------------
   -- 
   ----------------------------------------------
   signal player_grid: std_logic_vector(63 downto 0); -- grid with player boats
   constant MAX_SCORE: integer:=2+3+3+4+5;
	signal score, score_next: std_logic_vector(7 downto 0);
	
	---------------- Copied from screen_unit
	-- constant vars for the button
   constant CLICK_CHARS: integer:= 18*8; -- size for all chars
   constant CLICK_X_L: integer:= 223;
   constant CLICK_X_R: integer:= CLICK_X_L + CLICK_CHARS;
   constant CLICK_Y_T: integer:= 439;
   constant CLICK_Y_B: integer:= CLICK_Y_T + 8;
	constant WBOX_X_BORDER: integer:= 15;
	constant WBOX_Y_BORDER: integer:= 15;
   constant WBOX_X_L: integer:= CLICK_X_L - WBOX_X_BORDER;
   constant WBOX_X_R: integer:= CLICK_X_R + WBOX_X_BORDER;
   constant WBOX_Y_T: integer:= CLICK_Y_T - WBOX_Y_BORDER;
   constant WBOX_Y_B: integer:= CLICK_Y_B + WBOX_Y_BORDER;
	----------------	
	signal mouse_overlaps_start_button : std_logic;
	signal mouse_xm, mouse_ym  : unsigned(9 downto 0);
begin
			
	process(clk,reset)
	begin
		if (reset='1') then
			state_reg <= clear;
		elsif (clk'event and clk='1') then
			state_reg <= state_next;
			score <= score_next;
		end if;
	end process;
			
	mouse_xm <= unsigned(mouse_x);
	mouse_ym <= unsigned(mouse_y);	
	 
	mouse_overlaps_start_button <= '1' when	(WBOX_X_L <= mouse_xm) and (mouse_xm <= WBOX_X_R) and (WBOX_Y_T <= mouse_ym) and (mouse_ym <= WBOX_Y_B) else
											 '0';
			
	-- next state logic
	process(state_reg, ack, hit, boat_sunk, score, listen)
	begin
		state_next<= state_reg; --default
		case state_reg is
			when clear => state_next <= menu;
			when menu =>
				if (mouse_overlaps_start_button='1' and btnm(0)='1') then
					state_next <= play;
				end if;
			when play =>
		end case;
	end process;			
	
	-- output logic
	process(state_reg, ack, hit, boat_sunk, score, listen)
	begin
		-- defautls
		main_menu_active <= '0';
		
		case state_reg is
			when clear =>
				main_menu_active <= '1';
			when menu =>
				main_menu_active <= '1';
			when play =>
--			when send_data =>
--				listen <= '1';
--			when proc_data =>
--			when is_hit =>
--			when is_sunk =>
--			when is_won =>
--			when end_turn =>
--				listen <= '0';
--			when end_turn_b =>
--			when fsm_cpu_turn =>
--			when end_cpu_turn =>
--			when check_score =>
--			when is_lost =>
		end case;
	end process;	
	
end Behavioral;

