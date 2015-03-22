library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mux is
	port (
		input1	:	in std_logic_vector(31 downto 0);
		input2	:	in std_logic_vector(31 downto 0);
		selector:	in std_logic;
		output1	:	out std_logic_vector(31 downto 0)
	);
end mux;

architecture arch_mux of mux is

begin
	output1 <= input1 when selector = '0' else
		input2;

end arch_mux;