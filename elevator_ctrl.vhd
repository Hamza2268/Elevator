
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Elevator IS
    PORT (
        clk, rst, push : IN STD_LOGIC;
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
            TargetFloor : OUT INTEGER
        );
    END COMPONENT;

    CONSTANT CLK_FREQ : INTEGER := 25000000; -- 25000000
    CONSTANT DELAY : INTEGER := 2;

    SIGNAL sec_cnt : INTEGER RANGE 0 TO CLK_FREQ - 1;
    SIGNAL clk_en : STD_LOGIC := '0';

    TYPE state IS (idle, moving_up, moving_down, door_op, door_close);
    SIGNAL state_reg, state_next : state;
    SIGNAL timer, door_timer : INTEGER := 0;

    -- SIGNAL up, dn, rdy : STD_LOGIC;

    SIGNAL CurrentFloor, REQUIRED : INTEGER;
    SIGNAL Request : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL DIRECTION : STD_LOGIC;

BEGIN
    P : RESOLVER PORT MAP(CurrentFloor, Request, DIRECTION, REQUIRED);

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

    PROCESS (push)
    BEGIN
        IF rising_edge(push) THEN
            request(to_integer(unsigned(bn))) <= '1';
        END IF;
    END PROCESS;

    PROCESS (clk_en, rst)
    BEGIN
        IF (rst = '1') THEN
            state_reg <= idle;
            -- CurrentFloor <= 0;
            -- REQUIRED <= 0;
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
                    direction <= '1';
                ELSIF (REQUIRED < CurrentFloor) THEN
                    state_next <= moving_down;
                    direction <= '0';
                ELSE
                    state_next <= idle;
                END IF;
                -- ##########################################
            WHEN moving_up =>
                IF (door_timer = delay) THEN
                    CurrentFloor <= CurrentFloor + 1;
                    IF (CurrentFloor + 1 = REQUIRED) THEN
                        state_next <= door_op;
                    ELSE
                        state_next <= moving_up;
                    END IF;
                    door_timer <= 0;
                ELSE
                    door_timer <= door_timer + 1;
                END IF;
            WHEN moving_down =>
                IF (door_timer = delay) THEN
                    CurrentFloor <= CurrentFloor - 1;
                    IF (CurrentFloor - 1 = REQUIRED) THEN
                        state_next <= door_op;
                    ELSE
                        state_next <= moving_down;
                    END IF;
                    door_timer <= 0;
                ELSE
                    door_timer <= door_timer + 1;
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

        END CASE;
    END PROCESS;

    mv_up <= '1' WHEN state_reg = moving_up ELSE
        '0';
    mv_dn <= '1' WHEN state_reg = moving_down ELSE
        '0';
    door_open <= '1' WHEN state_reg = door_op ELSE
        '0';

    floor <= STD_LOGIC_VECTOR(to_unsigned(CurrentFloor, 4));
    -- ssd port map(floor,quartsconnections);
END arch;