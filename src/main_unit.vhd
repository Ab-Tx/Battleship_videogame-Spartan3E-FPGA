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

entity main_unit is
   port(
        clk, reset: in std_logic;
		  --
--		  xyfire: inout std_logic_vector(5 downto 0); -- 3 bit X, 3 bit Y
--		  hit,boat_sunk: inout std_logic;
--		  boat_xy : inout std_logic_vector(9 downto 0); -- 3 bit X, 3 bit Y, 1 bit Horizontal, 3 bit XY coord (if it's horizontal then this is X, else it's Y)
--		  listen, ack, cpu_turn: inout std_logic;
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
		  -- /\/\/\ X-Recursos insuficientes
		  led: out std_logic_vector(7 downto 0);
		  -- signals from ping_graph_an:
        cpu_grid_out: out std_logic_vector(127 downto 0) := (others=>'0'); -- 8x8 grid with two bits per position, represents the enemy's grid
		  -- '00' default value, '01' position shot but has nothing, '10' position shot and hit, '11' boat destroyed in this position
		  player_hit_grid: out std_logic_vector(63 downto 0) := (others=>'0'); -- 8x8 grid with the places the CPU shot
		  player_grid_out: out std_logic_vector(63 downto 0) := (others=>'0'); -- grid with player boats
		  main_menu_active: out std_logic;	--	Are we on the main menu?
		  -- 
		  cube_row: in std_logic_vector(3 downto 0); -- what cube is the mouse overlapping
		  cube_col: in std_logic_vector(4 downto 0); -- what cube is the mouse overlapping
		  mouse_x, mouse_y: in std_logic_vector(9 downto 0);	-- Mouse inputs
		  btnm: in std_logic_vector(2 downto 0);	--	Mouse Buttons
		  result: out std_logic_vector(1 downto 0) := (others=>'0'); -- resultado da partida, "01" jogador ganhou, "10" CPU ganhou
			an: out std_logic_vector(3 downto 0);
			sseg: out std_logic_vector(7 downto 0)
   );
end main_unit;

architecture Behavioral of main_unit is
	
	type fsm_state is (clear, menu,play,get_num, cpu_turn, game_over);--,send_data,proc_data,is_hit,is_sunk,is_won,end_turn,end_turn_b,fsm_cpu_turn,end_cpu_turn,check_score,is_lost);
	signal state_reg: fsm_state;
	signal state_next: fsm_state;
	--type fsm_state2 is (clr, get_num, place,done,idle);--,send_data,proc_data,is_hit,is_sunk,is_won,end_turn,end_turn_b,fsm_cpu_turn,end_cpu_turn,check_score,is_lost);
--	signal state2_reg: fsm_state2;
--	signal state2_next: fsm_state2;
   ----------------------------------------------
   -- 
   ----------------------------------------------
   signal player_grid: std_logic_vector(63 downto 0) := "0011111000000000100100001001000000010010000100100100001000000000"; -- grid with player boats
--00111110
--00000000
--10010000
--10010000
--00010010
--00010010
--01000010
--00000000
   signal cpu_grid: std_logic_vector(63 downto 0) := (others=>'0');--"0000000010000100100001001010010010000100100000000111000100000001"; -- grid with player boats
--00000000
--10000100
--10000100
--10100100
--10000100
--10000000
--01110001
--00000001
	--------
	constant MAP_0: std_logic_vector(63 downto 0) := "0011100000000000000000001111000100000001000000010000100101001001";
	constant MAP_1: std_logic_vector(63 downto 0) := "0010011000000000010000000100011101000000010000000100000000011110";
	constant MAP_2: std_logic_vector(63 downto 0) := "0000000010000100100001001010010010000100100000000111000100000001";
	constant MAP_3: std_logic_vector(63 downto 0) := "0011111000000000100100001001000000010010000100100100001000000000";
	
	---------------- Copied from screen_unit
	-- constant vars for the menu's button
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
	--constant EMPTY_VECT: std_logic_vector(63 downto 0) := (others=>'0');
	signal mouse_overlaps_start_button, cpu_play, valid_cube, ready, click, click_next: std_logic;
	signal mouse_xm, mouse_ym  : unsigned(9 downto 0);
	--
