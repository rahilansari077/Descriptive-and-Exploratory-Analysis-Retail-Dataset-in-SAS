/*Initializing Project Library to permanently store datasets */
libname project '/folders/myfolders/Project';

/* Importing Online Retail II xls file into SAS */
PROC IMPORT OUT=project.Retail_1 
		DATAFILE='/folders/myfolders/Project/online_retail_II.xlsx' DBMS=xlsx REPLACE;
	SHEET="Year 2009-2010";
	GETNAMES=YES;
RUN;

PROC IMPORT OUT=project.Retail_2 
		DATAFILE='/folders/myfolders/Project/online_retail_II.xlsx' DBMS=xlsx REPLACE;
	SHEET="Year 2010-2011";
	GETNAMES=YES;
RUN;

DATA project.Retail;
	set project.Retail_1 project.Retail_2;
RUN;

PROC PRINT DATA=project.retail (OBS=100);
RUN;

/* Dataset Characteristics*/
PROC CONTENTS DATA=project.Retail;
RUN;

/* Observations:
Categorical Variables: Country, Description, Invoice, StockCode
Numerical Variables: Customer_ID, InvoiceDate, Price, Quantity
*/
* 1. Working on Categorical Variables;

/* Checking Frequencies for Categorical Variables to detect possible errors
with the exception invoice, since invoice number is a unique identifier */
PROC FREQ DATA=project.Retail;
	TABLES Country Description StockCode;
RUN;

/* Checking for Missing Values */
TITLE "Checking Missing Character Values";

PROC FORMAT;
	VALUE $count_missing ' '='missing' other='Nonmissing';
run;

PROC FREQ DATA=Project.retail;
	TABLES _character_ / nocum missing;
	FORMAT _character_  $count_missing.;
run;

/* Observation: Description has missing values
Approach: Finding mode of description for replacing missing values
*/
PROC FREQ DATA=Project.Retail ORDER=freq;
	TABLE Description;
RUN;

/* Observation : WHITE HANGING HEART T-LIGHT HOLDER is the mode for Description Variable
Approach : Replacing Missing values with Mode obtained */
DATA Project.Retail;
	SET project.retail;

	if missing(Description) then
		Description='WHITE HANGING HEART T-LIGHT HOLDER';
RUN;

PROC FREQ DATA=Project.retail;
	TABLES _character_ / nocum missing;
	FORMAT _character_  $count_missing.;
run;

/* Many Character Errors in Description: Values starting with ?, missing etc */
DATA project.Retail_Clean;
	SET project.Retail;
	where Description like '%?%' or Description like '%miss%' or Description like 
		'%Miss%';
RUN;

TITLE 'Listing invalid values';

PROC PRINT DATA=project.Retail_Clean;
RUN;

PROC FREQ DATA=project.retail_clean;
	TABLES Description;
RUN;

/* Observations: Total 188 rows and most of the values in quantity column is negative
Approach: Exclude these values from Dataset
*/
DATA project.Retail;
	SET project.Retail;
	Where Description not like '%?%' and Description not like '%miss%' and 
		Description not like '%Miss%';
RUN;

PROC CONTENTS DATA=Project.Retail;
RUN;

/* Observation: Count of rows decreased from 1067371 to 1067183 (188 invalid values excluded) */
/* Creating Derived Variable:

Using the Country Variable, we propose creating a derived variable called International_Sale.
This will be useful in finding out how the company is doing internationally in terms of sale.

If the products are sold to a domestic customer (UK), the value of International_Sale will be 0
If the products are sold to an international customer, the value of International_Sale will be 1

*/
DATA project.Retail;
	SET project.Retail;

	if Country='United Kingdom' then
		International_Sale='0';
	else
		International_Sale='1';
RUN;

TITLE 'International Sales Flag';

PROC PRINT DATA=project.retail (OBS=200);
RUN;

/* Observation: New Variable International Sales has been created */
/* StockCodes are 5-digit integral numbers uniquely assigned to each distinct product.
We observed that there are values in StockCode with greater than 5 characters.
Of these those with length 6 have last digit as character and those with length 7 have last 2 digits
as character.
Extracting these can help to know the sub category of product.

We can create a derived variable for the same
*/
DATA project.Retail;
	SET project.Retail;

	if length(StockCode)=7 then
		Stock_Code_Category=substr(StockCode, 6, 2);
	else if length(StockCode)=6 then
		Stock_Code_Category=substr(StockCode, 6, 1);
	else
		Stock_Code_Category='0';
RUN;

TITLE 'Listing of Stock Code Category';

PROC PRINT DATA=project.Retail (obs=100);
RUN;

PROC FREQ DATA=project.Retail;
	TABLES Stock_Code_Category;
RUN;

/* Changing Character values to UpperCase for Stock_Code_Category */
data Project.Retail;
	set Project.Retail;
	array Chars[*] _character_;

	do i=1 to dim(Chars);
		Chars[i]=upcase(Chars[i]);
	end;
	drop i;
run;

PROC FREQ DATA=project.Retail;
	TABLES Stock_Code_Category;
RUN;

* 2. Working on Numerical Variables;

/* Generating Summary Statistics */
TITLE 'Summary Statistics for Numerical Variables';

PROC MEANS DATA=project.retail n nmiss min max mean maxdec=3;
RUN;

/* Observations: Quantity and Price have Negative Values. Ideally, Price and Quantity should be > 0.
Customer ID has missing values. This case is quite possible, if the customer did not want to enroll for
the retailers loyalty program and just wanted to make a single one time purchase.
There is no need to perform imputations to replace missing values in this case,
since it is only an identifier and just replace it with no of observations.

Approach:
Using PROC Univariate to examine Prices and Quantity Variables
Analysing price and quantity variable for errors and outliers.

*/
ods trace on;
title "Running PROC UNIVARIATE on Price and Quantity";
ODS Select ExtremeObs Quantiles Histogram;

