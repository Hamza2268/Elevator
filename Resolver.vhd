LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY RESOLVER IS
    GENERIC (n : INTEGER := 10);
    PORT (
        CurrentFloor : IN INTEGER;
        Request : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
        Direction : IN STD_LOGIC;
        TargetFloor : OUT INTEGER;
        NextDir : OUT STD_LOGIC
    );
END RESOLVER;

ARCHITECTURE arch OF RESOLVER IS

BEGIN

    PROCESS (CurrentFloor, Request, Direction)
        VARIABLE FOUND : BOOLEAN := false;
    BEGIN
        FOUND := false;
        NextDir <= Direction;
        TargetFloor <= CurrentFloor; -- default value
        IF (Direction = '1' AND NOT(CurrentFloor = n - 1)) THEN
            FOR fl IN 0 TO n - 1 LOOP
                IF (fl >= CurrentFloor + 1) THEN
                    IF (Request(fl) = '1' AND NOT found) THEN
                        TargetFloor <= fl;
                        FOUND := true;
                    END IF;
                    NextDir <= '1';
                END IF;
            END LOOP;
            IF (NOT FOUND) THEN
                FOR fl IN n - 1 DOWNTO 0 LOOP
                    IF (fl <= CurrentFloor - 1) THEN
                        IF (Request(fl) = '1' AND NOT found) THEN
                            TargetFloor <= fl;
                            FOUND := true;
                            NextDir <= '0';
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        ELSIF (Direction = '0' AND NOT(CurrentFloor = 0)) THEN
            FOR fl IN n - 1 DOWNTO 0 LOOP
                IF (fl <= CurrentFloor - 1) THEN
                    IF (Request(fl) = '1' AND NOT found) THEN
                        TargetFloor <= fl;
                        FOUND := true;
                    END IF;
                    NextDir <= '0';
                END IF;
            END LOOP;
            IF (NOT FOUND) THEN
                FOR fl IN 0 TO n - 1 LOOP
                    IF (fl >= CurrentFloor + 1) THEN
                        IF (Request(fl) = '1' AND NOT found) THEN
                            TargetFloor <= fl;
                            FOUND := true;
                            NextDir <= '1';
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END PROCESS;

END arch; -- arch