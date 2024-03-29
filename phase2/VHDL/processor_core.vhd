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
--Component: register table
	component regtable
		port (
			clk		:	in std_logic;
			rst		:	in std_logic;
			raddrA	:	in std_logic_vector(4 downto 0);
			raddrB	:	in std_logic_vector(4 downto 0);
			wen		:	in std_logic;
			waddr	:	in std_logic_vector(4 downto 0);
			din		:	in std_logic_vector(31 downto 0);
			doutA	:	out std_logic_vector(31 downto 0);
			doutB	:	out std_logic_vector(31 downto 0);
			extaddr	:	in std_logic_vector(4 downto 0);
			extdout	:	out std_logic_vector(31 downto 0)
			);
	end component;
-- Add signals here

------------------------ TESTING SIGNALS ---------------------------
	--signal debug1: std_logic_vector(31 downto 0);
	--signal debug2: std_logic_vector(31 downto 0);
	--signal test3: std_logic_vector(31 downto 0);
	--signal test4: std_logic_vector(31 downto 0);

	--Signal: State Control
	signal STATE: STD_LOGIC := '0';
	signal Startrunning: STD_LOGIC :='0';
	signal Finishrunning: STD_LOGIC :='0';

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

	--Signal: Control Unit
	SIGNAL PCSrc: STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL SignExtension: STD_LOGIC_VECTOR(31 downto 0);--aluloc

	--Signal: PC Control
	constant Nil: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
	constant Four: STD_LOGIC_VECTOR(31 downto 0) := "00000000000000000000000000000100";
	constant BaseAddress: STD_LOGIC_VECTOR(31 downto 0) :="00000000000000000100000000000000"; --0x00400000
	signal PcNext: STD_LOGIC_VECTOR(31 downto 0);--newpc
	signal PCAdd_Sft_Out: STD_LOGIC_VECTOR(31 downto 0);--brloc
	signal PCfirstMuxOut: STD_LOGIC_VECTOR(31 downto 0);--PCSrc2
	signal PCclk: STD_LOGIC;
	signal PCpre: std_logic_vector(31 downto 0);
	signal PC: STD_LOGIC_VECTOR(31 downto 0);

	signal ZERO, Jal, BeforeZero: STD_LOGIC;
	signal Tem1: STD_LOGIC_VECTOR(31 downto 0);
	signal Tem2: STD_LOGIC_VECTOR(32 downto 0);
	signal aluBuffer: STD_LOGIC_VECTOR(7 downto 0);
	signal RegWriteAddr: STD_LOGIC_VECTOR(4 downto 0);
	signal aluMult, aluResult ,aluin1, aluin2, aluo1, aluo2 : STD_LOGIC_VECTOR(31 downto 0);
	signal ALUConOut: std_logic_vector (3 downto 0);


	-- Signal: Hazard Detection Unit
	signal Hazard_PCMux_Control: std_logic; -- set to 1 if stall --
	signal Hazard_IF_EX_Control: std_logic;
	signal Hazard_StallMux_Control: std_logic;
	-- ID_EX isolator
--	signal ID_EX_WriteAddr_Q: std_logic_vector(4 downto 0);

	-- Taking input: MemRead, Register_Read_1, Register_Read_2, Register_Write


	signal Reg_Write_Data: std_logic_vector(31 downto 0);
	signal Reg_Write_Enable: std_logic;
	--Forwarding Unit
	--signal ID_EX_Read_1_Q: std_logic_vector(31 downto 0);
	--signal ID_EX_Read_2_Q: std_logic_vector(31 downto 0);
	signal Forwarding_ControlA: std_logic_vector(1 downto 0);
	signal Forwarding_ControlB: std_logic_vector(1 downto 0);

	--IF/ID
	signal IF_ID_PC_D: std_logic_vector(31 downto 0);
	signal IF_ID_InstMem_D: std_logic_vector(31 downto 0);
	signal IF_ID_PC_Q: std_logic_vector(31 downto 0);
	signal IF_ID_Inst_Q: std_logic_vector(31 downto 0);
	signal IF_ID_Hazard_Control: std_logic;
	signal IF_ID_Branch_Control: std_logic;
	signal IF_ID_Jump_Control: std_logic;
