-------------------------
-- EE119a HW3
-- L 
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- conversion bin = bcd [7..4] * 10  + bcd[3..0]
-- [bcd 7 .. 4]  = upper
-- [bcd 3 .. 0] = lower
-- upper * 8 + upper + upper = upper * 10
-- bin = upper * 10 + lower

entity BCD2Binary8 is
    port (
        -- input 8 bit BCD value
        BCD : in  std_logic_vector(7 downto 0);
        -- output 8 bit binary value
        B   : out std_logic_vector(7 downto 0)
    );
end entity BCD2Binary8;

architecture DataFlow of BCD2Binary8 is
    -- upper four bits of BCD value (ten's place), extended to 8 bits
    signal BCD_Upper: unsigned (BCD'length - 1 downto 0);
    -- lower four bits of BCD value (one's place), extended to 8 bits
    signal BCD_Lower: unsigned (BCD'length - 1 downto 0);

begin
    -- for both signals below perform zero extension to make final addition simple 
    BCD_Upper <= "0000" & unsigned(BCD(7 downto 4)); 
    BCD_Lower <= "0000" & unsigned(BCD(3 downto 0));
    B <= std_logic_vector(resize((BCD_Upper sll 3) + BCD_Upper + BCD_Upper + BCD_Lower, 8));

end architecture DataFlow;

