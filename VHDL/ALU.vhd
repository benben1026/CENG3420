library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entitiy ALU is 
	port (
		A	:	in std_logic_vector;
		B	:	in std_logic_vector;
		AorSin	:	in std_logic_vector;
		Carry_in:	in std_logic_vector;
		op	:	in std_logic_vector;
		AorSout	:	out std_logic_vector;
		carry_out:	out std_logic_vector;
		result	:	out std_logic_vector
	);
end ALU;