--	state signal
	signal IF_ID_State_D: std_logic := '0';
	signal IF_ID_State_Q: std_logic := '0';

	--ID/EX

	-- MemReg, RegWrite
	signal ID_EX_RegWrite_D: std_logic;
	signal ID_EX_WB_D: std_logic_vector(1 downto 0);
	-- MemRead, MemWrite
	signal ID_EX_MemRead_D: std_logic;
	signal ID_EX_MemWrite_D: std_logic;
	signal ID_EX_M_D: std_logic;
	-- Branch, AluOp, AluSrc
	signal ID_EX_Branch_D: std_logic;
	signal ID_EX_AluOp_D: std_logic_vector(3 downto 0);
	signal ID_EX_AluSrc_D: std_logic_vector(1 downto 0);
	signal ID_EX_control_D: std_logic_vector(5 downto 0);

	signal ID_EX_EX_D: std_logic_vector(3 downto 0);
	signal ID_EX_Addr_D: std_logic_vector(31 downto 0);
	signal ID_EX_funct_D: std_logic_vector(5 downto 0);
	signal ID_EX_RegData1_D: std_logic_vector(31 downto 0);
	signal ID_EX_RegData2_D: std_logic_vector(31 downto 0);
	signal ID_EX_SignExt_D: std_logic_vector(31 downto 0);
	signal ID_EX_RegRead1_D: std_logic_vector(4 downto 0);
	signal ID_EX_RegRead2_D: std_logic_vector(4 downto 0);
	signal ID_EX_WriteData_D: std_logic_vector(4 downto 0);
	-- MemReg, RegWrite
	signal ID_EX_RegWrite_Q: std_logic;
	signal ID_EX_WB_Q: std_logic_vector(1 downto 0);
	-- MemRead, MemWrite
	signal ID_EX_MemRead_Q: std_logic;
	signal ID_EX_MemWrite_Q: std_logic;
	signal ID_EX_M_Q: std_logic;
	-- Branch, AluOp, AluSrc
	signal ID_EX_Branch_Q: std_logic;
	signal ID_EX_AluOp_Q: std_logic_vector(3 downto 0);
	signal ID_EX_AluSrc_Q: std_logic_vector(1 downto 0);
	signal ID_EX_control_Q: std_logic_vector(5 downto 0);
--	signal ID_EX_EX_Q: std_logic_vector(3 downto 0);

	signal ID_EX_Addr_Q: std_logic_vector(31 downto 0);
	signal ID_EX_funct_Q: std_logic_vector(5 downto 0);
	signal ID_EX_RegData1_Q: std_logic_vector(31 downto 0);
	signal ID_EX_RegData2_Q: std_logic_vector(31 downto 0);
	signal ID_EX_SignExt_Q: std_logic_vector(31 downto 0);
	signal ID_EX_RegRead1_Q: std_logic_vector(4 downto 0);
	signal ID_EX_RegRead2_Q: std_logic_vector(4 downto 0);
	signal ID_EX_WriteData_Q: std_logic_vector(4 downto 0);
	signal ID_EX_Branch_Control: std_logic;
--	state signal
	signal ID_EX_State_D: std_logic := '0';
	signal ID_EX_State_Q: std_logic := '0';



	--EX/MEM
	signal EX_MEM_WB_D: std_logic_vector(1 downto 0);
	signal EX_MEM_WB_Q: std_logic_vector(1 downto 0);
	signal EX_MEM_M_D: std_logic;
	signal EX_MEM_M_Q: std_logic;
	signal EX_MEM_control_D: std_logic_vector(5 downto 0);
	signal EX_MEM_control_Q: std_logic_vector(5 downto 0);
	signal EX_MEM_ALU_D: std_logic_vector(31 downto 0);
	signal EX_MEM_ALU_Q: std_logic_vector(31 downto 0);
	signal EX_MEM_MWrite_D: std_logic_vector(31 downto 0);
	signal EX_MEM_MWrite_Q: std_logic_vector(31 downto 0);
	signal EX_MEM_RWrite_D: std_logic_vector(4 downto 0);
	signal EX_MEM_RWrite_Q: std_logic_vector(4 downto 0);
