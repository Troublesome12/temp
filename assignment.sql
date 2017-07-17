
/***********************************************************/
/*          Author: Sk. Md. Shariful Islam Arafat          */
/*                  Id    : 011132012                      */
/***********************************************************/


SET SERVEROUTPUT ON;

--CHECKS IF THE DEPARTMENT HAS FREE SEAT OR NOT
CREATE OR REPLACE FUNCTION checkChoiceAvailability(choice ALLOCATION.DEPTID%type) RETURN BOOLEAN 
AS
    free DEPT.CAPACITY%TYPE;
BEGIN
    SELECT FREE INTO free FROM ALLOCATION WHERE ALLOCATION.DEPTID = choice;
    IF free > 0 THEN 
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END checkChoiceAvailability;
/

--RETURNS SET OF DEPARTMENT CHOICE FOR A PARTICULAR STUDENT
CREATE OR REPLACE FUNCTION fetchChoice(reg_no TESTMARKS.REGNO%type) RETURN CHOICELIST%ROWTYPE
AS
    choice_list CHOICELIST%ROWTYPE;
BEGIN
    SELECT * INTO choice_list FROM CHOICELIST WHERE CHOICELIST.REGNO = reg_no;
    RETURN choice_list;
END fetchChoice;
/

--INSERT DATA IN SELECTED TABLE AND UPDATE ALLOCATION TABLE FOR A PARTICULAR STUDENT
CREATE OR REPLACE PROCEDURE allocateStudent(reg_no CHOICELIST.REGNO%TYPE, dept_id CHOICELIST.CHOICE1%TYPE, pos NUMBER)
AS 
BEGIN
    INSERT INTO SELECTED VALUES(reg_no, dept_id, pos);
    UPDATE ALLOCATION SET FREE = FREE - 1, ALLOCATED = ALLOCATED + 1 WHERE DEPTID = dept_id;
END allocateStudent;
/

--AT THE VERY BEGINNING FILL ALLOCATION TABLE FROM DEPT TABLE
CREATE OR REPLACE PROCEDURE preAllocation 
AS 
    CURSOR department_list IS SELECT * FROM DEPT;

BEGIN
    FOR department IN department_list LOOP
        INSERT INTO ALLOCATION VALUES(department.DEPTID, department.CAPACITY, 0);
    END LOOP;
END preAllocation;
/

--CHECKS IF THE CHOICES OF A STUDENT IS AVAILABLE OR NOT
--AND BASED ON THAT RESULT EITHER ALLOCATED STUDENT TO THE DESIRED DEPARTMENT
--OR SEND HIM/HER TO THE WAITING LIST
CREATE OR REPLACE PROCEDURE departmentAllocation 
AS 
    CURSOR top_list IS SELECT * FROM TESTMARKS ORDER BY MARKS DESC;
    choice CHOICELIST%ROWTYPE;
    pos NUMBER(3,0) := 1;
BEGIN
    FOR candidate IN top_list LOOP
        choice := fetchChoice(candidate.REGNO);
        IF checkChoiceAvailability(choice.CHOICE1) THEN
            allocateStudent(choice.REGNO, choice.CHOICE1, pos);
        ELSIF checkChoiceAvailability(choice.CHOICE2) THEN
            allocateStudent(choice.REGNO, choice.CHOICE2, pos);    
        ELSIF checkChoiceAvailability(choice.CHOICE3) THEN
            allocateStudent(choice.REGNO, choice.CHOICE3, pos);    
        ELSE
            INSERT INTO WAITING VALUES(choice.REGNO, pos);
        END IF;
        pos := pos + 1;
    END LOOP;
END departmentAllocation;
/

--CALLING THE PROCEDURES
execute preAllocation();
execute departmentAllocation();