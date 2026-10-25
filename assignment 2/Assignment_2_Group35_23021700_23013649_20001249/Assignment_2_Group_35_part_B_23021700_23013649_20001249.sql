/*---------------------------------------------PART B-------------------------------------------------*/   
   
SET SERVEROUTPUT ON                         --Needed to view cursor outpur

/*----------------------------------------------------------------------------------------------------*/   
/*Question 2a) SThink of some useful business rule or situation (based on the provided database) 
where it would be appropriate for your trigger to fire
*/
--------------------------------------------------------------------------------
/*ALTER TABLE CODE FOR TRIGGER*/
ALTER TABLE BOOKORDER
ADD BO_COST NUMBER(7,2) 
DEFAULT 0
;

ALTER TABLE BOOKORDER
ADD BO_DISCOUNT NUMBER(1) 
DEFAULT 0
;

ALTER TABLE BOOKORDER
ADD CONSTRAINT DISCOUNT_FLAG CHECK (bo_discount IN (0, 1))
;

ALTER TABLE BOOK
ADD BOOK_STOCK NUMBER(4)
DEFAULT 50
;

ALTER TABLE BOOK
ADD BOOK_STOCK_MIN NUMBER(2)
DEFAULT 15
;

ALTER TABLE BOOK
ADD BOOK_REORDER NUMBER(1)
DEFAULT 0
;

ALTER TABLE BOOK
ADD CONSTRAINT REORDER_FLAG CHECK (book_reorder IN (0, 1))
;

------------------------------------------------------------------------------
/*TRIGGER CODE*/
CREATE OR REPLACE TRIGGER total_order_trg_2
AFTER INSERT ON BOOKORDERITEM

FOR EACH ROW

DECLARE 
    total NUMBER(7,2) := 0;
    ordernum NUMBER(4);
    qty NUMBER(2) := 0;
    stockredux NUMBER(2) :=0;
    stockmin NUMBER(2) :=0;
    stock_level_error EXCEPTION;
    discount NUMBER(1) :=0;

BEGIN

    --1)get bo_order
    SELECT bo_ordernum INTO ordernum
    FROM BOOKORDER
    WHERE BOOKORDER.bo_ordernum = :new.bo_ordernum;
    
    --2) update bookorder total cost
    SELECT 
        :new.boi_qty * book_retail INTO total
    FROM BOOK 
    WHERE book_isbn = :new.book_isbn;
      
    --3) update bookorder cost
    UPDATE BOOKORDER
    SET BOOKORDER.bo_cost = BOOKORDER.bo_cost + total
    WHERE BOOKORDER.bo_ordernum = :new.bo_ordernum;
    
     
    --4) reduce book stock
    qty := :new.boi_qty;
    
    SELECT
        BOOK.book_stock_min INTO stockmin
    FROM BOOK
    WHERE BOOK.book_isbn = :new.book_isbn;
    
    SELECT
        BOOK.book_stock - qty INTO stockredux 
    FROM BOOK
    WHERE BOOK.book_isbn = :new.book_isbn;
        
    UPDATE BOOK
    SET BOOK.book_stock = BOOK.book_stock - qty
    WHERE BOOK.book_isbn = :new.book_isbn;
    
    /*--DEBUG code
    DBMS_OUTPUT.PUT_LINE(ordernum);
    DBMS_OUTPUT.PUT_LINE(qty);
    DBMS_OUTPUT.PUT_LINE(stockredux);
    DBMS_OUTPUT.PUT_LINE(total);
    */
    
    --5) check stock level
    IF stockredux < 0 
    THEN
        DBMS_OUTPUT.PUT_LINE ('NOT ENOUGH STOCK');
        RAISE stock_level_error;
        
        ELSE IF stockredux < stockmin
        THEN 
            DBMS_OUTPUT.PUT_LINE ('reorder ticket raised');
            UPDATE BOOK
            SET BOOK.book_reorder = 1
            WHERE BOOK.book_isbn = :new.book_isbn;
        END IF;
    END IF;
    
    --6) Check and apply 10% discount to order over $200
    SELECT
        bo_cost INTO total
    FROM BOOKORDER
    WHERE BOOKORDER.bo_ordernum = :new.bo_ordernum;
    
    SELECT
        BO_discount INTO discount
     FROM BOOKORDER
    WHERE BOOKORDER.bo_ordernum = :new.bo_ordernum;   
    
    IF total > 200 AND discount = 0
    THEN total := total * 0.9;
        UPDATE BOOKORDER
        SET BOOKORDER.bo_cost = total,
            BOOKORDER.bo_discount = 1
        WHERE BOOKORDER.bo_ordernum = :new.bo_ordernum;
        DBMS_OUTPUT.PUT_LINE('Discount Applied, purchase reduced to');
        DBMS_OUTPUT.PUT_LINE(total);
        
        ELSE IF total > 200 AND discount = 1
        THEN
            UPDATE BOOKORDER
            SET BOOKORDER.bo_cost = total
            WHERE BOOKORDER.bo_ordernum = :new.bo_ordernum;
        END IF;
    END IF;    

