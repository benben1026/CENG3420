library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity PC is 
  port (
    clk : in std_logic;
    jumpaddr : in std_logic_vector (25 downto 0);
    addr : in std_logic_vector (31 downto 0);
    braddr : in std_logic_vector (31 downto 0);
    pcclr : in std_logic;
    pcsrc : in std_logic;
    jumpcntl : in std_logic;
    outaddr : out std_logic_vector (31 downto 0)
  );
end PC;

architecture arch_PC of PC is 
signal pcaddr : std_logic_vector (31 downto 0);
begin
  process(clk, jumpaddr, addr, braddr, pcsrc, jumpcntl, pcclr)
    begin
      if (falling_edge(clk)) then
        if pcclr = '1' then
          outaddr <= "00000000000000000000000000000000";
          pcaddr <= "00000000000000000000000000000000";
        elsif jumpcntl = '1' then
          outaddr (31 downto 28) <= "0000";
          outaddr (27 downto 2) <= jumpaddr;
          outaddr (1 downto 0) <= "00"; 
          pcaddr (31 downto 28) <= "0000";
          pcaddr (27 downto 2) <= jumpaddr;
          pcaddr (1 downto 0) <= "00"; 
        elsif pcsrc = '1' then
          outaddr <= braddr;
          pcaddr <= braddr;
        else
          outaddr <= pcaddr + 4;
          pcaddr <= pcaddr + 4;
        end if;
      end if;
    end process;
end arch_PC;
      
        
    
    
