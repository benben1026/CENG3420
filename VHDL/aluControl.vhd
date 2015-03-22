library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity aluControl is
	port(
		func : in std_logic_vector(5 downto 0);
		aluOp : in std_logic_vector (1 downto 0);
		aluControl : out std_logic_vector(3 downto 0)
	);
end aluControl;

architecture arch_aluControl of aluControl is
begin
	  aluControl <= "0000" when aluOp = "00" else -- add
	    "0010" when aluOp = "01" else -- sub
	    "0000" when (aluOp = "10" and func = "100000") else -- add
	    "0010" when (aluOp = "10" and func = "100010") else -- beq / sub
	    "0100" when (aluOp = "10" and func = "100100") else -- and
	    "0101" when (aluOp = "10" and func = "100101") else -- or
	    "0110" when (aluOp = "10" and func = "100110") else -- xor
	    "0111" when (aluOp = "10" and func = "100111") else -- not
	    "1010" when (aluOp = "10" and func = "101010") else -- slt
	    "1011" when (aluOp = "10" and func = "101011") else -- sltu
	    "1001";

end arch_aluControl;