EXCEPTION
    WHEN stock_level_error
    THEN raise_application_error(-20002, 'Not Enough Stock for sale');

END;
/
--------------------------------------------------------------------------------
/* TEST CODE */
INSERT INTO  BOOKORDERITEM
VALUES (9999, 1, '0000000001', 5); --now have 45 stock, not discounted

INSERT INTO  BOOKORDERITEM
VALUES (9999, 2, '0000000001', 15); -- now have 30 stock, discounted

INSERT INTO  BOOKORDERITEM
VALUES (9999, 3, '0000000001', 10); -- now have 20 stock, not discounted

INSERT INTO  BOOKORDERITEM
VALUES (9999, 4, '0000000001', 10); --trigger reorder, now have 10 stock, not discounted

INSERT INTO  BOOKORDERITEM
VALUES (9999, 5, '0000000001', 10); --now have 0 stock, not discounted

INSERT INTO  BOOKORDERITEM
VALUES (9999, 6, '0000000001', 10); --trigger out of stock exception

INSERT INTO  BOOKORDERITEM
VALUES (9999, 7, '0401140733', 5); --add another book to the order, no discount

INSERT INTO  BOOKORDERITEM
VALUES (1000, 9, '3437212490', 2); -- order with no discount, stock reduced to 48

INSERT INTO  BOOKORDERITEM
VALUES (1000, 10, '3437212490', 50); -- stock would go below 0, trigger out of stock exception


/*----------------------------------------------------------------------------------------------------*/ 
/*Question 2b) rite a trigger that does not allow the book retail price to be updated when the
increase (in retail price) is over 25%. Provide test data and corresponding results to
confirm that the trigger works. */

--retail control --
--Code: 
CREATE TRIGGER retail_control AFTER UPDATE OF book_retail
ON BOOK
FOR EACH ROW 

DECLARE
    retail_control_error EXCEPTION;

BEGIN
    IF :new.book_retail/:old.book_retail > 1.25
    THEN DBMS_OUTPUT.PUT_LINE ('Cannot raise retail price by more than 25%');
    RAISE retail_control_error;
    END IF;
    
EXCEPTION
    WHEN retail_control_error
    THEN raise_application_error(-20001, 'Cannot update');
END;    
/

--Test:
--go high
UPDATE BOOK
    SET book_retail = 400
WHERE book_isbn = 8117949391
;

--legal change
UPDATE BOOK
    SET book_retail = 10
WHERE book_isbn = 8117949391
;


--Output:

/*----------------------------------------------------------------------------------------------------*/ 
/*Question 2c) Write a trigger that does not allow more than three author names to be associated
with books under FITNESS category (e.g., if a Book is added, it should only allow
up to 3 book authors to be recorded in BookAuthor table for �fitness� category
books). Provide the appropriate test data and results. */

