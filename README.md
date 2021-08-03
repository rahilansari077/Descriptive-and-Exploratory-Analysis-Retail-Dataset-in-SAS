# Descriptive-and-Exploratory-Analysis-Retail-Dataset-in-SAS

DATA PREPARATION AND HANDLING FINAL PROJECT

Group Members: 
•	Rahil Wajidali Ansari 
•	Arvind Neelakantan 
•	Parth Manish Shah

Dataset selected: Online Retail II Dataset.
Link: https://archive.ics.uci.edu/ml/datasets/Online+Retail+II#
Dataset Description:
The dataset contains real online retail transaction data set of a UK-based, registered, non-store online retail.
 
Attribute Information:

Variable Name	Description

InvoiceNo - Invoice number. Nominal. A 6-digit integral number uniquely assigned to each transaction. If this code starts with the letter 'c', it indicates a cancellation.
StockCode - Product (item) code. Nominal. A 5-digit integral number uniquely assigned to each distinct product.
Description - Product (item) name. Nominal.
Quantity - The quantities of each product (item) per transaction. Numeric.
InvoiceDate - Invoice date and time. Numeric. The day and time when a transaction was generated.
UnitPrice - Unit price. Numeric. Product price per unit in sterling (£).
CustomerID - Customer number. Nominal. A 5-digit integral number uniquely assigned to each customer.
Country - Country name. Nominal. The name of the country where a customer resides.


Preliminary Observations of the Dataset:
1.	Missing values:
•	Country – represented as ‘Unspecified’.
•	CustomerID – represented as blank.
•	Description – represented as blank.

2.	Outliers:
•	Price – Negative values
•	Quantity – Negative values
3.	Errors in categorical variables:
•	 Invoice – Supposed to be a numerical column,  but it contains non-numerical data for cancelled invoices (starts with the letter c). We could convert it to numerical and create a new sub category flag for cancelled invoices.
•	StockCode – Supposed to be a numerical column,  but it contains non-numerical data like ‘POST’ , ‘GIFT’ , ‘TEST001’ etc. 


The SAS project aims at performing following tasks:
1. Check and correct errors when necessary
2. Check for missing values Treat missing values  
3. Creating derived variables or combined values of a categorical variable. 
4. Detect and remove outliers
5. Test for normality and transformation of distribution


