<Query Kind="Statements">
  <Connection>
    <ID>b453d00d-8386-4f2a-aa86-985d6c3e7863</ID>
    <Persist>true</Persist>
    <Driver Assembly="IQDriver" PublicKeyToken="5b59726538a49684">IQDriver.IQDriver</Driver>
    <Provider>Devart.Data.Oracle</Provider>
    <CustomCxString>AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAoPXb9+gsskaOaAECua/csQAAAAACAAAAAAADZgAAwAAAABAAAADBKBUrVWrO2s+NmgYJeyHPAAAAAASAAACgAAAAEAAAADBiDObsNhi3cNSncv36t8JoAAAAdGMxO+UaOxFauUxn+dN8OGo6I/dmUQP00y+lSxzyjHeLqE5hu32E8WoDX3TmqQ62jyMhU7tKjnJdHfV8v8ewyqkjC6AkEfzYwcvHEbIISp9xbO5O/9vahBj98ttCjQSm1vuE3HQJ0UoUAAAAkRvKjSoVQcG+/IbSZRFrzNtIsvA=</CustomCxString>
    <Server>hpc-oracle01.massey.ac.nz</Server>
    <UserName>IT337013</UserName>
    <DisplayName>myLINQConnection</DisplayName>
    <Password>AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAoPXb9+gsskaOaAECua/csQAAAAACAAAAAAADZgAAwAAAABAAAABEPt6fsMf64U/M800kHTckAAAAAASAAACgAAAAEAAAAK/6tLAwdaqBcQabUrS2BH0QAAAAJWLbwVBMMVTbAyBa4JWVnhQAAABCUH+Ls00cjT+UpuQr8WTO9qpUzA==</Password>
    <EncryptCustomCxString>true</EncryptCustomCxString>
    <DriverData>
      <StripUnderscores>true</StripUnderscores>
      <QuietenAllCaps>true</QuietenAllCaps>
      <ConnectAs>Default</ConnectAs>
      <UseOciMode>false</UseOciMode>
      <SID>sncs</SID>
      <Port>1521</Port>
    </DriverData>
  </Connection>
</Query>

//----------------------------PART 2C-------------------------------//
//Question 3a) List books with the retail price $25 or over.

//Code:
var question1 =
	from s in Books
	where s.BookRetail > 25
	select s;
question1.Dump();

//OUTPUT:


//------------------------------------------------------------------//
//Question 3b) List books that have the word “HOW” in the book title.

//Code:
var question2 =
	from s in Books
	where s.BookTitle.Contains("HOW")
	select s;
question2.Dump();

//Output:


//------------------------------------------------------------------//
//Question 3c) List book categories, book titles and publisher names.

//Code:
var question3  =
	from s in Books
	join p in Publishers
		on s.PubID equals p.PubID
	select new {s.BookTitle, s.BookCategory, p.PubName};
question3.Dump();

//Output:


//------------------------------------------------------------------//
//Question 3d) Display total number of books by each publisher in 
//the order of publisher ID

//Code:
var question4 = 
	from b in Books
	join p in Publishers
		on b.PubID equals p.PubID
	group b by b.PubID into newgroup
	orderby newgroup.Key
	select new {
		PublisherID = newgroup.Key,
		TotalBooks = newgroup.Count()
		} into g
	join p in Publishers
		on g.PublisherID equals p.PubID
	select new{
		PublisherID = g.PublisherID,
		Publisher = p.PubName,
		TotalBooks = g.TotalBooks};
question4.Dump();

//Output:

//------------------------------------------------------------------//
//Question 3e) Display the number of books under each category in 
//the order of category

//Code:
var question5 = 
	from b in Books
	group b by b.BookCategory into newgroup
	orderby newgroup.Key
	select new {
		Category = newgroup.Key,
		TotalBooks = newgroup.Count()
		};
question5.Dump();

//Output:

//------------------------------------------------------------------//