proc univariate data=Project.Retail nextrobs=10;
	id invoice;
	var Price Quantity;
	histogram / normal;
run;

ods trace off;

/*Because the histogram does not show accurate distribution due to outliers, we will detect outliers and
then try to build a distribution for majority of dataset. */
proc means data=Project.Retail;
	var price;
	output out=Mean_Std(drop=_type_ _freq_) mean=std= /autoname;
run;

/*Mean of price is 4.6427 and Std Dev is 123.5417. So using it to remove outliers*/
title "Removing outliers in price";

data Project.Retail;
	set Project.Retail;

	if  (price gt 4.6427 - 2*123.5417) and  (price lt 4.6427 + 2*123.5417) and not 
		missing (price);
run;

proc contents data=project.retail;
run;

/*The Project.Retail data set consists of rows where price values are without any outliers.
Number of rows changed from 1067183 to 1066264.

Outliers in price are being removed because there are only about 919 outliers in the column,
however, their values range from -242.4 to -53594 (negative side) and 251.72 to 38970.0 (positive side)
and surprisingly they don't even represent the full 2% of price data. Additionally, price of a product
can never be negative anyway, so it also represents an error in the data record.
Therefore, we remove the error and outliers because any calculation including these outliers will result in
wrong means, std and distribution.
*/
*Statistical Desription of price;

proc means data=project.retail;
	var price;
run;

/*Now the price mean, std dev and median values seem coherent with majority of dataset.*/
/*Plotting real distribution of price*/
proc sgplot data=Project.Retail;
	histogram price /;
	yaxis grid;
run;

/*Distribution of price variable is positively skewed.*/

/*Creating QQ norm plot for price using histogram*/
title 'Normal Quantile-Quantile Plot for Price';
ods graphics on;

proc univariate data=Project.Retail noprint;
	qqplot price / normal(mu=est sigma=est) odstitle=title square;
run;

/*
On Analysing the QQ plot the distribution is not normally distribued at all.
The lower half of the prices are slightly parallel to the reference line, however, the upper half
of price values drastically deviate and go further away from the reference line.
This indicates that price values are heavily positively skewed.

*/
/*Adding another column to Retail dataset named price_log that consists of log transformation
of price variable. */
title "Adding price_log column";

data Project.Retail;
	set Project.Retail;

	if price NE 0 then
		price_log=log(price);
	else
		price_log=0;
run;

/*Now creating a histogram and QQ plot for the price_log variabe to check its normality.*/
proc sgplot data=Project.Retail;
	histogram price_log /;
	yaxis grid;
run;

title 'Normal Quantile-Quantile Plot for Price_log';
ods graphics on;

proc univariate data=Project.Retail noprint;
	qqplot price_log / normal(mu=est sigma=est) odstitle=title square;
run;

/*
The QQ plot has been of price log seems to have a normal distribution.
Even the histogram provides the same result. Log transfomation converted the the positively skewed
price to the normally distributed price_log.
*/
/* Checking for Missing values for Customer id
*/
PROC FREQ DATA=Project.Retail;
	TABLE customer_id / missing;
RUN;

proc sgplot data=Project.Retail;
	histogram customer_id /;
	yaxis grid;
run;

proc print data=project.retail (obs=50);
run;

/*There are about 242260 missing values in customer_id column. SO we cannot remove the records with missing
row id as it can delete valuable data for us.

On seeing the distirbution of the customer id variable it is clear that the id are assigned chronologically.

Two solutions can be applied here
- one solution we can adopt is that assign the missing customer id the value of the previous record's
customer id. But this would pollute the integrity of data as those missing id's orders haven't been placed by that
particular customer.
-Second and more appropriate solution is assigning the Invoice number to the Cutomer ID. Ivoice is a
character column as some of Invoice values have 'C' at the beginning, however most of the invoice
are numeric. So we can assign last 6 digits of invoice to that customer.
This proves to be better solution because one customer can have multiple invoices, however one invoice
can have only one customer. So all the orders of one invoice will go to one customer_id. This will
Maintain uniqueness of customer_id as well as the virtual integrity of data records.
*/
title "Replacing missing customer id with invoice numbers";

data Project.Retail;
	set Project.Retail;

	if missing(customer_id) then
		customer_id=input (substr(invoice, length(invoice)-5, 6), 8.);
run;


proc contents data=project.retail;
run;


proc univariate data=Project.Retail nextrobs=10;
	id invoice;
	var  Quantity;
	histogram / normal;
run;

ods trace off;

/*Because the histogram does not show accurate distribution  of Quantity var due to outliers, we will detect outliers and
remove them then try to build a distribution for majority of dataset. */
proc means data=Project.Retail;
	var quantity;
	output out=Mean_Std(drop=_type_ _freq_) mean=std= /autoname;
run;

/*Mean of quantity is 10.0106587 and Std Dev is 172.2898172. So using it to remove outliers*/
title "Removing outliers in quantity";

data Project.Retail;
	set Project.Retail;

	if  (quantity gt 10.0106 - 2*172.2898) and  (quantity lt 10.0106 + 2*172.2898) and not 
		missing (quantity);
run;

/*After cleaning off the outliers the number of rows is 1064039*/
/*We do not remove the negative quantity values because it is possible that customer have returned that 
product and getting rid of it might make us lose useful data. */

proc contents data=project.retail;
run;




