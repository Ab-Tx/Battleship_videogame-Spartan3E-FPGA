-- Gerador de numeros Pseudo-aleatorios
--Polinomio:
-- x^10 + x^14 + x^13 + x^11 + 1
--n=16 => T= 65535 numeros

Library IEEE;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity rng_unit is
   port (clk:   in std_logic;                      
         r_out: out std_logic_vector (0 to 7);  
         reset: in std_logic    
			);
 end rng_unit;

architecture behaviour of rng_unit is 

	signal xor_1,xor_2,xor_3: std_logic; 
	signal seq: std_logic_vector (0 to 7); 
	signal conta, conta_next: unsigned (18 downto 0);
begin 

	counter:
  process(clk, reset, conta)
  begin
   if reset = '1' then
			conta  <= (others => '0');
   elsif falling_edge(clk) then
			 conta <= conta_next;
    end if;
	end process counter;
	
	conta_next <= conta + 1      when conta < 100000 else 
					 (others => '0') ; --500 Hz --contador
														--\__>> pode ser acertado para acelerar o processo
	
  random:
  process(clk, reset, conta)
  begin
   if reset = '1' then
			seq  <= (0=> '1', others => '0');
   elsif (falling_edge(clk) and conta = 1) then
			 SEQ(0) <= xor_1;
			 SEQ(1) <= SEQ(0);
			 SEQ(2) <= SEQ(1);
			 SEQ(3) <= SEQ(2);
			 SEQ(4) <= SEQ(3);
			 SEQ(5) <= SEQ(4);
			 SEQ(6) <= SEQ(5);
			 SEQ(7) <= SEQ(6);
    end if;
	end process random;

	xor_1<= SEQ(2) xor xor_2;
	xor_2<= SEQ(4) xor xor_3;
	xor_3<= SEQ(5) xor SEQ(7);
	
	r_out <= SEQ;
	
end behaviour;