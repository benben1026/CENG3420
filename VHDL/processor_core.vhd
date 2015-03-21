library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity processor_core is
	port (
		clk		:	in std_logic;
		rst		:	in std_logic;
		run		:	in std_logic;
		instaddr:	out std_logic_vector(31 downto 0);
		inst	:	in std_logic_vector(31 downto 0);
		memwen	:	out std_logic;
		memaddr	:	out std_logic_vector(31 downto 0);
		memdw	:	out std_logic_vector(31 downto 0);
		memdr	:	in std_logic_vector(31 downto 0);
		fin		:	out std_logic;
		PCout	:	out std_logic_vector(31 downto 0);
		regaddr	:	in std_logic_vector(4 downto 0);
		regdout	:	out std_logic_vector(31 downto 0)
	);
end processor_core;

architecture arch_processor_core of processor_core is
-- Add the register table here
	component regtable
		port (
			clk	:	in std_logic;
			rst	:	in std_logic;
			raddrA	:	in std_logic_vector(4 downto 0);
			raddrB	:	in std_logic_vector(4 downto 0);
			wen	:	in std_logic;
			waddr	:	in std_logic_vector(4 downto 0);
			din	:	in std_logic_vector(31 downto 0);
			doutA	:	out std_logic_vector(31 downto 0);
			doutB	:	out std_logic_vector(31 downto 0);
			extaddr	:	in std_logic_vector(4 downto 0);
			extdout	:	out std_logic_vector(31 downto 0)
		);
	end component;

	component control
		port(
			ins	:	in std_logic_vector(31 downto 0);
			
		)
-- Add signals here
	--Signal: Decode
	signal RegDst: std_logic;
	signal Jump: std_logic;
	signal Branch: std_logic;
	signal MemRead: std_logic;
	signal MemToReg: std_logic;
	signal ALUOp: std_logic_vector(3 downto 0);
	signal MemWrite: std_logic;
	signal ALUSrc: std_logic_vector(1 downto 0);
	signal RegWrite: std_logic;
	signal RType: STD_LOGIC;
begin
-- Processor Core Behaviour
	--Decode
	process()
	begin
		RegDst <= '1' when inst(31 downto 26)='000000' else '0';
		Jump <= '1' when inst(31 downto 27)='00001' else '0';
		Branch <= '1' when inst(31 downto 26)='000100'	else 
			<= '1' when inst(31 downto 26)='000101' else '0';
		MemToReg <= '1' when inst(31 downto 26)="101000" or --SB
				inst(31 downto 26)="100011" or  --lw
				inst(31 downto 26)="100000" or  --lb
				inst(31 downto 26)="100100" else  --lbu  
			'0';
		ALUSrc <= "00" when RType='1' or Branch='1' or    
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
		RegWrite <= '1' when RType='1' or 
				inst(31 downto 26)="100011" or  --lw
				inst(31 downto 26)="100000" or  --lb
				inst(31 downto 26)="100100" or  --lbu
				inst(31 downto 26)="000011" or   --JAL
				inst(31 downto 29)="001" else    --Operation end with 'i'
			'0';
		
		
	end process;
end arch_processor_core;
