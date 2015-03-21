library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity aluControl is
	port(
		ins : in std_logic_vector(5 downto 0),
		aluOp : in std_logic_vector (1 downto 0),
		aluControl : out std_logic_vector(3 downto 0)
	);
end aluControl;

architecture arch_aluControl of aluControl is
begin
	process()
	begin
		if ALUOp = "10" then
			ALUControl <= "0110" when inst(31 downto 26)="100000" else 
				"1110" when inst(31 downto 26)="100010" else
				"0000" when inst(31 downto 26)="100100" else 
				"0001" when inst(31 downto 26)="100101" else 
				"0010" when inst(31 downto 26)="100110" else 
				"0011" when inst(31 downto 26)="100111" else 
				"1111" when inst(31 downto 26)="101010" else 
				"1001"
		end if;
	end process;

end arch_aluControl;