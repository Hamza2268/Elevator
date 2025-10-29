LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY elevator_ctrl_tb IS
END ENTITY;

ARCHITECTURE tb OF elevator_ctrl_tb IS

    COMPONENT elevator_ctrl IS
        GENERIC (n : INTEGER := 10);

        PORT (
            clk, rst, push : IN STD_LOGIC;
            bn : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            mv_up, mv_dn, door_open : OUT STD_LOGIC;
            floor : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
        );
    END COMPONENT;

    -- Signals
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '1';
    SIGNAL push : STD_LOGIC := '1'; -- active low
    SIGNAL bn : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '1'); -- active low buttons
    SIGNAL mv_up : STD_LOGIC;
    SIGNAL mv_dn : STD_LOGIC;
    SIGNAL door_open : STD_LOGIC;
    SIGNAL floor : STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- Clock period definition
    CONSTANT clk_period : TIME := 20 ns; -- 50 MHz
    CONSTANT step_time : TIME := 5 ms; -- time to move between floors
    CONSTANT door_time : TIME := 2 ms;

    -- 7-segment expected values (active-low SSD)
    TYPE seg_lut_t IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(6 DOWNTO 0);
    CONSTANT seg_lut : seg_lut_t := (
        "1000000", -- 0
        "1111001", -- 1
        "0100100", -- 2
        "0110000", -- 3
        "0011001", -- 4
        "0010010", -- 5
        "0000010", -- 6
        "1111000", -- 7
        "0000000", -- 8
        "0010000" -- 9
    );

BEGIN

    -- Instantiate the DUT
    DUT : elevator_ctrl
    PORT MAP(
        clk => clk,
        rst => rst,
        push => push,
        bn => bn,
        mv_up => mv_up,
        mv_dn => mv_dn,
        door_open => door_open,
        floor => floor
    );

    -- Clock generation
    clk_gen : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR clk_period / 2;
        clk <= '1';
        WAIT FOR clk_period / 2;
    END PROCESS;

    -- Stimulus
    stim_proc : PROCESS
        PROCEDURE press_button(floor_num : INTEGER) IS
        BEGIN
            bn <= STD_LOGIC_VECTOR(to_unsigned(floor_num, 4)); -- choose floor
            push <= '0'; -- active low press
            WAIT FOR 2 ms;
            push <= '1';
        END PROCEDURE;

        PROCEDURE check_floor(expected : INTEGER; testname : STRING) IS
        BEGIN
            IF (floor = seg_lut(expected)) THEN
                REPORT testname & " PASS: Arrived at floor " & INTEGER'IMAGE(expected) SEVERITY NOTE;
            ELSE
                REPORT testname & " FAIL: Expected floor " & INTEGER'IMAGE(expected) SEVERITY ERROR;
            END IF;
        END PROCEDURE;

    BEGIN
        -- RESET
        rst <= '0';
        WAIT FOR 100 ns;
        rst <= '1';
        REPORT "System reset complete" SEVERITY NOTE;
        WAIT FOR 2 ms;

        -- TEST 1: Go from floor 0 to 3
        REPORT "TEST 1: Request floor 3" SEVERITY NOTE;
        press_button(3);
        WAIT FOR step_time * 3;
        check_floor(3, "TEST 1");
        WAIT FOR door_time;

        -- TEST 2: Request floor 7
        REPORT "TEST 2: Request floor 7" SEVERITY NOTE;
        press_button(7);
        WAIT FOR step_time * 4;
        check_floor(7, "TEST 2");
        WAIT FOR door_time;

        -- TEST 3: Request floor 2
        REPORT "TEST 3: Request floor 2" SEVERITY NOTE;
        press_button(2);
        WAIT FOR step_time * 5;
        check_floor(2, "TEST 3");
        WAIT FOR door_time;

        -- TEST 4: Multiple requests (floors 5 and 9)
        REPORT "TEST 4: Request floor 5 then 9" SEVERITY NOTE;
        press_button(5);
        WAIT FOR 200 ns;
        press_button(9);
        WAIT FOR step_time * 7;
        check_floor(9, "TEST 4");
        WAIT FOR door_time;

        REPORT "All tests completed successfully." SEVERITY NOTE;
        WAIT;
    END PROCESS;

END ARCHITECTURE tb;