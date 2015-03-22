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
	process
	begin
		if aluOp = "00" then
			aluControl <= "0110"; -- add
		elsif aluOp = "01" then
			aluControl <= "1110"; --sub
		elsif aluOp = "10" then
		  case func is
		    when "100000" =>
		      aluControl <= "0000"; -- add
		    when "100010" =>
		      aluControl <= "0010"; -- beq
		    when "100100" =>
		      aluControl <= "0100"; -- and
		    when "100101" =>
          aluControl <= "0101"; -- or
		    when "100110" =>
		      aluControl <= "0110"; -- xor
		    when "100111" =>
		      aluControl <= "0111"; -- nor
		    when "101010" =>
		      aluControl <= "1010"; -- slt
		    when "101011" =>
		      aluControl <= "1011"; -- sltu
		    when others =>
		      aluControl <= "1001";
		  end case;
--			aluControl <= "0110" when func="100000" else -- add
--				"1110" when func="100010" else -- beq
--				"0000" when func="100100" else -- and
--				"0001" when func="100101" else -- or
--				"0010" when func="100110" else -- xor
--				"0011" when func="100111" else -- nor
--				"1111" when func="101010" else -- slt
--				"1001" when others;
		else
			aluControl <= "1001";
		end if;
	end process;

end arch_aluControl;

