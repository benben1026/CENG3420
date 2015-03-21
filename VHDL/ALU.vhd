library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entitiy ALU is 
	port (
		A	:	in std_logic_vector (31 downto 0);
		B	:	in std_logic_vector (31 downto 0);
		op	:	in std_logic_vector (3 downto 0);
		less: out std_logic;
		result	:	out std_logic_vector (31 downto 0)
	);
end ALU;

architecture arch_ALU of ALU is 
begin
  process(A, B, op)
    variable msb_a: std_logic;
    variable msb_b: std_logic;
    begin
      case op is
        when "0000" =>
          result <= A + B;
          msb_a := A(31) and B(31);
          msb_b := A(30) and B(30);
          less <= msb_a xor msb_b;
        when "0010" =>
          result <= A + (not B) + 1;
          msb_a := A(31) and B(31);
          msb_b := A(30) and B(30);
          less <= msb_a xor msb_b;
        when "0100" =>
          result <= A and B;
          less <= "0";
        when "0101" =>
          result <= A or B;
          less <= "0";
        when "0110" =>
          result <= (A or B) and (not (A and B));
          less <= "0";
        when "0111" =>
          result <= (not A) and (not B);
          less <= "0";
        when "1000" =>
          if A < B then
            result <= "11111111111111111111111111111111";
          else 
            result <= "00000000000000000000000000000000";
          end if;
          less <= "0";
        when "1001" =>
          if (unsigned)A < (unsigned)B then
            result <= "11111111111111111111111111111111";
          else 
            result <= "00000000000000000000000000000000";
          end if;
          less <= "0";
      end case;
      
    end process;
    
end arch_ALU;
        
          
      