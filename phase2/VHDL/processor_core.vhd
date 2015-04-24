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

	--Signal: State Control
	signal STATE: STD_LOGIC;
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
	constant Four: STD_LOGIC_VECTOR(31 downto 0) := "00000000000000000000000000000100";
	constant BaseAddress: STD_LOGIC_VECTOR(31 downto 0) :="00000000000000000100000000000000"; --0x00400000
	signal PcNext: STD_LOGIC_VECTOR(31 downto 0);--newpc
	signal PCAdd_Sft_Out: STD_LOGIC_VECTOR(31 downto 0);--brloc
	signal PCfirstMuxOut: STD_LOGIC_VECTOR(31 downto 0);--PCSrc2
	signal PCclk: STD_LOGIC;
	signal PC: STD_LOGIC_VECTOR(31 downto 0);

	signal ZERO, Jal, BeforeZero: STD_LOGIC;
	signal Tem1: STD_LOGIC_VECTOR(31 downto 0);	
	signal Tem2: STD_LOGIC_VECTOR(32 downto 0);
	signal aluBuffer: STD_LOGIC_VECTOR(7 downto 0);	
	signal RegWriteAddr: STD_LOGIC_VECTOR(4 downto 0);
	signal aluMult, aluResult ,aluin1, aluin2, aluo1, aluo2 : STD_LOGIC_VECTOR(31 downto 0);		
	signal ALUConOut: std_logic_vector (3 downto 0);


	-- Signal: Hazard Detection Unit
	signal Hazard_PCMux_Control: std_logic;
	signal Hazard_IF_EX_Control: std_logic;
	signal Hazard_StallMux_Control: std_logic;
	-- ID_EX isolator
	signal ID_EX_WriteAddr_Q: std_logic_vector(4 downto 0);

	-- Taking input: MemRead, Register_Read_1, Register_Read_2, Register_Write


	signal Reg_Write_Data: std_logic_vector(31 downto 0);
	--Forwarding Unit
	signal ID_EX_Read_1_Q: std_logic_vector(31 downto 0);
	signal ID_EX_Read_2_Q: std_logic_vector(31 downto 0);
	signal Forwarding_ControlA: std_logic_vector(1 downto 0);
	signal Forwarding_ControlB: std_logic_vector(1 downto 0);

	--IF/ID

	--ID/EX

	--EX/MEM
	signal EX_MEM_WB_D: std_logic;
	signal EX_MEM_WB_Q: std_logic;
	signal EX_MEM_M_D: std_logic;
	signal EX_MEM_M_Q: std_logic;
	signal EX_MEM_ALU_D: std_logic;
	signal EX_MEM_ALU_Q: std_logic;
	signal EX_MEM_MWrite_D: std_logic_vector(31 downto 0);
	signal EX_MEM_MWrite_Q: std_logic_vector(31 downto 0);
	signal EX_MEM_RWrite_D: std_logic_vector(31 downto 0);
	signal EX_MEM_RWrite_Q: std_logic_vector(31 downto 0);

	--MEM/WB
	signal MEM_WB_WB_D: std_logic;
	signal MEM_WB_WB_Q: std_logic;
	signal MEM_WB_MRead_D: std_logic_vector(31 downto 0);
	signal MEM_WB_MRead_Q: std_logic_vector(31 downto 0);
	signal MEM_WB_MWrite_D: std_logic_vector(31 downto 0);
	signal MEM_WB_MWrite_Q: std_logic_vector(31 downto 0);
	signal MEM_WB_RWrite_D: std_logic_vector(31 downto 0);
	signal MEM_WB_RWrite_Q: std_logic_vector(31 downto 0);


begin
-- Processor Core Behaviour

