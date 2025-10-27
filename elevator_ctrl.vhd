
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Elevator IS
    PORT (
        clk, rst : IN STD_LOGIC;
        bn : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        mv_up, mv_dn, door_open : OUT STD_LOGIC;
        floor : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
END Elevator;

ARCHITECTURE arch OF Elevator IS

    -- COMPONENT RESOLVER

    COMPONENT RESOLVER IS
        PORT (
            CurrentFloor : IN INTEGER;
            Request : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            Direction : IN STD_LOGIC;
            TargetFloor : OUT INTEGER;
        );
    END COMPONENT;

    CONSTANT CLK_FREQ : INTEGER := 25000000; -- 25000000
    CONSTANT DELAY : INTEGER := 2;

    SIGNAL sec_cnt : INTEGER RANGE 0 TO CLK_FREQ - 1;
    SIGNAL clk_en : STD_LOGIC := '0';

    TYPE state IS (idle, moving_up, moving_down, door_op, door_close);
    SIGNAL state_reg, state_next : state;
    SIGNAL timer : INTEGER := 0;

    -- SIGNAL up, dn, rdy : STD_LOGIC;

    SIGNAL CurrentFloor, REQUIRED : INTEGER;
    SIGNAL Request : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL DIRECTION : STD_LOGIC;

BEGIN

    -- PORT MAP (REQUIRED)
    P : RESOLVER PORT MAP(CurrentFloor, REQUIRED, DIRECTION, Request)

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
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

    PROCESS (clk_en, rst)
    BEGIN
        IF (rst = '1') THEN
            state_reg <= idle;
            CurrentFloor <= 0;
            REQUIRED <= 0;
            Request <= (OTHERS => '0');
        ELSIF rising_edge(clk_en) THEN
            state_reg <= state_next;
        END IF;
    END PROCESS;

    PROCESS (state_reg)
    BEGIN
        CASE state_reg IS
            WHEN idle =>
                IF (REQUIRED > CurrentFloor) THEN
                    state_next <= moving_up;
                    Request <= '1';
                ELSIF (REQUIRED < CurrentFloor)
                    state_next <= moving_down;
                    Request <= '0';
                ELSE
                    state_next <= idle;
                END IF;
                -- ##########################################
            WHEN moving_up =>
                CurrentFloor = CurrentFloor + 1;
                IF (CurrentFloor = REQUIRTED) THEN
                    state_next <= door_op;
                ELSE
                    state_next <= moving_up;
                END IF;
            WHEN moving_down =>
                CurrentFloor = CurrentFloor - 1;
                IF (CurrentFloor = REQUIRTED) THEN
                    state_next <= door_op;
                ELSE
                    state_next <= moving_down;
                END IF;
                -- ##########################################
            WHEN door_op =>
                IF (timer = DELAY - 1) THEN -- DELAY - 1
                    state_next <= door_op;
                    timer <= timer - 1;
                ELSE
                    state_next <= door_close;
                END IF;
            WHEN door_close =>
                state_next <= idle;
        END CASE;
    END PROCESS;

END arch;