----------------------------------------------------------------------------
--
--  D Flip-Flop with Reset (dff_reset)
--
--  This is an implementation of a D-type flip-flop with reset in VHDL.  It
--  uses a behavioral type architecture.  There are architectures for both
--  synchronous and asynchronous reset.
--
--  Revision History:
--      8 Apr 98  Glen George       Initial revision.
--     10 May 99  Glen George       Fixed bug in qn outputs.
--     10 May 99  Glen George       Updated comments.
--      6 Nov 99  Glen George       Updated formatting and comments.
--     19 Oct 00  Glen George       Removed default output for qn.
--      4 Apr 02  Glen George       Updated comments.
--      7 Oct 02  Glen George       Updated comments.
--      4 Nov 05  Glen George       Updated comments.
--     24 Oct 26  Steven Lei        Update q from buffer to out port model (2008)
--                                  and to use rising_edge(clk)
----------------------------------------------------------------------------


-- bring in the necessary packages
library  ieee;
use  ieee.std_logic_1164.all;


--
--  D Flip-Flop with Reset entity declaration
--

entity  dff_reset  is
    port (
        clk    :  in  std_logic;            -- clock input
        reset  :  in  std_logic;            -- active high reset input
        d      :  in  std_logic;            -- data in
        q      :  out  std_logic;           -- q output (feeds back)
        qn     :  out  std_logic            -- qbar output
    );
end  dff_reset;


--
--  D Flip-Flop with Reset synchronous behavioral architecture
--

architecture  sync  of  dff_reset  is
begin

    process (clk)                   -- only change on clock
    begin
        if  rising_edge(clk)  then         -- look for a rising edge on the clock
            if  reset = '1'  then   -- check for reset
                q <= '0';
            else                    -- no reset, clock in the d input
                q <= d;
            end if;
        end if;
    end process;

    qn <= not q;                    -- qbar is always opposite of q

end  sync;


--
--  D Flip-Flop with Reset asynchronous behavioral architecture
--

architecture  async  of  dff_reset  is
begin

    process (clk, reset)            -- change output on clock or reset inputs
    begin
        if  reset = '1'  then       -- check for reset (highest priority)
            q <= '0';
        elsif rising_edge(clk)  then    -- no reset, check clock edge
            q <= d;                 -- on clock edge, store d value
        end if;
    end process;

    qn <= not q;                    -- qbar is always opposite of q

end  async;