--Code:
CREATE OR REPLACE TRIGGER trg_fitness_author_control
FOR INSERT ON BOOKAUTHOR
COMPOUND TRIGGER
  TYPE type_isbns  IS TABLE OF BOOK.book_isbn%TYPE;
  v_isbns          type_isbns := type_isbns();
  v_book_category  BOOK.book_category%TYPE;
  v_count          INTEGER;

  AFTER EACH ROW IS
  BEGIN
    v_isbns.EXTEND;
    v_isbns(v_isbns.COUNT) := :new.book_isbn;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    FOR i IN 1 .. v_isbns.COUNT LOOP
      SELECT B.book_category, a.cnt
      INTO v_book_category, v_count
      FROM BOOK B
      CROSS APPLY
      (
        SELECT COUNT(*) as cnt 
        FROM BOOKAUTHOR BA
        WHERE BA.book_isbn = B.book_isbn
      ) A
      WHERE B.book_isbn = v_isbns(i);

      IF v_book_category = 'FITNESS' AND v_count > 3 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Too many authors for fitness book ' || v_isbns(i));
      END IF;
    END LOOP;
  END AFTER STATEMENT;
END trg_fitness_author_control;
/

--Test code:
--inserting test data into book, author and book author

INSERT INTO BOOK VALUES ('9000000099', 'FITEST', '21-FEB-23', 01, 10.00, 20.95, 'FITNESS', 1, 20.95);
    
INSERT INTO AUTHOR VALUES ('M200', 'Mycenae', 'Agamemnon');
INSERT INTO AUTHOR VALUES ('I200', 'Ithica', 'Odysseus');
INSERT INTO AUTHOR VALUES ('D200', 'Dardania', 'Aeneas');

INSERT INTO BOOKAUTHOR VALUES ('9000000099', 'M200');
INSERT INTO BOOKAUTHOR VALUES ('9000000099', 'I200');
INSERT INTO BOOKAUTHOR VALUES ('9000000099', 'D200');

--test by adding one more author to a fitness book with 3 already
INSERT INTO BOOKAUTHOR VALUES ('9000000099', 'P105');


--Output:

/*----------------------------------------------------------------------------------------------------*/ 
/*Question 2d) d. Write a procedure to insert a new book record. The procedure should also
automatically calculate the book retail value. This retail is calculated as 110.5%
of the book cost price plus 4.5% of the average cost price of the existing books in
the database. Provide rest of the attributes� values as input parameters. Execute
your procedure to insert at least one book record. */

--Code:

CREATE OR REPLACE PROCEDURE PRC_INSERT_NEW_BOOK_RECORD(
    p_Book_ISBN IN BOOK.Book_ISBN%TYPE,
    p_Book_Title IN BOOK.Book_Title%TYPE,
    p_Book_PubDate IN BOOK.Book_PubDate%TYPE,
    p_Pub_ID IN BOOK.Pub_ID%TYPE,
    p_Book_Cost IN BOOK.Book_Cost%TYPE,
    p_Book_Category IN BOOK.Book_Category%TYPE,
    p_Author_ID IN AUTHOR.Author_id%TYPE,
    p_Author_LName IN AUTHOR.Author_LName%TYPE,
    p_Author_FName IN AUTHOR.Author_FName%TYPE
    )
    
IS
    v_Avg_Cost BOOK.Book_Cost%TYPE;
    v_Book_Retail BOOK.Book_Retail%TYPE;
