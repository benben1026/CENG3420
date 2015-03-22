library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control is
	port(
		inst	:	in std_logic_vector(31 downto 0);
		regDst	:	out std_logic;
		jump	:	out std_logic;
		branch	:	out std_logic;
		memRead	:	out std_logic;
		memToReg:	out std_logic;
		aluOp	:	out std_logic_vector(1 downto 0);
		memWrite:	out std_logic;
		aluSrc	:	out std_logic;
		regWrite:	out std_logic;
		clk		:	in std_logic
	);
end control;

architecture arch_control of control is
signal opcode : std_logic_vector (5 downto 0);
signal funct : std_logic_vector (5 downto 0);
begin
	process(clk)
	begin
		if clk'event and clk='1' then
			opcode <= inst(31 downto 26);
			funct <= inst(31 downto 26);
			if opcode = "000000" then 
				regdst <= '1';
			else 
				regdst <= '0';
			end if;
			if opcode (5 downto 1) = "00001" then 
				jump <= '1';
			else 
				jump <= '0';
			end if;	
			if opcode (5 downto 1) = "00010" then
				branch <= '1';
			else 
				branch <= '0';
			end if;
				memRead <= '1';
			if opcode = "100011" or opcode = "100100" or opcode = "100000" then
				memToReg <= '1';
			else
				memToReg <= '0';
			end if;

			if opcode (5 downto 4) = "10" then
				aluop <= "00";
			elsif opcode (5 downto 1) = "00010" then
				aluop <= "01";
			elsif opcode = "000000" then
				aluop <= "10";
			else 
				aluop <= "11";
			end if;

			if opcode = "101000" or opcode = "101011" then 
				memWrite <= '1';
			else 
				memWrite <= '0';
			end if;
			if opcode = "000000" or opcode (5 downto 1) = "00010" then
				aluSrc <= '0';
			else 
				aluSrc <= '1';
			end if;
			if (opcode = "000000" and funct = "001000") or opcode = "000010" or opcode = "101011" or opcode = "101000" or opcode = "000100" or opcode = "000101" then
				regWrite <= '0';
			else 
				regWrite <= '1';
			end if;

		end if;
	end process;
end arch_control;
