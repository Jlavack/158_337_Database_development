/*---------------------------------------------PART A-------------------------------------------------*/   

/*----------------------------------------------------------------------------------------------------*/   
/*QUESTION 1a) Write a query that lists both customer and author details (only their ids, first and 
last names). Provide suitable headings for the merged list*/

/*Code:*/
SELECT 
    TO_CHAR(Cust_Num) AS "ID" ,
    Cust_FName || ' ' || Cust_LName AS "Full Name"
    FROM CUSTOMER
UNION
SELECT
    Author_ID AS "ID",
    Author_FName || ' ' || Author_LName AS "Full Name"
    FROM AUTHOR
;    
/*Output:*/
 
/*----------------------------------------------------------------------------------------------------*/   
/*QUESTION 1b)Write a query that will list the books with the price difference (between retail and 
cost) of $20 or more. Display your results in the decreasing order of the price
difference */

/*Code:*/
SELECT
    Book_Title AS "Book Title",
    Book_Retail - Book_Cost AS "Price Difference"
    FROM BOOK
WHERE 
    Book_Retail - Book_Cost >= 20
ORDER BY "Price Difference" DESC
;

/*Output:*/

/*----------------------------------------------------------------------------------------------------*/ 
/*Question 1c) Write a query that will list books that have retail price of $35 or less and
were published in any of the years 1999 or 2001. Display the year of publication
values under the column titled as Publication Year. Show the query results in the
increasing order of the publication year and decreasing retail price. */

/*Code:*/
SELECT
    Book_Title AS "Book Title",
    Book_Retail AS "Retail Price",
    Book_Pubdate AS "Publication Year"
FROM BOOK
WHERE (
    Book_Retail <= 35 
    AND (
        TO_CHAR(Book_Pubdate, 'YYYY') = '1999' 
        OR TO_CHAR(Book_Pubdate, 'YYYY') = '2001'
        )
    )
ORDER BY 
    "Publication Year" ASC,
    "Retail Price" DESC
;    

/*Output:*/

/*----------------------------------------------------------------------------------------------------*/ 
/*Question 1d) Write a query that will list publishers (with details such as name) and total
number of books published by them. Include only those publishers that have 2 
or more books published and display your output in the decreasing order of
total number of publications */

/*Code:*/
SELECT 
    PUBLISHER.Pub_Name AS "Publisher Name",
    COUNT(BOOK.Pub_ID) AS "Total Publications" 
FROM BOOK
INNER JOIN 
    Publisher
    ON
    PUBLISHER.Pub_ID = BOOK.Pub_ID
GROUP BY 
    PUBLISHER.Pub_Name
    HAVING COUNT(BOOK.Pub_ID) >1
ORDER BY
    "Total Publications" DESC
;

/*Output:*/

/*----------------------------------------------------------------------------------------------------*/ 
/*Question 1e) Write a query to list books that have multiple authors. Also, display the number of
authors who wrote the book */

/*Code:*/
SELECT
    BOOK.Book_Title AS "Book Title",
    COUNT(BOOKAUTHOR.Book_ISBN) AS "Total Authors" 
FROM BOOKAUTHOR
INNER JOIN
    BOOK
    ON
    BOOK.Book_ISBN = BOOKAUTHOR.Book_ISBN
GROUP BY
    BOOK.Book_Title
    HAVING COUNT(BOOKAUTHOR.Book_ISBN) >1
ORDER BY
    "Total Authors"
DESC
;

/*Output:*/

/*----------------------------------------------------------------------------------------------------*/ 
/*Question 1f) Write a query that will list books from the �computer� category along with other 
details such as author(s), publisher, etc. List the book authors in a single row and 
the query should be able to accommodate all the casing-variations of the category 
values in the database.*/

/*Code:*/