---------------------------------------- Port Map ----------------------------------------
	map_regtable : regtable PORT MAP
	(
		clk     => PCclk,
		rst     => rst,
		raddrA  => inst(25 downto 21),
		raddrB  => inst(20 downto 16),
		wen     => RegWrite,
		waddr   => RegWriteAddr,
		din	    => Reg_Write_Data,
		doutA   => aluin1,
		doutB   => aluMult,
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

--ID/EX

--EX/MEM
	process (PCclk)
	begin
		if(PCclk'event and PCclk = '1') then
			EX_MEM_WB_Q <= EX_MEM_WB_D;
			EX_MEM_M_Q <= EX_MEM_M_D;
			EX_MEM_ALU_Q <= EX_MEM_ALU_D;
			EX_MEM_MWrite_Q <= EX_MEM_MWrite_D;
			EX_MEM_RWrite_Q <= EX_MEM_RWrite_D;
		end if;
	end process;

--MEM/WB
	process (PCclk)
	begin
		if(PCclk'event and PCclk = '1') then 
			MEM_WB_WB_Q <= MEM_WB_WB_D;
			MEM_WB_MWrite_Q <= MEM_WB_MWrite_D;
			MEM_WB_MRead_Q <= MEM_WB_MRead_D;
			MEM_WB_RWrite_Q <= MEM_WB_RWrite_D;
		end if;
	end process;
------------------------------------------ Pipeline ------------------------------------------

  ---------------------------------------- PC Control ----------------------------------------
	PCclk <= (clk) and (Startrunning) and (not Finishrunning);

	process (rst,PCclk)
	begin

		if (rst='1') then
			PC <= BaseAddress; -- 0x00400000 is the base address		
	   	  elsif ( PCclk='1' and PCclk'event ) then
		    PC <= PCfirstMuxOut;
		end if;		
	end process;

	PCout  <= PC;
	PcNext <= PC + Four;
	
	PCAdd_Sft_Out <= PcNext + (SignExtension(29 downto 0) & "00");
	
	PCfirstMuxOut <= PcNext                                         when PCSrc="00" else
	               PCAdd_Sft_Out                                  when PCSrc = "01" else
				        (PC(31 downto 28) & inst(25 downto 0 ) & "00")  when PCSrc = "10" else
	               aluin1;
	instaddr <= PC;
  ---------------------------------------- PC Control ----------------------------------------


  ---------------------------------------- Decode ----------------------------------------
			 
	RegDst <= '1' when inst(31 downto 26)="000000" else -- 1 means RType
			  '0';


	Jump   <= '1' when inst(31 downto 27)="00001" else   --J, JAL
			  '1' when (RegDst='1' and (inst(5 downto 0) = "001000")) else   --JR
			  '0';
			  
	Branch <= '1' when inst(31 downto 26)="000100"  or   --beq
	                   inst(31 downto 26)="000101" else  --bne 
			  '0'; 
		    
	MemToReg <= '1' when inst(31 downto 26)="101000" or --SB
	                     inst(31 downto 26)="100011" or  --lw
						           inst(31 downto 26)="100000" or  --lb
						           inst(31 downto 26)="100100" else  --lbu  
				'0';
				
	ALUOp  <= "0000" when inst(31 downto 30)="10"      else  --save, load
          "0001" when RType='1'                    else  -- R-type
          "0010" when inst(31 downto 26)="001000"  else  --addi
	      "0011" when inst(31 downto 26)="001100"  else  --andi
          "0100" when inst(31 downto 26)="001101"  else  --ori
          "0101" when inst(31 downto 26)="001010"  else  --slti
          "0110" when inst(31 downto 26)="001011"  else  --sltiu
          "0111" when inst(31 downto 26)="001111"  else  --Lui
	      "1000" when Jump='1'                     else  --Jump
          "1001";
          
	MemWrite <= '1' when inst(31 downto 26)="101000" or --sb
					           	 inst(31 downto 26)="101011" else    --sw
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
				
	RType <= '1' when RegDst='1' and (
					inst(5 downto 0) = "100000" or   --add
					inst(5 downto 0) = "100010" or   --sub
					inst(5 downto 0) = "100100" or   --and
					inst(5 downto 0) = "100101" or   --or
					inst(5 downto 0) = "101010" or   --slt
					inst(5 downto 0) = "101011"  )	else    --sltu
			 '0';
			  
	PCSrc(1)  <= Jump;
	PCSrc(0)  <= '1' when Jump='0' and Branch='1' and ZERO='1' else
				       '1' when Jump='1' and inst(31 downto 26)="000000"  else
				       '0';
				 
	aluin2 <= aluMult when ALUSrc="00" else
			SignExtension    when ALUSrc="01" else
			"0000000000000000" & inst(15 downto 0);
			
	Jal <= '1' when inst(31 downto 26)="000011" else 
		   '0';
  ---------------------------------------- Decode ----------------------------------------
  
  
  

---------------------------------------- sign_extend ----------------------------------------

	SignExtension <= "1111111111111111" & inst(15 downto 0) when inst(15)='1'
		else "0000000000000000" & inst(15 downto 0);	 

---------------------------------------- sign_extend ----------------------------------------


---------------------------------------- Forwarding Unit ------------------------------------
	Forwarding_ControlA <= "10" when EX_MEM_WB_Q = 1 and ID_EX_Read_1_Q = EX_MEM_RWrite_Q else
						"01" when MEM_WB_WB_Q = 1 and ID_EX_Read_1_Q = MEM_WB_RWrite_Q else
						"00";
	Forwarding_ControlB <= "10" when EX_MEM_WB_Q = 1 and ID_EX_Read_2_Q = EX_MEM_RWrite_Q else
						"01" when MEM_WB_WB_Q = 1 and ID_EX_Read_2_Q = MEM_WB_RWrite_Q else
						"00";
---------------------------------------- Forwarding Unit ------------------------------------

	---------------------------------------- ALU Control ----------------------------------------
	
	aluin1 <= ID_EX_RegData1 when Forwarding_ControlA = "00" else
		<=  when Forwarding_ControlA = "01" else
		<= EX_MEM_ALU_Q;

	EX_MEM_MWrite_D <= ID_EX_RegData1 when Forwarding_ControlB = "00" else
		<=  Reg_Write_Data when Forwarding_ControlB = "01" else
		<= EX_MEM_ALU_Q;
	--aluin2 <= 
	
	ALUConOut <="0110" when  (ALUOp = "0001" and inst(5 downto 0)="100000")  or ALUOp = "0010" else --add,addi
	          "0001" when  (ALUOp = "0001" and inst(5 downto 0)="100101")  or ALUOp = "0100" else --or ,ori 
	          "0000" when  (ALUOp = "0001" and inst(5 downto 0)="100100")  or ALUOp = "0011" else --and,andi
	          "1110" when  (ALUOp = "0001" and inst(5 downto 0)="100010")                    else --subt
	          "1111" when  (ALUOp = "0001" and inst(5 downto 0)="101010")                    else --slt
	          "0010" when  (ALUOp = "0001" and inst(5 downto 0)="101011")                    else --sltu
	          "0011" when   ALUOp = "0101"                                                   else --slti 
	          "0100" when   ALUOp = "0110"                                                   else --sltiu
	          "0101" when   ALUOp = "0111"                                                   else --lui
	          "0111" when   ALUOp = "1000"                                                   else --jump
	          "1000" when   ALUOp = "0000"                                                   else -- save , load
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
				 
	BeforeZero <= '1' when aluResult="00000000000000000000000000000000" else '0';
	ZERO <= BeforeZero xor inst(26);


	---------------------------------------- ALU Control ----------------------------------------




	---------------------------------------- Hazard Detection Unit ----------------------------------------

	Hazard_PCMux_Control <= '1' when inst(25 downto 21) = ID_EX_WriteAddr_Q and MemToReg = '1' 
								or inst(20 downto 16) = ID_EX_WriteAddr_Q and MemToReg = '1'
								else '0';
	Hazard_IF_EX_Control <= '1' when inst(25 downto 21) = ID_EX_WriteAddr_Q and MemToReg = '1' 
								or inst(20 downto 16) = ID_EX_WriteAddr_Q and MemToReg = '1'
								else '0';
	Hazard_StallMux_Control <= '1' when inst(25 downto 21) = ID_EX_WriteAddr_Q and MemToReg = '1' 
								or inst(20 downto 16) = ID_EX_WriteAddr_Q and MemToReg = '1'
								else '0';




	---------------------------------------- Hazard Detection Unit ----------------------------------------





	---------------------------------------- Memory & Data  ----------------------------------------
	memaddr <= EX_MEM_ALU_Q(31 downto 2) & "00";
	memdw <= EX_MEM_MWrite_Q;
	MEM_WB_MRead_D <= memdr;

	--memaddr <= aluResult(31 downto 2) & "00";
	
	memwen <= MemWrite;
	
	--memdw  <=aluo1(31 downto 8) & aluMult(7 downto 0) 
	--		   when inst(31 downto 26)="101000" and aluResult(1 downto 0)="11" else
			       
	--         aluMult(7 downto 0) & aluo1(23 downto 0) 
	--         when inst(31 downto 26)="101000" and aluResult(1 downto 0)="00" else
	         			      
	--		   aluo1(31 downto 16) & aluMult(7 downto 0) & aluo1(7 downto 0) 
	--		   when inst(31 downto 26)="101000" AND aluResult(1 downto 0)="10" else
			   
	--		   aluo1(31 downto 24) & aluMult(7 downto 0) & aluo1(15 downto 0) 
	--		   when inst(31 downto 26)="101000" and aluResult(1 downto 0)="01" else		   
			       
	--		   aluMult;
	
	--aluo1  <= memdr when MemToReg='1' else aluResult;
	
	
  ---------------------------------------- Memory & Data ----------------------------------------

		
	
   ---------------------------------------- Value Writing ----------------------------------------
 	aluo2  <= "000000000000000000000000" & aluBuffer when
                  inst(31 downto 26)="100100" or
			           (inst(31 downto 26)="100000" and aluBuffer(7)='0') else
			       "111111111111111111111111" & aluBuffer when 
			            inst(31 downto 26)="100000" and aluBuffer(7)='1' else
			            PcNext when Jal='1' 
			            else aluo1;
	 
	 aluBuffer <= aluo1(31 downto 24)  when aluin2(1 downto 0)="00" else
	      		 	 aluo1(23 downto 16)  when aluin2(1 downto 0)="01" else
		        	aluo1(15 downto  8)  when aluin2(1 downto 0)="10" else
		      		 aluo1( 7 downto  0);
				
				   
	 RegWriteAddr <= "11111"         when Jal='1' else
			            		inst(20 downto 16)  when RegDst = '0' else
			            		inst(15 downto 11);
  ---------------------------------------- Value Writing ----------------------------------------



	---------------------------------------- Finish ----------------------------------------
	STATE <= '1' when (inst(31 downto 30) & inst(28 downto 26)="10011" and not aluResult(1 downto 0)="00")
	                  or (ALUSrc="11" or not PCfirstMuxOut(1 downto 0)="00")
	             else '0';
	process (clk, run)
	begin

		if (run='1') then Finishrunning <= '0';	
		  elsif (clk='1' and clk'event ) then
		    Finishrunning <= (Finishrunning or STATE);
		end if;
    end process;

	fin <= Finishrunning;
  ---------------------------------------- Finish ----------------------------------------

end arch_processor_core;
