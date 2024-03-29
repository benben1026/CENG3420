library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

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

	component mux
		port(
			input1	:	in std_logic_vector(31 downto 0);
			input2	:	in std_logic_vector(31 downto 0);
			selector:	in std_logic;
			output1	:	out std_logic_vector(31 downto 0)
		);
	end component;

	component aluControl
		port(
			func	:	in std_logic_vector(5 downto 0);
			aluOp	:	in std_logic_vector(1 downto 0);
			aluControl:	out std_logic_vector(3 downto 0)
		);
	end component;

	component control
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
	end component;

	component ALU
		port (
	  		A	:	in std_logic_vector (31 downto 0);
			B	:	in std_logic_vector (31 downto 0);
			op	:	in std_logic_vector (3 downto 0);
			result	:	out std_logic_vector (31 downto 0);
			ZERO : out std_logic
	);
	end component;
-- Add signals here
	signal running	:	std_logic;

	signal inst_signal : std_logic_vector(31 downto 0);
	signal pc 		:	std_logic_vector(31 downto 0) := x"00004000";
	signal pcAdd4	:	std_logic_vector(31 downto 0) := x"00004004";
	signal pcNext	:	std_logic_vector(31 downto 0);
	signal imme		:	std_logic_vector(15 downto 0);
	signal immeExt	:	std_logic_vector(31 downto 0);

	signal aluin1	:	std_logic_vector(31 downto 0);
	signal aluResult:	std_logic_vector(31 downto 0);
	signal regWriteAddr	:	std_logic_vector(31 downto 0);
	signal ZERO	:	std_logic;
	signal aluControlSignal	:	std_logic_vector(3 downto 0);

	signal mux1Output	:	std_logic_vector(4 downto 0);

	signal mux2Input1	:	std_logic_vector(31 downto 0);
	signal mux2Output	:	std_logic_vector(31 downto 0);

	signal mux3Input1	:	std_logic_vector(31 downto 0);
	signal mux3Output	:	std_logic_vector(31 downto 0);

	signal mux4Input1	:	std_logic_vector(31 downto 0);
	signal mux4Input2	:	std_logic_vector(31 downto 0);
	signal mux4Control	:	std_logic;

	signal mux5Input1	:	std_logic_vector(31 downto 0);
	signal mux5Input2	:	std_logic_vector(31 downto 0);
	signal mux5Control	:	std_logic;

	signal regDst	: 	std_logic;
	signal jump		: 	std_logic;
	signal branch	:	std_logic;
	signal memRead	:	std_logic;
	signal memToReg :	std_logic;
	signal aluOp	:	std_logic_vector(1 downto 0);
	signal memWrite :	std_logic;
	signal aluSrc	:	std_logic;
	signal regWrite :	std_logic;

	signal extwen	:	std_logic;
	signal extaddr	:	std_logic_vector(31 downto 0);
	signal extdin	:	std_logic_vector(31 downto 0);
	signal extdout	:	std_logic_vector(31 downto 0);

	signal temp1	:	std_logic_vector(31 downto 0);
	signal temp2	:	std_logic_vector(31 downto 0);
	signal temp3	:	std_logic_vector(31 downto 0);

	signal flag	:	std_logic := '1';
begin
-- Processor Core Behaviour
	--process(run, clk)
	--begin
	--	if clk'event and clk='1' then
	--		if run = '1' then
	--			running <= '1';
	--			--pc <= x"00004000";
	--			--pcNext <= x"00004004";
	--			--instaddr <= x"00004000";
	--		end if;
	--	end if;
	--end process;

	process(clk, running, inst, pc, ZERO, pcNext, branch, flag)
	begin
		if clk'event and clk='1' then
			if run = '1' then
				running <= '1';
				--pc <= x"00004000";
				--pcNext <= x"00004004";
				--instaddr <= x"00004000";
			end if;
			if running = '1' then
				--fin <= '0';
				if flag = '1' then
					pc <= x"00004000";
					flag <= '0';
				else
					pc <= pcNext;
				end if;
			end if;
			if running = '1' and inst = x"00000000" then
				--inst_signal <= "00000000000000000000000000000000";
				--fin <= '1';
				running <= '0';
				flag <= '1';
			end if;
		end if;
	end process;

	--running <= '0' when inst = x"00000000" else '1';
	fin <= '1' when running = '0' else '0';

	inst_signal <= inst when running = '1' else x"00000000";
	pcAdd4 <= pc + x"4";
	imme <= inst(15 downto 0);
	immeExt <= std_logic_vector(resize(signed(imme), 32));


	mux4Input1 <= pcAdd4;
	mux4Input2 <= pcAdd4 + std_logic_vector(shift_left(signed(immeExt), 2));
	mux4Control <= branch and ZERO;
	mux5Input2 <= (pcAdd4 and (x"ff000000")) or std_logic_vector(resize(shift_left(unsigned(inst(25 downto 0)), 2), 32));
	instaddr <= pc;

--data memory mapping--
	memwen <= memWrite;
	memaddr <= aluResult;
	memdw <= mux2Input1;

	mux3Input1 <= memdr;
--end--

--instruction memory mapping--
	instaddr <= pc;
	PCout <= pc;
--end--

	regtableMapping : regtable PORT MAP
	(
		clk     => clk,
		rst     => rst,
		raddrA  => inst(25 downto 21),
		raddrB  => inst(20 downto 16),
		wen     => regWrite,
		waddr   => mux1Output,
		din	=> mux3Output,
		doutA   => aluin1,
		doutB   => mux2Input1,
		extaddr => regaddr,
		extdout => regdout
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
		regWrite =>	regWrite,
		clk => clk
	);

	aluControlMapping : aluCOntrol PORT MAP
	(
		func => inst(5 downto 0),
		aluOp => aluOp,
		aluControl => aluControlSignal
	);

	temp1 <= std_logic_vector(resize(signed(inst(20 downto 16)), 32));
	temp2 <= std_logic_vector(resize(signed(inst(15 downto 11)), 32));
	mux1Mapping : mux PORT MAP
	(
		input1 => temp1,
		input2 => temp2,
		selector => regDst,
		output1 => temp3
	);

	mux1Output <= temp3(4 downto 0);

	mux2Mapping : mux PORT MAP
	(
		input1 => mux2Input1,
		input2 => immeExt,
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
		op	=> aluControlSignal,
		Result	=> aluResult,
		ZERO	=> ZERO
	);


	mux4Mapping : mux PORT MAP
	(
		input1 => pcAdd4,
		input2 => mux4Input2,
		selector => mux4Control,
		output1 => mux5Input1
	);

	mux5Mapping : mux PORT MAP
	(
		input1 => mux5Input1,
		input2 => mux5Input2,
		selector => jump,
		output1 => pcNext
	);


---------------------------------------- sign_extend ----------------------------------------

 -- immeExt <= "1111111111111111" & inst(15 downto 0) when inst(15)='1'
--		 else "0000000000000000" & inst(15 downto 0);	 

---------------------------------------- sign_extend ----------------------------------------

end arch_processor_core;







