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

	component mux
		port(
			input1	:	in std_logic_vector(31 downto 0);
			input2	:	in std_logic_vector(31 downto 0);
			selector:	in std_logic;
			output1	:	out std_logic_vector(31 downto 0)
		);
	end component;

-- Add signals here
	signal running	:	std_logic;

	signal inst_signal : std_logic_vector(31 downto 0);
	signal pc 		:	std_logic_vector(31 downto 0) := x"00004000";
	signal pcAdd4	:	std_logic_vector(31 downto 0);
	signal pcNext	:	std_logic_vector(31 downto 0);
	signal imme		:	std_logic_vector(15 downto 0);
	signal immeExt	:	std_logic_vector(31 downto 0);

	signal mux4Input1	:	std_logic_vector(31 downto 0);
	signal mux4Input2	:	std_logic_vector(31 downto 0);
	signal mux4Control	:	std_logic_vector(31 downto 0);

	signal mux5Input1	:	std_logic_vector(31 downto 0);
	signal mux5Input2	:	std_logic_vector(31 downto 0);
	signal mux5Control	:	std_logic_vector(31 downto 0);

	signal regDst	: 	std_logic;
	signal jump		: 	std_logic;
	signal branch	:	std_logic;
	signal memRead	:	std_logic;
	signal memToReg :	std_logic;
	signal aluOp	:	std_logic_vector(1 downto 0);
	signal memWrite :	std_logic;
	signal aluSrc	:	std_logic;
	signal regWrite :	std_logic;
begin
-- Processor Core Behaviour
	regtableMapping : regtable PORT MAP
	(
		clk     => clk,
		rst     => rst,
		raddrA  => inst(25 downto 21),
		raddrB  => inst(20 downto 16),
		wen     => regWrite,
		waddr   => regWriteAddr,
		din	=> mux3Output,
		doutA   => aluin1,
		doutB   => mux2Input1,
		extaddr => regaddr,
		extdout => regdout
	);

	memtableMapping : memtable PORT MAP
	(
		clk	=> clk,
		rst	=> rst,
		instaddr=> PC,
		instout	=> 
		wen	=> memWrite,
		addr	=> aluResult,
		din	=> mux2Input1,
		dout	=> mux3Input1
		extwen	=> 
		extaddr	=> 
		extdin	=> 
		extdout	=>
	);

	controlMapping : control PORT MAP
	(
		inst => inst,
		regDst => regDst,
		jump => jump,
		branch => branch,
		memRead => memRead,
		memToReg => memToReg,
		aluOp => aluOp,
		memWrite => memWrite,
		aluSrc => aluSrc,
		regWrite =>	regWrite
	);

	mux1Mapping : mux PORT MAP
	(
		input1 => inst(20 downto 16),
		input2 => inst(15 downto 11),
		selector => regDst,
		output1 => waddr
	);

	mux2Mapping : mux PORT MAP
	(
		input1 => mux2Input1,
		input2 => 
		selector => aluSrc,
		output1 => mux2Output
	);

	mux3Mapping : mux PORT MAP
	(
		input1 => mux3Input1,
		input2 => aluResult,
		selector => memToReg,
		output1 => mux3Output
	);

	ALUMapping : ALU PORT MAP
	(
		A	=> aluin1,
		B	=> mux2Output,
		op	=> aluControl,
		Result	=> aluResult,
		ZERO	=> ZERO
	);

	
	inst_signal <= inst when running = '1' else
		"00000000000000000000000000000000";
	pcAdd4 <= pc + x"4";
	imme <= inst_signal(15 downto 0);
	immeExt <= std_logic_vector(resize(signed(imme), 32));

	mux4Input1 <= pcAdd4;
	mux4Input2 <= pcAdd4 + std_logic_vector(shift_left(signed(immeExt), 2));
	mux4Control <= branch and ZERO;

	mux4Mapping : mux PORT MAP
	(
		input1 => mux4Input1,
		input2 => mux4Input2,
		selector => mux4Control,
		outpu1 => mux5Input1,
	)

	mux5Input1 <= pcAdd4 + std_logic_vector(resize(shift_left(inst_signal(25 downto 0), 2), 32));
	mux5Mapping : mux PORT MAP
	(
		input1 => mux5Input1,
		input2 => mux5Input2,
		selector => jump,
		output1 => pcNext,
	)


---------------------------------------- sign_extend ----------------------------------------

  SignExtension <= "1111111111111111" & inst(15 downto 0) when inst(15)='1'
		 else "0000000000000000" & inst(15 downto 0);	 

---------------------------------------- sign_extend ----------------------------------------

end arch_processor_core;







