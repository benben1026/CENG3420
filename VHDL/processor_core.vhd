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

	component memtable
		port (
			clk		:	in std_logic;
			rst		:	in std_logic;
			instaddr:	in std_logic_vector(31 downto 0);
			instout	:	out std_logic_vector(31 downto 0);
			wen		:	in std_logic;
			addr	:	in std_logic_vector(31 downto 0);
			din		:	in std_logic_vector(31 downto 0);
			dout	:	out std_logic_vector(31 downto 0);
			extwen	:	in std_logic;
			extaddr	:	in std_logic_vector(31 downto 0);
			extdin	:	in std_logic_vector(31 downto 0);
			extdout	:	out std_logic_vector(31 downto 0)
		);
	end component;

-- Add signals here
	--Signal: Decode
	signal RegDst: std_logic;
	signal Jump: std_logic;
	signal Branch: std_logic;
	signal MemRead: std_logic;
	signal MemToReg: std_logic;
	signal ALUOp: std_logic_vector(1 downto 0);
	signal MemWrite: std_logic;
	signal ALUSrc: std_logic;
	signal RegWrite: std_logic;

	signal RType: STD_LOGIC;
	signal ALUControl: std_logic_vector(3 downto 0);

	--Signal: Control Unit
	SIGNAL PCSrc: STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL SignExtension: STD_LOGIC_VECTOR(31 downto 0);--aluloc
		
	--Signal: PC Control
	constant Four: STD_LOGIC_VECTOR(31 downto 0) := "00000000000000000000000000000100";
	constant BaseAddress: STD_LOGIC_VECTOR(31 downto 0) :="00000000000000000100000000000000"; --0x00400000
	signal NewPc: STD_LOGIC_VECTOR(31 downto 0);
	signal PC_Ins: STD_LOGIC_VECTOR(31 downto 0);--brloc
	signal PCfirstMuxOut: STD_LOGIC_VECTOR(31 downto 0);--PCSrc2
	signal PCclk: STD_LOGIC;
	signal PC: STD_LOGIC_VECTOR(31 downto 0);
  
  
 	signal ZERO, Jal, BeforeZero: STD_LOGIC;
	signal RegWriteAddr: STD_LOGIC_VECTOR(4 downto 0);
	signal aluMult, aluResult ,aluin1, aluin2, aluo1, aluo2 : STD_LOGIC_VECTOR(31 downto 0);		
	signal ALUConOut: std_logic_vector (3 downto 0);

	signal din, dout: STD_LOGIC_VECTOR(31 downto 0);
begin
-- Processor Core Behaviour
	regtableMapping : regtable PORT MAP
	(
		clk     => PCclk,
		rst     => rst,
		raddrA  => inst(25 downto 21),
		raddrB  => inst(20 downto 16),
		wen     => RegWrite,
		waddr   => RegWriteAddr,
		din	=> aluo2,
		doutA   => aluin1,
		doutB   => aluMult,
		extaddr => regaddr,
		extdout => regdout
	);

	memtableMapping : memtable PORT MAP
	(
		clk	=> clk,
		rst	=> rst,
		instaddr=> PC,
		instout	=> 
		wen	=> MemWrite,
		addr	=> aluResult,
		din	=> din,
		dout	=> dout,
		extwen	=> 
		extaddr	=> 
		extdin	=> 
		extdout	=>
	);

	ALUMapping : ALU PORT MAP
	(
		A	=> aluin1,
		B	=> aluin2,
		op	=> ALUControl,
		Result	=> aluResult,
		ZERO	=> ZERO
	);
	--Decode
	begin
		RegDst <= '1' when inst(31 downto 26)='000000' else '0';
		Jump <= '1' when inst(31 downto 27)='00001' else '0';
		Branch <= '1' when inst(31 downto 26)='000100'	else 
			<= '1' when inst(31 downto 26)='000101' else '0';
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
	
---------------------------------------- sign_extend ----------------------------------------

  SignExtension <= "1111111111111111" & inst(15 downto 0) when inst(15)='1'
		 else "0000000000000000" & inst(15 downto 0);	 

---------------------------------------- sign_extend ----------------------------------------
	---- ALUControl -----
		if ALUOp = "10" then
			ALUControl <= "0110" when inst(31 downto 26)="100000" else 
				"1110" when inst(31 downto 26)="100010" else
				"0000" when inst(31 downto 26)="100100" else 
				"0001" when inst(31 downto 26)="100101" else 
				"0010" when inst(31 downto 26)="100110" else 
				"0011" when inst(31 downto 26)="100111" else 
				"1111" when inst(31 downto 26)="101010" else 
				"1001"
	---- ALUControl -----


---------------Register-------------------
	raddrA <= inst(25 downto 21);
	raddrB <= inst(20 downto 16);
	waddr <= inst(20 downto 16) when RegDst="0" else
		<= inst(15 downto 11);
	din <= ;
------------End Of Register---------------
end arch_processor_core;







