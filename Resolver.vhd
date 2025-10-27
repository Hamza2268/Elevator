LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY RESOLVER IS
    PORT (
        CurrentFloor : IN INTEGER;
        Request : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        Direction : IN STD_LOGIC;
        TargetFloor : OUT INTEGER;
    );
END RESOLVER;

ARCHITECTURE arch OF RESOLVER IS
    -- SIGNAL UP_Request, DOWN_Request : INTEGER(9 DOWNTO 0);
    -- SIGNAL lp : INTEGER := 9;
    -- SIGNAL tgt : INTEGER := CurrentFloor;
    SIGNAL FOUND : BOOLEAN := false
BEGIN
    IF (Direction = '1' AND NOT(CurrentFloor = 9)) THEN
        FOR fl IN CurrentFloor + 1 TO 9 LOOP
            IF (Request(fl) = '1' AND NOT found) THEN
                TargetFloor <= fl;
                FOUND <= true;
            END IF;
        END LOOP;
        IF (NOT FOUND) THEN
            Direction <= '0';
            FOR fl IN CurrentFloor +- 1 DOWNTO 0 LOOP
                IF (Request(fl) = '1' AND NOT found) THEN
                    TargetFloor <= fl;
                    FOUND <= true;
                END IF;
            END LOOP;
        END IF;
    ELSIF (Direction = '0' AND NOT(CurrentFloor = 0)) THEN
        FOR fl IN CurrentFloor +- 1 DOWNTO 0 LOOP
            IF (Request(fl) = '1' AND NOT found) THEN
                TargetFloor <= fl;
                FOUND <= true;
            END IF;
        END LOOP;
        IF (NOT FOUND) THEN
            Direction <= '1';
            FOR fl IN CurrentFloor + 1 TO 9 LOOP
                IF (Request(fl) = '1' AND NOT found) THEN
                    TargetFloor <= fl;
                    FOUND <= true;
                END IF;
            END LOOP;
        END IF;
    END IF;

END arch; -- arch