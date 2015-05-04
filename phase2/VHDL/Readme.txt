CENG3420 Project Phase 2

Group number: 24
Student:	WANG Yuxi 1155014399
		ZHOU wei 1155014575

processor_core.vhd:
	The main VHDL file contains all relevant code, which aims to simulate a 5-stage pipeline MIPS processor. This code file is written with reference to the provided single-cycle mips implementation.

memtable.vhd, processor.vhd, processor_tb.vhd, regtable.vhd:
	The provided code are not modified.

Datapath.png:
	A photocopy of our datapath, details of the modification are provided as follows:

		- The signals with each stage are calculated and copies concurrently. And the input signals of a pipeline register is copied to the output signals on rising edge of clock cycle.
		- The names of signals written on the photocopy are the names of the corresponding signals in the code file.

		Modification [1]: 
				Marked as [1] in the photocopy. There is a signal connected to Multiplexor 1 and it should be the destination address of a jump instruction in our implementation.
				The destination address signal is actually implemented as (PC(31 downto 28) & IF_ID_Inst_Q(25 downto 0 ) & "00"), where IF_ID_Inst_Q is the 32 bit instruction and PC is the 32 bit PC address.

		Modification [2]: 
				Marked as [2] in the photocopy, which is near Multiplexor 5. The Multiplexor 5 is actually moved to MEM stage, which is before the MEM/WB pipeline register.
				Also, the signal connected to the output signal of MEM/WB pipeline register WB port is deleted and the input is directed connected to the Register as well as Mux 5..
				The passing of the output signal of Mux 5 as well as the  the input signal of MEM/WB pipeline register WB port is triggered by rising edge.


