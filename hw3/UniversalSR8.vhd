
library ieee;
use ieee.std_logic_1164.all;

entity UniversalSR8 is 

    port (
        D    : in      std_logic_vector(7 downto 0);
        LSer : in      std_logic;
        RSer : in      std_logic;
        Mode : in      std_logic_vector(1 downto 0);
        CLR  : in      std_logic;
        CLK  : in      std_logic;
        Q    : buffer  std_logic_vector(7 downto 0)
    );
    

end UniversalSR8;

architecture structural of UniversalSR8 is
    component IC74194 is 
        port (
            DI   :  in      std_logic_vector(3 downto 0);
            LSI  :  in      std_logic;
            RSI  :  in      std_logic;
            S    :  in      std_logic_vector(1 downto 0);
            CLR  :  in      std_logic;
            CLK  :  in      std_logic;
            DO   :  buffer  std_logic_vector(3 downto 0)
        );
    end component IC74194;
begin
    lower_shift_register: entity work.IC74194(DataFlow)
        port map (
            DI => D(3 downto 0),
            LSI => LSer,
            RSI => Q(4),
            S => Mode,
            CLR => CLR,
            CLK => CLK,
            DO => Q(3 downto 0)
        );
    upper_shift_register: entity work.IC74194(DataFlow)
        port map (
            DI => D(7 downto 4),
            LSI => Q(3),
            RSI => RSer,
            S => Mode,
            CLR => CLR,
            CLK => CLK,
            DO => Q(7 downto 4)
        );
end architecture structural;