WITH A AS (
    SELECT  
        BOOK.*, --allows any book attribute to be selected
        BOOKAUTHOR.*,
        AUTHOR.Author_Fname || ' ' || Author.Author_LName AS "Author",
        PUBLISHER.Pub_name
    FROM BOOK
    JOIN BOOKAUTHOR ON BOOK.Book_isbn = BOOKAUTHOR.book_isbn 
    JOIN AUTHOR ON BOOKAUTHOR.Author_id = AUTHOR.author_id
    JOIN PUBLISHER ON BOOK.pub_id = PUBLISHER.pub_id
    WHERE Book_Category = 'COMPUTER'
    )

SELECT --specifically select and alias any book table value you want
    Book_title AS "Title", 
    book_category AS "Category" , 
    pub_name AS "Publisher",
    LISTAGG("Author", ', ') AS "Authors"
FROM A
--include all selected book attributes in the group by statement to show them in output
GROUP BY Book_title, book_category, pub_name 
;

This code also works, but is less easily configurable
SELECT  
   B.Book_title,
   P.pub_name,
   LISTAGG( A.Author_Fname || ' ' || A.Author_LName, ', ') AS Author_Name
FROM BOOK B
JOIN BOOKAUTHOR BA ON B.Book_isbn = BA.book_isbn 
JOIN AUTHOR A ON BA.Author_id = A.author_id
JOIN PUBLISHER P ON B.pub_id = P.pub_id
WHERE B.Book_Category = 'COMPUTER'
GROUP BY P.Pub_name, B.Book_title, B.book_category
;

/*Output*/


/*----------------------------------------------------------------------------------------------------*/ 
/*Question 1g)  Write a query that will list the customer who has ordered the greatest number of
items (two copies of the same book will be counted as two items) to date. If there 
is more than one customer, then your query should list all those customers.*/

/*Code:*/
SELECT 
    Customer.Cust_Num AS "Customer Number", 
    Customer.Cust_FName || ' ' || Customer.Cust_LName AS "Customer Name",
    COUNT(BookOrderItem.BO_OrderNum) AS "Total Items Ordered" 
FROM CUSTOMER
INNER JOIN 
    BOOKORDER 
    ON 
    CUSTOMER.Cust_Num = BookOrder.Cust_Num
INNER JOIN 
    BOOKORDERITEM  
    ON 
    BOOKORDER.BO_OrderNum = BOOKORDERITEM.BO_OrderNum
GROUP BY 
    CUSTOMER.Cust_Num, CUSTOMER.Cust_FName, CUSTOMER.Cust_LName
    HAVING COUNT(BOOKORDERITEM.BO_OrderNum) = ( 
        SELECT MAX(ItemCount) 
        FROM (SELECT  
            COUNT(BOOKORDERITEM.BO_OrderNum) AS ItemCount 
            FROM BOOKORDERITEM
GROUP BY BOOKORDERITEM.BO_OrderNum 
        )
    )
;

/*Output:*/

/*----------------------------------------------------------------------------------------------------*/ 
/*Question 1h) Write a query that will display the customer that referred the greatest number of
customers. Again, like g) there can be more than one customer. */

/*Code:*/
SELECT
    C.Cust_referred_by AS "Customer Number",
    CUSTOMER.Cust_FName || ' ' || CUSTOMER.Cust_LName AS "Customer Name",
    COUNT(*) AS "Total Referrals"
FROM CUSTOMER
LEFT JOIN CUSTOMER C ON CUSTOMER.Cust_num = C.Cust_referred_by
GROUP BY C.Cust_referred_by, CUSTOMER.Cust_FName, CUSTOMER.Cust_LName
    HAVING COUNT(*) = (
        SELECT MAX(ReferralCount) 
        FROM (
            SELECT
                COUNT(*) AS ReferralCount 
            FROM CUSTOMER
            WHERE 
                Cust_Referred_by IS NOT NULL
            GROUP BY 
                Cust_Referred_by
        )
    )
;    

/*Output:*/

/*----------------------------------------------------------------------------------------------------*/

