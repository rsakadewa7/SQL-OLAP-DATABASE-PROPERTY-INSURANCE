-- Membuat Data Warehouse Sales 
USE MASTER
GO
CREATE DATABASE Sales

USE Sales
GO

-- Create Dimension Table Claim [V]
CREATE TABLE DimClaim (
	claim_id NVARCHAR(50) PRIMARY KEY,
	claimant_name NVARCHAR(150),
	claim_status NVARCHAR(10),
	currency NVARCHAR(3),
	paid_amount NUMERIC(20,2),
	reserve_amount NUMERIC(20,2)
)
GO

-- Create Dimension Table Claim_View with Composite Key [V]
CREATE TABLE DimClaim_View (
	claim_view_id NVARCHAR(50) PRIMARY KEY,
	claim_date DATETIME,
	claim_day INT,
	claim_month INT,
	claim_year INT
)
GO

-- Create Dimension Table Block [V]
CREATE TABLE DimBlock (
	block_id NVARCHAR(50) PRIMARY KEY,
	block_name NVARCHAR(150),
	postal_code INT,
	building_name NVARCHAR(150),
	street_name NVARCHAR(150)
)
GO

-- CREATE TABLE DimOccupation [V]
CREATE TABLE DimOccupation (
	occupation_id NVARCHAR(50) PRIMARY KEY,
	occupation_name NVARCHAR(1000)
)
GO

-- Create Dimension Table Acceptance_View with Composite Key [V]
CREATE TABLE DimAcceptance_View (
	acceptance_view_id NVARCHAR(50) PRIMARY KEY,
	acceptance_date DATETIME,
	acceptance_day INT,
	acceptance_month INT,
	acceptance_year INT
)
GO

-- Create Dimension Table Release_View with Composite Key [V]
CREATE TABLE DimRelease_View (
	release_view_id NVARCHAR(50) PRIMARY KEY,
	release_date DATETIME,
	release_day INT,
	release_month INT,
	release_year INT
)
GO

-- Create Dimension Table Product [V]
CREATE TABLE DimProduct (
	product_id NVARCHAR(5) PRIMARY KEY,
	product_name NVARCHAR(150)
)
GO

-- Create Dimension Table Policy [V]
CREATE TABLE DimPolicy (
	policy_id NVARCHAR(50) PRIMARY KEY,
	quotation_id NVARCHAR(50),
	insured NVARCHAR(250),
	account_id NVARCHAR(50),
	currency NVARCHAR(3),
	insured_amount NUMERIC(20,2),
	premium_due NUMERIC(20,2),
	renewal NVARCHAR(50)
)
GO

-- Create Dimension Table  Commencement_View with Composite Key [V]
CREATE TABLE DimCommencement_View (
	commencement_view_id NVARCHAR(50) PRIMARY KEY,
	commencement_date DATETIME,
	commencement_day INT,
	commencement_month INT,
	commencement_year INT
)
GO

-- Create Dimension Table  Location [V]
CREATE TABLE DimLocation (
	city_id NVARCHAR(4) PRIMARY KEY,
	city_name NVARCHAR(50),
	latitude DECIMAL(8,6),
	longitude DECIMAL(9,6)
)
GO

-- Create Dimension Table Expiry_View with Composite Key [V]
CREATE TABLE DimExpiry_View (
	expiry_view_id NVARCHAR(50) PRIMARY KEY,
	expiry_date DATETIME,
	expiry_day INT,
	expiry_month INT,
	expiry_year INT
)
GO

