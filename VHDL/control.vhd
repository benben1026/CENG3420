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
		regWrite:	out std_logic
	);
end control;

architecture arch_control of control is
signal opcode <= inst(31 downto 26);
begin
	regdst	<=	'1' when opcode = "000000" else '0';
	jump <= '1' when opcode(5 downto 1) = "00001" else '0'; -- j or jal
	branch <= '1' when opcode(5 downto 1) ="00010" else '0'; -- beq or bne
	memRead <= '1';
	memToReg <= '1' when opcode = "100011" -- lw
				or opcode = "100100" -- lbu
				or opcode = "100000" -- lb
				else '0';
	aluop <= "00" when opcode(5 downto 4) = "10" else -- load or store
				"01" when opcode(5 downto 1) = "00010" else -- beq or bne
				"10" when opcode = "000000" else
				"11";
	memWrite <= '1' when opcode="101000" or opcode="101011" else
				'0';
	aluSrc <= '0' when opcode = "000000" -- R type
				or  opcode(5 downto 1) = "00010" -- beq or bne
				else '1';
	regWrite <= '0' when (opcode = "000000" and funct = "001000") -- jr
					or opcode = "000010" -- j
					or opcode = "101011" -- sw
					or opcode = "101000" -- sb
					or opcode = "000100" -- beq
					or opcode = "000101" -- bne
					else '1';

end arch_control;