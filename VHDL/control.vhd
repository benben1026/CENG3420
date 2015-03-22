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
begin
	RegDst <= '1' when inst(31 downto 26)='000000' else '0';
		Jump <= '1' when inst(31 downto 27)='00001' else '0';
		Branch <= '1' when inst(31 downto 26)='000100'	else 
			 '1' when inst(31 downto 26)='000101' else '0';
		MemToReg <= '1' when inst(31 downto 26)="101000" or --sb
				inst(31 downto 26)="100011" or  --lw
				inst(31 downto 26)="100000" or  --lb
				inst(31 downto 26)="100100" else  --lbu  
			'0';
		ALUOp <= "00" when RType='1' or Branch='1' or    
				(RegDst='1' and	inst(5 downto 0)="001000") else  --beq, bne, RType, jr
			"01" when inst(31 downto 26)="001000" or   --addi
				inst(31 downto 26)="001010" or   --slti
				inst(31 downto 26)="101000"	or   --sb
				inst(31 downto 26)="100011" or   --lw
				inst(31 downto 26)="101011" or   --sw
				inst(31 downto 26)="100000" or   --lb   
				inst(31 downto 26)="100100"	else   --lbu
			"10" when inst(31 downto 27)="00001" or   --j, jal
				inst(31 downto 27)="00110" or     --andi, ori
				inst(31 downto 26)="001011" or     --sltiu
				inst(31 downto 26)="001111" else   --lui
			"11";  --The instruction is not allowed
		ALUSrc <= "1" when inst(31 downto 26)="001000" or  --addi
				inst(31 downto 26)="001100" or  --andi
				inst(31 downto 26)="001101" or  --ori
				inst(31 downto 26)="100011" or  --lw
				inst(31 downto 26)="101011" or  --sw
				inst(31 downto 26)="100100" or  --lbu
				inst(31 downto 26)="100000" or  --lb
				inst(31 downto 26)="101000" or  --sb
				inst(31 downto 26)="001111" or  --lui
				inst(31 downto 26)="000100" or  --beq
				inst(31 downto 26)="000101" or  --bne
				inst(31 downto 26)="001010" or  --slti
				inst(31 downto 26)="001011" else  --sltiu
			"0";
		RegWrite <= '1' when RType='1' or 
				inst(31 downto 26)="100011" or  --lw
				inst(31 downto 26)="100000" or  --lb
				inst(31 downto 26)="100100" or  --lbu
				inst(31 downto 26)="000011" or   --JAL
				inst(31 downto 29)="001" else    --Operation end with 'i'
			'0';
end arch_control;