BEGIN
    SELECT AVG(Book_Cost) INTO v_Avg_Cost FROM BOOK;
    v_Book_Retail := ((1.105 * p_Book_Cost) + (0.045 * v_Avg_Cost));

    INSERT INTO BOOK ( Book_ISBN, Book_Title, Book_PubDate, Pub_ID, Book_Cost, Book_Retail, Book_Category)
    VALUES ( p_Book_ISBN, p_Book_Title, p_Book_PubDate, p_Pub_ID, p_Book_Cost, v_Book_Retail, p_Book_Category);
    INSERT INTO AUTHOR (Author_id, Author_Lname, Author_Fname)
    VALUES (p_Author_ID, p_Author_LName, p_Author_FName); 
    INSERT INTO BOOKAUTHOR (Book_isbn, Author_id)
    VALUES (p_Book_ISBN, p_Author_ID);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('New book record inserted successfully.');

END;
/

-- Test insert of book record
EXECUTE PRC_INSERT_NEW_BOOK_RECORD('0000000001', 'THE BROTHERS KARAMAZOV','09/10/23', 1, 20.00, 'FICTION','Z999', 'Fyodor', 'Dostoy');


--Output:


/*----------------------------------------------------------------------------------------------------*/   
/*Question 2e) Use a cursor construct to list book authors for the �computer� category books (along
with their book title, cost, and retail). Present your work in a well readable report
format (e.g., include headings, well-spaced expressions, some summary in the end) */

--Code:
DECLARE CURSOR computer_books_cursor IS

SELECT  
    B.Book_title,
    B.Book_cost,
    B.Book_retail,
    LISTAGG( A.Author_Fname || ' ' || A.Author_LName, ', ') AS Author_Name
FROM BOOK B
JOIN BOOKAUTHOR BA ON B.Book_isbn = BA.book_isbn 
JOIN AUTHOR A ON BA.Author_id = A.author_id
WHERE B.Book_Category = 'COMPUTER'
GROUP BY B.Book_title, B.Book_cost, B.Book_retail, B.book_category;

book_info computer_books_cursor%ROWTYPE;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('-------------------------------------START OF REPORT---------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Book Title               |Book Cost |Book Retail|Author Name                              |');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------');

OPEN computer_books_cursor;
LOOP
    FETCH computer_books_cursor INTO book_info;
    IF computer_books_cursor%FOUND THEN
        DBMS_OUTPUT.PUT_LINE(RPAD(book_info.Book_Title, 24) || ' | ' || 
                        TO_CHAR(book_info.Book_Cost, 9999.99) || ' | ' || 
                        TO_CHAR(book_info.Book_Retail, 9999.99) || ' | ' || 
                        RPAD(book_info.Author_Name, 40)  || ' | ' );                
    ELSE
        EXIT;
    END IF;
   
END LOOP;
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total number of rows    ' || computer_books_cursor%ROWCOUNT);
    DBMS_OUTPUT.PUT_LINE('---------------------------------------END OF REPORT---------------------------------------');
IF computer_books_cursor%ISOPEN THEN
    CLOSE computer_books_cursor;
END IF;

END;
/

--Output:


/*----------------------------------------------------------------------------------------------------*/   
/*Question 2f) Write a function to appropriately format money values (e.g., columns such as book
cost, retail price uses a currency sign, commas if needed) when presented in some
listing.
Call this function in a SQL statement for displaying books� costs and retail prices */

--Code:
CREATE OR REPLACE FUNCTION FUNC_MONEY_FORMAT(v_amount NUMBER)
RETURN VARCHAR2 IS
v_formatted_amount VARCHAR2(100);
BEGIN
  v_formatted_amount := TO_CHAR(v_amount, '$999,999,999.99');
RETURN v_formatted_amount;

 DBMS_OUTPUT.PUT_LINE(FUNC_MONEY_FORMAT(1000000));
END;
/

--Test Code
SELECT 
    Book_Title AS "Book Title",
    FUNC_MONEY_FORMAT(Book_Cost) AS "Book Cost",
    FUNC_MONEY_FORMAT(Book_Retail) AS "Book Retail"
FROM
    Book
;
    
--Output:


/*----------------------------------------------------------------------------------------------------*/   
