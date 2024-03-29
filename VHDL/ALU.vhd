library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ALU is
	port (
		A	:	in std_logic_vector (31 downto 0);
		B	:	in std_logic_vector (31 downto 0);
		op	:	in std_logic_vector (3 downto 0);
		result	:	out std_logic_vector (31 downto 0);
		ZERO : out std_logic
	);
end ALU;

architecture arch_ALU of ALU is 
signal less : std_logic;
begin
  process(A, B, op)
    variable msb_a: std_logic;
    variable msb_b: std_logic;
    variable temp: std_logic;
    variable temp_res: std_logic_vector (31 downto 0);
    begin
      case op is
        -- addition
        when "0000" =>
          result <= A + B;
          temp_res := A + B;
          msb_a := A(31) and B(31);
          msb_b := A(30) and B(30);
          less <= msb_a xor msb_b;
        -- substraction
        when "0010" =>
          result <= A + (not B) + 1;
          temp_res := A + (not B) + 1;
          msb_a := A(31) and B(31);
          msb_b := A(30) and B(30);
          less <= msb_a xor msb_b;
        -- and
        when "0100" =>
          result <= A and B;
          temp_res := A and B;
          less <= '0';
        -- or
        when "0101" =>
          result <= A or B;
          temp_res := A or B;
          less <= '0';
        -- xor
        when "0110" =>
          result <= A xor B;
          temp_res := A xor B;
          less <= '0';
        -- nor
        when "0111" =>
          result <= A nor B;
          temp_res := A nor B;
          less <= '0';
        -- slt
        when "1010" =>
          if signed(A) < signed(B) then
            result <= "11111111111111111111111111111111";
            temp_res := "11111111111111111111111111111111";
          else 
            result <= "00000000000000000000000000000000";
            temp_res := "00000000000000000000000000000000";
        end if;
          less <= '0';
        -- sltu
        when "1011" =>
          if unsigned(A) < unsigned(B) then
            result <= "11111111111111111111111111111111";
         else 
            result <= "00000000000000000000000000000000";
          end if;
          less <= '0';
        when others =>
          null;
      end case;
      temp := temp_res(0) or temp_res(1);
      for ii in 2 to 31 loop
        temp := temp or temp_res(ii);
      end loop;
      ZERO <= not temp;
      
    end process;
    
end arch_ALU;
        
          
      