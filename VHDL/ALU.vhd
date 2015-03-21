library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entitiy ALU is 
	port (
		A	:	in std_logic_vector;
		B	:	in std_logic_vector;
		carry_in:	in std_logic_vector;
		less_in: in std_logic_vector;
		op	:	in std_logic_vector;
		less_out: out std_logic_vector;
		carry_out:	out std_logic_vector;
		result	:	out std_logic_vector
	);
end ALU;

architecture arch_ALU of ALU is 
  signal temp: std_logic_vector;
begin
  process(A, B, carry_in, op)
    begin
      case op is
        when "0000" =>
          result <= A + B;
        when "0001" =>
          result <= (unsigned)A + (unsigned)B;
        when "0010" =>
          result <= A + (not B) + 1;
        when "0011" =>
          result <= (unsigned)A + (not (unsigned)B) + 1;
        when "0100" =>
          result <= A and B;
        when "0101" =>
          result <= A or B;
        when "0110" =>
          result <= (A or B) and (not (A and B));
        when "0111" =>
          result <= (not A) and (not B);
        when "1000" =>
          temp <= A + (not B) + 1;
          if temp < 0 then
            result <= "11111111111111111111111111111111";
          else 
            result <= "00000000000000000000000000000000";
          end if;
        when "1001" =>
          temp <= (unsigned) A + (not (unsigned) B);
          if temp < 0 then
            result <= "11111111111111111111111111111111";
          else 
            result <= "00000000000000000000000000000000";
          end if;
      end case;
      
    end process;
    
end arch_ALU;
        
          
      