--	signal carrier: std_logic_vector(4 downto 0); 	-- 5 slots
--	signal battleship: std_logic_vector(3 downto 0); -- 4 slots
--	signal cruiser: std_logic_vector(2 downto 0); 	-- 3 slots
--	signal submarine: std_logic; -- 1 slot
--	signal destroyer: std_logic_vector(1 downto 0); -- 2 slots
--	signal cCarrier,cBattleship,cCruiser,cSubmarine,cDestroyer: std_logic_vector(9 downto 0) := "0000000000"; -- 3 bit X, 3 bit Y, 1 bit hor(horizontal), 3 bit XY (if hor=1, it's X)
   --signal temp_grid: std_logic_vector(63 downto 0) := (others=>'0'); -- grid to check if boat position is valid
	signal int_cpu, int_64, int_temp: integer; --"ms_grid_pos" removed. ", int_x, int_y" removed
	signal r_copy, r_copy_next: std_logic_vector (0 to 5) := (others=>'0');  
	signal r_out : std_logic_vector (0 to 7) := (others=>'0');  
	--signal pointsP,pointsC: std_logic_vector(63 downto 0) := (others=>'0');
	signal poP,poC: integer := 0;
	signal pontP,pontC:std_logic_vector(5 downto 0) := (others=>'0');
	signal rst: std_logic := '0';
	
begin
   -- instantiation
   rng_unit: entity work.rng_unit(behaviour)
      port map(clk=>clk, reset=>reset,
               r_out=>r_out); 
					
	process(clk,reset)
	begin
		if (reset='1') or (rst='1') then
			if reset='1' and rst='0' then
				state_reg 	<= clear;
			end if;
			player_hit_grid <= (others=>'0');
			cpu_grid_out <= (others=>'0');
			poP <= 0;
			poC <= 0;
		elsif (clk'event and clk='1') then
			state_reg <= state_next;
			click <= click_next;
			if(state_reg=cpu_turn) then
				if(cpu_play='1') then
					player_hit_grid(int_cpu) <= '1';-- when state_reg=cpu_turn;
					if player_grid(int_cpu)='1' then --and pointsC(int_cpu)='0' then 
						poC <= poC+1;	-- add point
--						pointsC(int_cpu) <= '1'; -- no more ponts from this cube
					end if;
				end if;
				cpu_play<='0';
			else
				cpu_play<='1';
			end if;
			if click='1' and valid_cube='1' and state_reg=play then
				if cpu_grid(int_64)='0' then
					cpu_grid_out((int_temp+1) downto (int_temp)) <= "10"; -- miss, "01" (bits reversed on code!)
				elsif cpu_grid(int_64)='1' then
					cpu_grid_out((int_temp+1) downto (int_temp)) <= "01"; -- hit, "10" (bits reversed on code!)
					--if pointsP(int_64)='0' then 
					poP <= poP+1;	-- add point
						--pointsP(int_64) <= '1'; -- no more ponts from this cube
					--end if;
				end if;
			end if;
		end if;
	end process;
	
	pontP <= std_logic_vector(to_unsigned(poP,5)) when poP<10 else
				'1' & std_logic_vector(to_unsigned(poP-10,4));
	pontC <= std_logic_vector(to_unsigned(poC,5)) when poC<10 else
				'1' & std_logic_vector(to_unsigned(poC-10,4));
	disp_unit: entity work.disp_hex_mux
	port map(
		clk=>clk, reset=>reset,
		hex3=>pontC(4), hex2=>pontC(3 downto 0),
		hex1=>pontP(4), hex0=>pontP(3 downto 0),
		dp_in=>"1011", an=>an, sseg=>sseg);
	--led <= pontP;
	mouse_xm <= unsigned(mouse_x);
	mouse_ym <= unsigned(mouse_y);	
	
	result <= "01" when pontP="10101" else	-- "01" jogador ganhou
				 "10" when pontC="10101" else	-- "10" CPU ganhou
				 "00";
				 
--	led <= 	"11111111" when poP>14 else
--				"11111110" when poP>12 else
--				"11111100" when poP>10 else
--				"11111000" when poP>8 else
--				"11110000" when poP>6 else
--				"11100000" when poP>4 else
--				"11000000" when poP>2 else
--				"10000000" when poP>0 else
--				(others=>'0');
	led(7) <= '1' when pontP(4)='1' and pontP(2)='1' else '0'; -- >14
	led(6) <= '1' when pontP>"10010" else '0'; -- >12
	led(5) <= '1' when pontP>"10000" else '0'; -- >10
	led(4) <= '1' when pontP>8 else '0'; -- >8
	led(3) <= '1' when pontP>6 else '0';
	led(2) <= '1' when pontP>4 else '0';
	led(1) <= '1' when pontP>2 else '0';
	led(0) <= '1' when pontP>0 else '0';
				
	mouse_overlaps_start_button <= '1' when	(WBOX_X_L <= mouse_xm) and (mouse_xm <= WBOX_X_R) and (WBOX_Y_T <= mouse_ym) and (mouse_ym <= WBOX_Y_B) else
											 '0';
											 
--	ms_grid_pos <=  to_integer(unsigned(cube_row))*8 + (to_integer(unsigned(cube_col)-8)) when (cube_col>"00111")  and not(cube_col="10000") else -- which cube overlaped by the mouse? (0 to 63) right grid only
--						 to_integer(unsigned(cube_row))*8 + (to_integer(unsigned(cube_col))) when (cube_col<"00111"); -- left grid only, 0 to 63

	
	click_next <= '1' when btnm(0)='1' else -- and valid_cube='1' else
					  '0';
	int_64 <= to_integer(unsigned(cube_col)+unsigned(cube_row)*8) when cube_col<"01000";
	int_temp <= to_integer(unsigned(cube_col)+unsigned(cube_row)*8)*2 when cube_col<"01000";
	--int_x <= to_integer(unsigned(r_copy(0 to 2) ));	--	CPU x
	--int_y <= to_integer(unsigned(r_copy(3 to 5) ));	--	CPU y
	int_cpu <= (to_integer(unsigned(r_copy(0 to 2) ))+to_integer(unsigned(r_copy(3 to 5) ))*8);	--	position CPU chose
	
	valid_cube <= '1' when  not(cube_row="1000" or cube_col="10000") and cube_col<"01000" else
					  '0';
	
	process(state_reg)
	begin
		state_next <= state_reg; --default
		player_grid_out <= player_grid;
		case state_reg is
			when clear => 
				state_next <= menu;
			when menu =>
				if (mouse_overlaps_start_button='1' and btnm(0)='1') then
					state_next <= game_over;
				end if;
			when play => 
				rst <= '0';
				if pontP="10101" or pontC="10101" then	-- game ended?
					state_next <= menu;	--	back to main menu
				elsif (click='1') and valid_cube='1' then
					state_next <= get_num;
				end if;
			when get_num =>
				r_copy <= r_out(0 to 5);	--	copy random number
				state_next <= cpu_turn;	--	change state
			when cpu_turn =>
				if(click='0') then	-- wait for player to release the mouse
					state_next <= play;	-- CPU action is done on a different process, 
				end if;
			when game_over =>
				rst <= '1';
				if(pontP="00000") and (pontC="00000") then
					rst <= '0';
					-- mapa do CPU aleatorio, sem recursos para colocar mapa do jogador aleatorio
					if (r_copy(0 to 1)="00") then
						cpu_grid <= MAP_0;
					elsif (r_copy(0 to 1)="01") then
						cpu_grid <= MAP_1;
					elsif (r_copy(0 to 1)="10") then
						cpu_grid <= MAP_3;
					elsif (r_copy(0 to 1)="11") then 
						cpu_grid <= MAP_2;
					end if;
					state_next <= play;
				end if;
		end case;
	end process;			
	
	-- output logic
	process(state_reg)
	begin
		-- defautls
		main_menu_active <= '0';
		case state_reg is
			when clear =>
				main_menu_active <= '1';
			when menu =>
				main_menu_active <= '1';
			when play =>
			when get_num =>
			when cpu_turn =>
			when game_over =>
				main_menu_active <= '1';
		end case;
	end process;	
	
end Behavioral;

