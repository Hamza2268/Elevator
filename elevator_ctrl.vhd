
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY elevator_ctrl IS
    GENERIC (n : INTEGER := 10);
    PORT (
        clk, rst, push : IN STD_LOGIC;
        bn : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        mv_up, mv_dn, door_open : OUT STD_LOGIC;
        floor : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
    );
END elevator_ctrl;

ARCHITECTURE arch OF elevator_ctrl IS

    -- COMPONENT RESOLVER

    COMPONENT RESOLVER IS
        GENERIC (n : INTEGER := 10);
        PORT (
            CurrentFloor : IN INTEGER;
            Request : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            Direction : IN STD_LOGIC;
            TargetFloor : OUT INTEGER;
            NextDir : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT ssd IS
        PORT (
            bin : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    CONSTANT CLK_FREQ : INTEGER := 25000; -- 25000000
    CONSTANT DELAY : INTEGER := 2;

    SIGNAL sec_cnt : INTEGER RANGE 0 TO CLK_FREQ - 1;
    SIGNAL clk_en : STD_LOGIC := '0';

    TYPE state IS (idle, moving_up, moving_down, door_op, door_close);
    SIGNAL state_reg, state_next : state := idle;
    SIGNAL timer, floor_timer : INTEGER := 0;

    -- SIGNAL up, dn, rdy : STD_LOGIC;

    SIGNAL CurrentFloor, REQUIRED : INTEGER := 0;
    SIGNAL Request : STD_LOGIC_VECTOR(n - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL DIRECTION, NextDir : STD_LOGIC := '1';

    SIGNAL ssdin : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
    P : RESOLVER PORT MAP(CurrentFloor, Request, DIRECTION, REQUIRED, NextDir);
    -- DIRECTION <= NextDir;

    clockAdjust : PROCESS (clk, rst)
    BEGIN
        IF rst = '0' THEN
            sec_cnt <= 0;
            clk_en <= '0';
        ELSIF rising_edge(clk) THEN
            IF sec_cnt = CLK_FREQ - 1 THEN
                sec_cnt <= 0;
                clk_en <= NOT clk_en;
            ELSE
                sec_cnt <= sec_cnt + 1;
            END IF;
        END IF;
    END PROCESS;

    mainProcess : PROCESS (clk_en, rst, state_reg, REQUIRED, push)
    BEGIN
        IF (rst = '0') THEN
            state_reg <= idle;
            DIRECTION <= '1';
            request <= (OTHERS => '0');
        ELSIF rising_edge(clk_en) THEN
            state_reg <= state_next;
            DIRECTION <= NextDir;
            CASE state_reg IS
                WHEN idle =>
                    IF (rst = '1') THEN
                        IF (REQUIRED > CurrentFloor) THEN
                            state_next <= moving_up;
                            direction <= '1';
                        ELSIF (REQUIRED < CurrentFloor) THEN
                            state_next <= moving_down;
                            direction <= '0';
                        ELSE
                            state_next <= idle;
                        END IF;
                    END IF;
                    -- ##########################################
                WHEN moving_up =>
                    IF (floor_timer = delay) THEN
                        CurrentFloor <= CurrentFloor + 1;
                        IF (CurrentFloor + 1 = REQUIRED) THEN
                            state_next <= door_op;
                        ELSE
                            state_next <= moving_up;
                        END IF;
                        floor_timer <= 0;
                    ELSE
                        floor_timer <= floor_timer + 1;
                    END IF;
                WHEN moving_down =>
                    IF (floor_timer = delay) THEN
                        CurrentFloor <= CurrentFloor - 1;
                        IF (CurrentFloor - 1 = REQUIRED) THEN
                            state_next <= door_op;
                        ELSE
                            state_next <= moving_down;
                        END IF;
                        floor_timer <= 0;
                    ELSE
                        floor_timer <= floor_timer + 1;
                    END IF;
                    -- ##########################################
                WHEN door_op =>
                    IF (timer = delay) THEN
                        state_next <= door_close;
                        timer <= 0;
                    ELSE
                        state_next <= door_op;
                        timer <= timer + 1;
                    END IF;
                WHEN door_close =>
                    state_next <= idle;
                    Request(CurrentFloor) <= '0';
            END CASE;
            IF (push = '0') THEN
                Request(to_integer(unsigned(bn))) <= '1';
            END IF;

        END IF;
    END PROCESS;

    mv_up <= '1' WHEN state_reg = moving_up ELSE
        '0';
    mv_dn <= '1' WHEN state_reg = moving_down ELSE
        '0';
    door_open <= '1' WHEN state_reg = door_op ELSE
        '0';

    ssdin <= STD_LOGIC_VECTOR(to_unsigned(CurrentFloor, 4));
    s : ssd PORT MAP(ssdin, floor);
END arch;