-- Create Fact Table Sales
CREATE TABLE FactSales (
	policy_id NVARCHAR(50) NOT NULL,
	product_id NVARCHAR(5) NOT NULL,
	commencement_view_id NVARCHAR(50) NOT NULL,
	acceptance_view_id NVARCHAR(50) NOT NULL,
	release_view_id NVARCHAR(50) NOT NULL,
	expiry_view_id NVARCHAR(50) NOT NULL,
	occupation_id NVARCHAR(50) NULL,
	city_id NVARCHAR(4) NULL,
	block_id NVARCHAR(50) NULL,
	claim_id NVARCHAR(50) NULL,
	claim_view_id NVARCHAR(50) NULL,

	FOREIGN KEY (policy_id) REFERENCES DimPolicy(policy_id),
	FOREIGN KEY (product_id) REFERENCES DimProduct(product_id),
	FOREIGN KEY (commencement_view_id) REFERENCES DimCommencement_View(commencement_view_id),
	FOREIGN KEY (acceptance_view_id) REFERENCES DimAcceptance_View(acceptance_view_id),
	FOREIGN KEY (release_view_id) REFERENCES DimRelease_View(release_view_id),
	FOREIGN KEY (expiry_view_id) REFERENCES DimExpiry_View(expiry_view_id),
	FOREIGN KEY (occupation_id) REFERENCES DimOccupation(occupation_id),
	FOREIGN KEY (city_id) REFERENCES DimLocation(city_id),
	FOREIGN KEY (block_id) REFERENCES DimBlock(block_id),
	FOREIGN KEY (claim_id) REFERENCES DimClaim(claim_id),
	FOREIGN KEY (claim_view_id) REFERENCES DimClaim_View(claim_view_id)

);
GO

--Calculation in Fact Table
ALTER TABLE FactSales ADD total_insured INT;
ALTER TABLE FactSales ADD total_claim INT;
ALTER TABLE FactSales ADD total_policies_per_month INT;
--
ALTER TABLE DimPolicy ADD max_insured_per_currency NUMERIC(20,2);
ALTER TABLE DimPolicy ADD max_premium_per_currency NUMERIC(20,2);
ALTER TABLE DimClaim ADD max_claim_per_currency NUMERIC(20,2);

--total insured [V]
UPDATE FactSales SET total_insured = (SELECT COUNT(DISTINCT policy_id) FROM DimPolicy)

--total claim [V]
UPDATE FactSales SET total_claim = (SELECT COUNT(DISTINCT claim_id) FROM DimClaim)

--max insured by currency
UPDATE DimPolicy SET max_insured_per_currency = (SELECT MAX(B.insured_amount) FROM DimPolicy B GROUP BY B.currency) WHERE currency = currency

--max premium by currency
UPDATE DimPolicy SET max_premium_per_currency = (SELECT MAX(premium_due) FROM DimPolicy GROUP BY currency)

--max claim by currency
UPDATE DimClaim SET max_claim_per_currency = (SELECT MAX(paid_amount + reserve_amount) FROM DimClaim GROUP BY currency)


ALTER TABLE FactSales DROP COLUMN total_claim;

SELECT  AS max_insured, currency
FROM DimPolicy
JOIN 
WHERE FactSales.
GROUP BY currency

--max premium by currency
INSERT INTO FactSales(max_insured)
SELECT MAX(premium_due) AS max_insured
FROM DimPolicy;
GROUP BY currency

Select * FROM FactSales

--create table max_insured_per_currency [V]
SELECT DimPolicy.currency, MAX(DimPolicy.insured_amount) AS max_insured 
INTO max_insured_per_currency
FROM DimPolicy GROUP BY DimPolicy.currency

--create table sum_insured_per_currency [V]
SELECT DimPolicy.currency, SUM(DimPolicy.insured_amount) AS sum_insured
INTO sum_insured_per_currency 
FROM DimPolicy GROUP BY DimPolicy.currency

--create table max_premium_per_currency [V]
SELECT DimPolicy.currency, MAX(DimPolicy.premium_due) AS max_premium 
INTO max_premium_per_currency
FROM DimPolicy GROUP BY DimPolicy.currency

--create table sum_premium_per_currency [V]
SELECT DimPolicy.currency, SUM(DimPolicy.premium_due) AS sum_premium 
INTO sum_premium_per_currency
FROM DimPolicy GROUP BY DimPolicy.currency

--create table total_policies_per_product [V]
SELECT FactSales.product_id, COUNT(DISTINCT FactSales.policy_id) AS total_policies
INTO total_policies_per_product
FROM FactSales GROUP BY FactSales.product_id

--create table total_claims_per_product [V]
SELECT FactSales.product_id, COUNT(DISTINCT FactSales.claim_id) AS total_claims
INTO total_claims_per_product
FROM FactSales GROUP BY FactSales.product_id