--	state signal
	signal EX_MEM_State_D: std_logic := '0';
	signal EX_MEM_State_Q: std_logic := '0';

	--MEM/WB
	signal MEM_WB_WB_D: std_logic_vector(1 downto 0);
	signal MEM_WB_WB_Q: std_logic_vector(1 downto 0);
	signal MEM_WB_MRead_D: std_logic_vector(31 downto 0);
	signal MEM_WB_MRead_Q: std_logic_vector(31 downto 0);
	signal MEM_WB_MAddr_D: std_logic_vector(31 downto 0);
	signal MEM_WB_MAddr_Q: std_logic_vector(31 downto 0);
	signal MEM_WB_RWrite_D: std_logic_vector(4 downto 0);
	signal MEM_WB_RWrite_Q: std_logic_vector(4 downto 0);
--	state signal


begin
-- Processor Core Behaviour

---------------------------------------- Port Map ----------------------------------------
	map_regtable : regtable PORT MAP
	(
		clk     => PCclk,
		rst     => rst,
		raddrA  => IF_ID_Inst_Q(25 downto 21),
		raddrB  => IF_ID_Inst_Q(20 downto 16),
		wen     => Reg_Write_Enable,
		waddr   => MEM_WB_RWrite_D,
		din	    => Reg_Write_Data,
		doutA   => ID_EX_RegData1_D,
		doutB   => ID_EX_RegData2_D,
		extaddr => regaddr,
		extdout => regdout
	);
 ---------------------------------------- Port Map ----------------------------------------
 ---------------------------------------- Start/Reset ----------------------------------------
	process (clk, rst)
		begin

	    if (rst='1') then Startrunning <= '0';
	    	elsif (clk'event and clk='1') then
	    		if (run='1') then Startrunning <= '1';
	    	end if;
	    end if;
	end process;
  ---------------------------------------- Start/Reset ----------------------------------------

------------------------------------------ Pipeline ------------------------------------------
--IF/ID
--------------------------------------- update required ---------------------------------------
	IF_ID_State_D <= '0' when Hazard_IF_EX_Control = '1' or Jump = '1' or IF_ID_Branch_Control = '1' else
					'1' when inst = Nil  else
					'0';
	IF_ID_Hazard_Control <= Hazard_IF_EX_Control;
	IF_ID_Jump_Control <= Jump;
	IF_ID_Branch_Control <= '1' when ZERO = '1' and ID_EX_Branch_Q = '1' else
							'0';
	IF_ID_PC_D <= PcNext;
	IF_ID_InstMem_D <= Nil when IF_ID_Hazard_Control = '1' or IF_ID_Jump_Control = '1' or IF_ID_Branch_Control = '1' else
						inst;
	process (PCclk)
	begin
		if (PCclk = '1' and PCclk'event) then
			if (IF_ID_Hazard_Control = '0') then
				IF_ID_Inst_Q <= IF_ID_InstMem_D;
				IF_ID_PC_Q <= IF_ID_PC_D;
				IF_ID_State_Q <= IF_ID_State_D;
			end if;
--			if (IF_ID_Hazard_Control = '1' or IF_ID_Jump_Control = '1' or IF_ID_Branch_Control = '1') then
--				IF_ID_Inst_Q(31 downto 26) <= "000000";
--			end if;
		end if;
	end process;

	ID_EX_WriteData_D <= IF_ID_Inst_Q(20 downto 16) when RegDst = '0' else
		IF_ID_Inst_Q(15 downto 11);

	ID_EX_State_D <= IF_ID_State_Q;

	ID_EX_Addr_D <= std_logic_vector(unsigned(IF_ID_PC_Q) + unsigned(resize(shift_left(unsigned(ID_EX_SignExt_D), 2), 32)));

	ID_EX_funct_D <= IF_ID_Inst_Q(5 downto 0);

--ID/EX
	process (PCclk)
	begin
		if(PCclk'event and PCclk = '1') then
			ID_EX_RegWrite_Q <= ID_EX_RegWrite_D;
			ID_EX_MemRead_Q <= ID_EX_MemRead_D;
			ID_EX_MemWrite_Q <= ID_EX_MemWrite_D;
			ID_EX_Branch_Q <= ID_EX_Branch_D;
			ID_EX_control_Q <= ID_EX_control_D;
			ID_EX_AluSrc_Q <= ID_EX_AluSrc_D;
			ID_EX_AluOp_Q <= ID_EX_AluOp_D;
			ID_EX_Addr_Q <= ID_EX_Addr_D;
			ID_EX_funct_Q <= ID_EX_funct_D;
			ID_EX_RegData1_Q <= ID_EX_RegData1_D;
			ID_EX_RegData2_Q <= ID_EX_RegData2_D;
			ID_EX_RegRead1_Q <= ID_EX_RegRead1_D;
			ID_EX_RegRead2_Q <= ID_EX_RegRead2_D;
			ID_EX_WriteData_Q <= ID_EX_WriteData_D;
			ID_EX_State_Q <= ID_EX_State_D;
			ID_EX_SignExt_Q <= ID_EX_SignExt_D;
			ID_EX_WB_Q <= ID_EX_WB_D;
			ID_EX_M_Q <= ID_EX_M_D;
		end if;
	end process;
	EX_MEM_WB_D <= ID_EX_WB_Q;
	EX_MEM_M_D <= ID_EX_M_Q;
	EX_MEM_RWrite_D <= ID_EX_WriteData_Q;
	EX_MEM_State_D <= ID_EX_State_Q;


--EX/MEM
	process (PCclk)
	begin
		if(PCclk'event and PCclk = '1') then
			EX_MEM_WB_Q <= EX_MEM_WB_D;
			EX_MEM_M_Q <= EX_MEM_M_D;
			EX_MEM_control_Q <= EX_MEM_control_D;
			EX_MEM_ALU_Q <= EX_MEM_ALU_D;
			EX_MEM_MWrite_Q <= EX_MEM_MWrite_D;
			EX_MEM_RWrite_Q <= EX_MEM_RWrite_D;
			EX_MEM_State_Q <= EX_MEM_State_D;
		end if;
	end process;
	MEM_WB_WB_D <= EX_MEM_WB_Q;
	MEM_WB_RWrite_D <= EX_MEM_RWrite_Q;
--MEM/WB
	process (PCclk)
	begin
		if(PCclk'event and PCclk = '1') then
			MEM_WB_WB_Q <= MEM_WB_WB_D;
			MEM_WB_MAddr_Q <= MEM_WB_MAddr_D;
			MEM_WB_MRead_Q <= MEM_WB_MRead_D;
			MEM_WB_RWrite_Q <= MEM_WB_RWrite_D;
		end if;
	end process;
	Reg_Write_Enable <= MEM_WB_WB_D(1); -- set reg write enable
------------------------------------------ Pipeline ------------------------------------------

  ---------------------------------------- IF stage, PC Control ----------------------------------------
	PCclk <= (clk) and (Startrunning) and (not Finishrunning);

	process (rst,PCclk)
	begin

		if (rst='1') then
			PC <= BaseAddress; -- 0x00400000 is the base address
	   	  elsif ( PCclk='1' and PCclk'event ) then
		    PC <= PCfirstMuxOut;
		    PCpre <= PC;
		end if;
	end process;

	PCout  <= PC;
	PcNext <= PC + Four;

	PCAdd_Sft_Out <= PcNext + (ID_EX_SignExt_D(29 downto 0) & "00");

--	process(rst, PCclk)
--	begin
--		if (rst = '1') then
--			PCfirstMuxOut <= BaseAddress + Four;
--		elsif (PCclk = '0' and PCclk'event) then
--			if (Hazard_PCMux_Control = '1') then
--				PCfirstMuxOut <= PC;	-- data hazard
--			elsif (PCSrc = "00") then
--				PCfirstMuxOut <= PcNext; -- normal
--			elsif (PCSrc = "01") then
--				PCfirstMuxOut <= ID_EX_Addr_Q;
--			elsif (PCSrc = "10") then
--				PCfirstMuxOut <= (PC(31 downto 28) & IF_ID_Inst_Q(25 downto 0 ) & "00");
--			else
--				PCfirstMuxOut <= PCAdd_Sft_Out;
--			end if;
--		end if;
--	end process;

	PCfirstMuxOut <= PC when Hazard_PCMux_Control = '1' else -- stall
	            	ID_EX_Addr_Q when IF_ID_Branch_Control = '1' else -- branch
			        (PC(31 downto 28) & IF_ID_Inst_Q(25 downto 0 ) & "00")  when IF_ID_Jump_Control = '1' else -- jump
	            	PcNext;
	instaddr <= PC;
  ---------------------------------------- PC Control ----------------------------------------


---------------------------------------- ID stage, Decode and set Hazard Stall ----------------------------------------

	ID_EX_control_D <= IF_ID_Inst_Q(31 downto 26);
	RegDst <= '1' when IF_ID_Inst_Q(31 downto 26)="000000" and Hazard_StallMux_Control='0' else -- 1 means RType
			  '0';


	Jump   <= '1' when IF_ID_Inst_Q(31 downto 27)="00001" and Hazard_StallMux_Control='0' else   --J, JAL
			  '1' when (RegDst='1' and (IF_ID_Inst_Q(5 downto 0) = "001000")) and Hazard_StallMux_Control='0' else   --JR
			  '0';

	ID_EX_Branch_D <= '1' when IF_ID_Inst_Q(31 downto 26)="000100" and Hazard_StallMux_Control='0' else   --beq
	          '1' when IF_ID_Inst_Q(31 downto 26)="000101" and Hazard_StallMux_Control='0' else  --bne
			  '0';

	ID_EX_WB_D(0) <= '1' when IF_ID_Inst_Q(31 downto 26)="101000" and Hazard_StallMux_Control='0' else --SB
	            '1' when IF_ID_Inst_Q(31 downto 26)="100011" and Hazard_StallMux_Control='0' else  --lw
			    '1' when IF_ID_Inst_Q(31 downto 26)="100000" and Hazard_StallMux_Control='0' else  --lb
			    '1' when IF_ID_Inst_Q(31 downto 26)="100100" and Hazard_StallMux_Control='0' else  --lbu
				'0';

	ID_EX_AluOp_D  <= "0000" when IF_ID_Inst_Q(31 downto 30)="10" and Hazard_StallMux_Control='0'		else  --save, load
        		"0001" when RType='1' and Hazard_StallMux_Control='0'                 	else  -- R-type
          		"0010" when IF_ID_Inst_Q(31 downto 26)="001000" and Hazard_StallMux_Control='0' else  --addi
	      		"0011" when IF_ID_Inst_Q(31 downto 26)="001100" and Hazard_StallMux_Control='0'	else  --andi
          		"0100" when IF_ID_Inst_Q(31 downto 26)="001101" and Hazard_StallMux_Control='0'	else  --ori
          		"0101" when IF_ID_Inst_Q(31 downto 26)="001010" and Hazard_StallMux_Control='0'	else  --slti
          		"0110" when IF_ID_Inst_Q(31 downto 26)="001011" and Hazard_StallMux_Control='0'	else  --sltiu
          		"0111" when IF_ID_Inst_Q(31 downto 26)="001111" and Hazard_StallMux_Control='0'	else  --Lui
	      		"1000" when Jump='1' and Hazard_StallMux_Control='0'                    else  --Jump
          		"1001";

	ID_EX_M_D <= '1' when IF_ID_Inst_Q(31 downto 26)="101000" and Hazard_StallMux_Control='0' else --sb
				'1' when IF_ID_Inst_Q(31 downto 26)="101011" and Hazard_StallMux_Control='0' else    --sw
			    '0';

	ID_EX_MemRead_D <= '1' when IF_ID_Inst_Q(31 downto 26) = "100011" else
						'0';


	ID_EX_AluSrc_D <= "00" when Hazard_StallMux_Control = '1' or ID_EX_Branch_D = '1' or Jump = '1' else
				"00" when RType='1' or ID_EX_Branch_D='1' or
		  		(RegDst='1' and	IF_ID_Inst_Q(5 downto 0)="001000") else  --beq, bne, RType, jr
			    "01" when IF_ID_Inst_Q(31 downto 26)="001000" or   --addi
					        IF_ID_Inst_Q(31 downto 26)="001010" or   --slti
					        IF_ID_Inst_Q(31 downto 26)="101000"	or   --sb
					        IF_ID_Inst_Q(31 downto 26)="100011" or   --lw
					        IF_ID_Inst_Q(31 downto 26)="101011" or   --sw
				            IF_ID_Inst_Q(31 downto 26)="100000" or   --lb
				            IF_ID_Inst_Q(31 downto 26)="100100"	else   --lbu
			    "10" when IF_ID_Inst_Q(31 downto 27)="00001" or   --j, jal
					        IF_ID_Inst_Q(31 downto 27)="00110" or     --andi, ori
				            IF_ID_Inst_Q(31 downto 26)="001011" or     --sltiu
					        IF_ID_Inst_Q(31 downto 26)="001111" else   --lui
		      	"11";  --The instruction is not allowed



    ID_EX_WB_D(1) <= '0' when Hazard_StallMux_Control = '1' or ID_EX_Branch_D = '1' or Jump = '1'  else
    			'1' when RType='1' or
						    IF_ID_Inst_Q(31 downto 26)="100011" or  --lw
						    IF_ID_Inst_Q(31 downto 26)="100000" or  --lb
						    IF_ID_Inst_Q(31 downto 26)="100100" or  --lbu
						    IF_ID_Inst_Q(31 downto 26)="000011" or   --JAL
						    IF_ID_Inst_Q(31 downto 29)="001" else    --Operation end with 'i'
	         	'0';


---------------------------------------- Decode and Set Hazard Stall ----------------------------------------

  ---------------------------------------- Decode ----------------------------------------

	RType <= '1' when RegDst='1' and (
					IF_ID_Inst_Q(5 downto 0) = "100000" or   --add
					IF_ID_Inst_Q(5 downto 0) = "100010" or   --sub
					IF_ID_Inst_Q(5 downto 0) = "100100" or   --and
					IF_ID_Inst_Q(5 downto 0) = "100101" or   --or
					IF_ID_Inst_Q(5 downto 0) = "101010" or   --slt
					IF_ID_Inst_Q(5 downto 0) = "101011"  )	else    --sltu
			 '0';

	PCSrc(1)  <= Jump;
	PCSrc(0)  <= '1' when Jump='0' and ID_EX_Branch_D='1' and ZERO='1' else
				       '1' when Jump='1' and IF_ID_Inst_Q(31 downto 26)="000000"  else
				       '0';

	Jal <= '1' when IF_ID_Inst_Q(31 downto 26)="000011" else
		   '0';
  ---------------------------------------- Decode ----------------------------------------





---------------------------------------- Hazard Detection Unit, 1 for hazard ----------------------------------------

	Hazard_PCMux_Control <= '1' when (IF_ID_Inst_Q(25 downto 21) = ID_EX_WriteData_Q and ID_EX_MemRead_Q = '1')
								or (IF_ID_Inst_Q(20 downto 16) = ID_EX_WriteData_Q and ID_EX_MemRead_Q = '1') else
							'0';
	Hazard_IF_EX_Control <= '1' when (IF_ID_Inst_Q(25 downto 21) = ID_EX_WriteData_Q and ID_EX_MemRead_Q = '1')
								or (IF_ID_Inst_Q(20 downto 16) = ID_EX_WriteData_Q and ID_EX_MemRead_Q = '1') else
							'0';
	Hazard_StallMux_Control <= '1' when (IF_ID_Inst_Q(25 downto 21) = ID_EX_WriteData_Q and ID_EX_MemRead_Q = '1')
									or (IF_ID_Inst_Q(20 downto 16) = ID_EX_WriteData_Q and ID_EX_MemRead_Q = '1') else
								'0';

---------------------------------------- Hazard Detection Unit ----------------------------------------



---------------------------------------- sign_extend ----------------------------------------

	ID_EX_SignExt_D <= "1111111111111111" & IF_ID_Inst_Q(15 downto 0) when IF_ID_Inst_Q(15)='1'
						else "0000000000000000" & IF_ID_Inst_Q(15 downto 0);

---------------------------------------- sign_extend ----------------------------------------


---------------------------------------- Forwarding Unit ------------------------------------
	Forwarding_ControlA <= "10" when EX_MEM_WB_Q(1) = '1' and ID_EX_RegRead1_Q = EX_MEM_RWrite_Q else
						"01" when MEM_WB_WB_Q(1) = '1' and ID_EX_RegRead1_Q = MEM_WB_RWrite_Q else
						"00";
	Forwarding_ControlB <= "10" when EX_MEM_WB_Q(1) = '1' and ID_EX_RegRead2_Q = EX_MEM_RWrite_Q else
						"01" when MEM_WB_WB_Q(1) = '1' and ID_EX_RegRead2_Q = MEM_WB_RWrite_Q else
						"00";
---------------------------------------- Forwarding Unit ------------------------------------

	---------------------------------------- EX stage, ALU Control ----------------------------------------

	aluin1 <= ID_EX_RegData1_Q when Forwarding_ControlA = "00" else
		Reg_Write_Data when Forwarding_ControlA = "01" else
		EX_MEM_ALU_Q;

	EX_MEM_control_D <= ID_EX_control_Q;
	EX_MEM_MWrite_D <= ID_EX_RegData2_Q when Forwarding_ControlB = "00" else
		Reg_Write_Data when Forwarding_ControlB = "01" else
		EX_MEM_ALU_Q;
	aluin2 <= EX_MEM_MWrite_D when ID_EX_AluSrc_Q = "00" else
		ID_EX_SignExt_Q;

	ALUConOut <="0110" when  (ID_EX_AluOp_Q = "0001" and ID_EX_funct_Q ="100000")  or (ID_EX_AluOp_Q = "0010") else --add,addi
	          "0001" when  (ID_EX_AluOp_Q = "0001" and ID_EX_funct_Q ="100101")  or (ID_EX_AluOp_Q = "0100") else --or ,ori
	          "0000" when  (ID_EX_AluOp_Q = "0001" and ID_EX_funct_Q ="100100")  or (ID_EX_AluOp_Q = "0011") else --and,andi
	          "1110" when  (ID_EX_AluOp_Q = "0001" and ID_EX_funct_Q ="100010")                    else --subt
	          "1111" when  (ID_EX_AluOp_Q = "0001" and ID_EX_funct_Q ="101010")                    else --slt
	          "0010" when  (ID_EX_AluOp_Q = "0001" and ID_EX_funct_Q ="101011")                    else --sltu
	          "0011" when   ID_EX_AluOp_Q = "0101"                                                   else --slti
	          "0100" when   ID_EX_AluOp_Q = "0110"                                                   else --sltiu
	          "0101" when   ID_EX_AluOp_Q = "0111"                                                   else --lui
	          "0111" when   ID_EX_AluOp_Q = "1000"                                                   else --jump
	          "1000" when   ID_EX_AluOp_Q = "0000"                                                   else -- save , load
	          "1001";


	Tem1  <=  aluin1 + aluin2        when ALUConOut = "0110" or ALUConOut = "1000"  else  --add
	         aluin1 OR  aluin2      when ALUConOut = "0001" else  --or
        		 aluin1 AND aluin2      when ALUConOut = "0000" else  --and
		       aluin2(15 downto 0) & "0000000000000000" when ALUConOut = "0101" else  --lui
		       aluin1 - aluin2;

	Tem2 <= ('1' & aluin1) - ('0' & aluin2);

	aluResult <= Tem1          when ALUConOut="0110" or ALUConOut="0001" or ALUConOut="0000" or ALUConOut="0101" or ALUConOut="1000" or ALUConOut="1001"  else
				 (others => '0')   when  ALUConOut="0111" else --Jump
				 "0000000000000000000000000000000" & NOT(Tem2(32)) when ALUConOut="0010" or ALUConOut="0100" else --sltiu sltu
				 "0000000000000000000000000000000" & Tem1(31); --slti , slt

	EX_MEM_ALU_D <= aluResult;

	BeforeZero <= '1' when aluResult="00000000000000000000000000000000" else '0';
	ZERO <= BeforeZero xor ID_EX_control_Q(0);


	---------------------------------------- ALU Control ----------------------------------------






	---------------------------------------- MEM stage, Memory & Data  ----------------------------------------
	--register write back mux
	Reg_Write_Data <= MEM_WB_MRead_D when MEM_WB_WB_D(0) = '1' else
		MEM_WB_MAddr_D;
	--end

	memaddr <= EX_MEM_ALU_Q(31 downto 2) & "00";
	memdw <= EX_MEM_MWrite_Q;

	MEM_WB_MAddr_D <= EX_MEM_ALU_Q;
	MEM_WB_MRead_D <= memdr;

--	memaddr <= aluResult(31 downto 2) & "00";

	memwen <= EX_MEM_M_Q;

----------------------
--------------------
-------------------------------
--------------------move to previous stage-------------------------

	aluo1  <= memdr when ID_EX_WB_Q(0)='1' else aluResult;


  ---------------------------------------- Memory & Data ----------------------------------------



   ---------------------------------------- WB stage, Value Writing ---------------------------------------- (checking)

   -------------------------------- WRONG SIGNAL HERE, UPDATE REQUIRED -------------------------------------
-- 	aluo2  <= "000000000000000000000000" & aluBuffer when
--                  IF_ID_Inst_Q(31 downto 26)="100100" or
--			           (IF_ID_Inst_Q(31 downto 26)="100000" and aluBuffer(7)='0') else
--			       "111111111111111111111111" & aluBuffer when
--			            IF_ID_Inst_Q(31 downto 26)="100000" and aluBuffer(7)='1' else
--			            PcNext when Jal='1'
--			            else aluo1;

 	aluo2  <= "000000000000000000000000" & aluBuffer when
                  EX_MEM_control_Q(5 downto 0)="100100" or
			           (EX_MEM_control_Q(5 downto 0)="100000" and aluBuffer(7)='0') else
			       "111111111111111111111111" & aluBuffer when
			            EX_MEM_control_Q(5 downto 0)="100000" and aluBuffer(7)='1' else
			            PcNext when Jal='1'
			            else aluo1;

	 aluBuffer <= aluo1(31 downto 24)  when aluin2(1 downto 0)="00" else
	      		 	 aluo1(23 downto 16)  when aluin2(1 downto 0)="01" else
		        	aluo1(15 downto  8)  when aluin2(1 downto 0)="10" else
		      		 aluo1( 7 downto  0);

	--RegWriteAddr <= MEM_WB_RWrite_Q;
--	RegWriteAddr <= "11111"         when Jal='1' else
--			            		IF_ID_Inst_Q(20 downto 16)  when RegDst = '0' else
--			            		IF_ID_Inst_Q(15 downto 11);
  ---------------------------------------- Value Writing ----------------------------------------



	---------------------------------------- Finish ----------------------------------------
--	STATE <= '1' when (IF_ID_Inst_Q(31 downto 30) & IF_ID_Inst_Q(28 downto 26)="10011" and not aluResult(1 downto 0)="00")
--	                  or (ID_EX_AluSrc_D="11" or not PCfirstMuxOut(1 downto 0)="00")
--	             else '0';


--	process(PCclk)
--	begin
--	if (PCclk = '1' and PCclk'event) then
--		STATE <= EX_MEM_State_Q;
--	end if;
--	end process;

	process (clk, run)
	begin

		if (run='1') then Finishrunning <= '0';
		  elsif (clk='1' and clk'event ) then
		    Finishrunning <= (Finishrunning or EX_MEM_State_Q);
		end if;
    end process;

	fin <= Finishrunning;
  ---------------------------------------- Finish ----------------------------------------

end arch_processor_core;
