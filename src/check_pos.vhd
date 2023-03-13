----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:54:06 12/29/2022 
-- Design Name: 
-- Module Name:    check_pos - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity check_pos is
   port(
			clk, reset: in std_logic;
				 enable: in std_logic;
					boat: in std_logic_vector(2 downto 0); -- boat type
					-- 101 carrier
					-- 100 battleship
					-- 011 cruiser
					-- 010 submarine
					-- 001 destroyer
			  boat_pos: in std_logic_vector(6 downto 0);
        valid_position: out std_logic_vector(1 downto 0) -- '01' not valid, '10' valid, '00' no processed yet
   );
end check_pos;

architecture Behavioral of check_pos is
	signal h_grid: std_logic_vector(63 downto 0);
	signal v_grid: std_logic_vector(63 downto 0);
	
   signal h_row_1: std_logic_vector(7 downto 0);
   signal h_row_2: std_logic_vector(7 downto 0);
   signal h_row_3: std_logic_vector(7 downto 0);
   signal h_row_4: std_logic_vector(7 downto 0);
   signal h_row_5: std_logic_vector(7 downto 0);
   signal h_row_6: std_logic_vector(7 downto 0);
   signal h_row_7: std_logic_vector(7 downto 0);
   signal h_row_8: std_logic_vector(7 downto 0);
	
   signal v_col_1: std_logic_vector(7 downto 0);
   signal v_col_2: std_logic_vector(7 downto 0);
   signal v_col_3: std_logic_vector(7 downto 0);
   signal v_col_4: std_logic_vector(7 downto 0);
   signal v_col_5: std_logic_vector(7 downto 0);
   signal v_col_6: std_logic_vector(7 downto 0);
   signal v_col_7: std_logic_vector(7 downto 0);
   signal v_col_8: std_logic_vector(7 downto 0);
begin
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         --bar_y_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         --bar_y_reg <= bar_y_next;
      end if;
   end process;

   process(boat,boat_pos) -- "refr_tick" -> when the screen is refreshed
   begin
	
      bar_y_next <= bar_y_reg; -- no move
      if refr_tick='1' then
         if btn(1)='1' and bar_y_b<(MAX_Y-1-BAR_V) then
            bar_y_next <= bar_y_reg + BAR_V; -- move down
         elsif btn(0)='1' and bar_y_t > BAR_V then
            bar_y_next <= bar_y_reg - BAR_V; -- move up
         end if;
      end if;
   end process;


end Behavioral;

