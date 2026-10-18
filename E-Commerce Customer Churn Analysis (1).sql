USE ecomm;
/* Handling Missing Values and Outliers: 
➢ Impute mean  for the following columns, and round off to the nearest integer if 
required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear, 
DaySinceLastOrder. */
------------------------------------
-- WarehouseToHome mean imputation--
SET SQL_SAFE_UPDATES = 0;
UPDATE customer_churn
JOIN (
SELECT ROUND(AVG(WarehouseToHome),0) AS mean_val
FROM customer_churn
WHERE WarehouseToHome IS NOT NULL) AS t
SET customer_churn.WarehouseToHome = t.mean_val
WHERE customer_churn.WarehouseToHome IS NULL
AND customer_churn.CustomerID IS NOT NULL;

-- HourSpendOnApp--
UPDATE customer_churn
JOIN (
SELECT ROUND(AVG(HourSpendOnApp),0) AS mean_val
FROM customer_churn
WHERE HourSpendOnApp IS NOT NULL) AS t
SET customer_churn.HourSpendOnApp = t.mean_val
WHERE customer_churn.HourSpendOnApp IS NULL;

-- OrderAmountHikeFromlastYear
UPDATE customer_churn
JOIN (
SELECT ROUND(AVG(OrderAmountHikeFromlastYear),0) AS mean_val
FROM customer_churn
WHERE OrderAmountHikeFromlastYear IS NOT NULL) AS t
SET customer_churn.OrderAmountHikeFromlastYear = t.mean_val
WHERE customer_churn.OrderAmountHikeFromlastYear IS NULL;

-- DaySinceLastOrder
UPDATE customer_churn
JOIN (
SELECT ROUND(AVG(DaySinceLastOrder),0) AS mean_val
FROM customer_churn
WHERE DaySinceLastOrder IS NOT NULL) AS t
SET customer_churn.DaySinceLastOrder = t.mean_val
WHERE customer_churn.DaySinceLastOrder IS NULL;

/* ➢ Impute mode for the following columns: Tenure, CouponUsed, OrderCount.*/
-- Tenure mode imputation ---
UPDATE customer_churn
JOIN (
SELECT Tenure AS mode_val
FROM customer_churn
WHERE Tenure IS NOT NULL
GROUP BY Tenure
ORDER BY COUNT(*) DESC
LIMIT 1) AS t
SET customer_churn.Tenure = t.mode_val
WHERE customer_churn.Tenure IS NULL;

-- CouponUsed mode imputation --
UPDATE customer_churn
JOIN (
SELECT CouponUsed AS mode_val
FROM customer_churn
WHERE CouponUsed IS NOT NULL
GROUP BY CouponUsed
ORDER BY COUNT(*) DESC
LIMIT 1) AS t
SET customer_churn.CouponUsed = t.mode_val
WHERE customer_churn.CouponUsed IS NULL;

-- OrderCount mode imputation--
UPDATE customer_churn
JOIN (
SELECT OrderCount AS mode_val
FROM customer_churn
WHERE OrderCount IS NOT NULL
GROUP BY OrderCount
ORDER BY COUNT(*) DESC
LIMIT 1) AS t
SET customer_churn.OrderCount = t.mode_val
WHERE customer_churn.OrderCount IS NULL;

/*➢ Handle outliers in the 'WarehouseToHome' column by deleting rows where the 
values are greater than 100. */
DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

/* Dealing with Inconsistencies: 
➢ Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and 
“Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure 
uniformity.*/

-- Replace "Phone" with "Mobile Phone" in PreferredLoginDevice --
UPDATE customer_churn
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice = 'Phone';

-- Replace "Mobile" with "Mobile Phone" in PreferedOrderCat --
UPDATE customer_churn
SET PreferedOrderCat = 'Mobile Phone'
WHERE PreferedOrderCat = 'Mobile';

/*➢ Standardize payment mode values: Replace "COD" with "Cash on Delivery" and 
"CC" with "Credit Card" in the PreferredPaymentMode column. */

-- Replace "COD" with "Cash on Delivery" --
UPDATE customer_churn
SET PreferredPaymentMode = 'Cash on Delivery'
WHERE PreferredPaymentMode = 'COD';

-- Replace "CC" with "Credit Card" --
UPDATE customer_churn
SET PreferredPaymentMode = 'Credit Card'
WHERE PreferredPaymentMode = 'CC';

-- Data Transformation: -----
-- Column Renaming: ---------
/*➢ Rename the column "PreferedOrderCat" to "PreferredOrderCat". */
/*➢ Rename the column "HourSpendOnApp" to "HoursSpentOnApp". */

-- Rename PreferedOrderCat → PreferredOrderCat --
ALTER TABLE customer_churn
CHANGE PreferedOrderCat PreferredOrderCat VARCHAR(20);

-- Rename HourSpendOnApp → HoursSpentOnApp --
ALTER TABLE customer_churn
CHANGE HourSpendOnApp HoursSpentOnApp INT;

/*Creating New Columns: 
➢ Create a new column named ‘ComplaintReceived’ with values "Yes" if the 
corresponding value in the ‘Complain’ is 1, and "No" otherwise. 
➢ Create a new column named 'ChurnStatus'. Set its value to “Churned” if the 
corresponding value in the 'Churn' column is 1, else assign “Active”.*/

ALTER TABLE customer_churn
ADD ComplaintReceived VARCHAR(3),
ADD ChurnStatus VARCHAR(10);

-- ComplaintReceived: Yes if Complain = 1, else No --
UPDATE customer_churn
SET ComplaintReceived = CASE 
WHEN Complain = 1 THEN 'Yes' 
ELSE 'No' 
END;

-- ChurnStatus: Churned if Churn = 1, else Active --
UPDATE customer_churn
SET ChurnStatus = CASE 
WHEN Churn = 1 THEN 'Churned' 
ELSE 'Active' 
END;

-- Column Dropping:---- 
/*➢ Drop the columns "Churn" and "Complain" from the table.*/
ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- Data Exploration and Analysis:  -- 
/*➢ Retrieve the count of churned and active customers from the dataset.*/
SELECT ChurnStatus, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

/*➢ Display the average tenure and total cashback amount of customers who 
churned.*/
SELECT AVG(Tenure) AS AvgTenure,
SUM(CashbackAmount) AS TotalCashback
FROM customer_churn
WHERE ChurnStatus = 'Churned';

/*➢ Determine the percentage of churned customers who complained. */
SELECT ROUND((SUM(CASE WHEN ChurnStatus = 'Churned' AND ComplaintReceived = 'Yes' THEN 1 ELSE 0 END) * 100.0) /
(SUM(CASE WHEN ChurnStatus = 'Churned' THEN 1 ELSE 0 END)), 2) AS PercentageChurnedWithComplaint
FROM customer_churn;

/*➢ Identify the city tier with the highest number of churned customers whose 
preferred order category is Laptop & Accessory.*/
SELECT CityTier, COUNT(*) AS ChurnedCount
FROM customer_churn
WHERE ChurnStatus = 'Churned'
AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCount DESC
LIMIT 1;

/*➢ Identify the most preferred payment mode among active customers.  */
SELECT PreferredPaymentMode, COUNT(*) AS ActiveCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY ActiveCount DESC
LIMIT 1;

/*Calculate the total order amount hike from last year for customers who are single 
and prefer mobile phones for ordering.  */
SELECT SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM customer_churn
WHERE MaritalStatus = 'Single'
AND PreferredOrderCat = 'Mobile Phone';

/* Find the average number of devices registered among customers who used UPI as 
their preferred payment mode. */
 SELECT AVG(NumberOfDeviceRegistered) AS AvgDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

 /* Determine the city tier with the highest number of customers */
SELECT CityTier, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;

/*Identify the gender that utilized the highest number of coupons. */  
SELECT Gender, SUM(CouponUsed) AS TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

/*List the number of customers and the maximum hours spent on the app in each 
preferred order category */
SELECT PreferredOrderCat, 
COUNT(*) AS CustomerCount, 
MAX(HoursSpentOnApp) AS MaxHoursSpent
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY CustomerCount DESC;

/*Calculate the total order count for customers who prefer using credit cards and 
have the maximum satisfaction score. */
SELECT SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

/* What is the average satisfaction score of customers who have complained? */
SELECT AVG(SatisfactionScore) AS AvgSatisfactionScore
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

/*List the preferred order category among customers who used more than 5 
coupons.*/
SELECT PreferredOrderCat, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat
ORDER BY CustomerCount DESC;

/* List the top 3 preferred order categories with the highest average cashback 
amount. */
SELECT PreferredOrderCat, 
AVG(CashbackAmount) AS AvgCashback
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgCashback DESC
LIMIT 3;

/*Find the preferred payment modes of customers whose average tenure is 10 
months and have placed more than 500 orders*/
SELECT PreferredPaymentMode
FROM customer_churn
WHERE Tenure = 10
AND OrderCount > 500
GROUP BY PreferredPaymentMode;

/* Categorize customers based on their distance from the warehouse to home such 
as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km, 
'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the 
churn status breakdown for each distance category*/
SELECT CASE 
WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
WHEN WarehouseToHome <= 10 THEN 'Close Distance'
WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
ELSE 'Far Distance'END AS DistanceCategory,ChurnStatus,
COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, ChurnStatus;

/*List the customer’s order details who are married, live in City Tier-1, and their 
order counts are more than the average number of orders placed by all 
customers */
SELECT CustomerID, OrderCount, PreferredOrderCat, PreferredPaymentMode
FROM customer_churn
WHERE MaritalStatus = 'Married'
AND CityTier = '1'
AND OrderCount > (SELECT AVG(OrderCount) FROM customer_churn);

/*Create
 (a). ‘customer_returns’ table in the ‘ecomm’ database and insert the 
following data:*/ 
USE ecomm;
CREATE TABLE customer_returns (
ReturnID INT PRIMARY KEY,
CustomerID INT NOT NULL,
ReturnDate DATE NOT NULL,
RefundAmount DECIMAL(10,2) NOT NULL
);
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) VALUES
(1001, 50022, '2023-01-01', 1002),
(1002, 50316, '2023-01-23', 2130),
(1003, 51099, '2023-02-14', 2000),
(1004, 52321, '2023-03-08', 2290),
(1005, 52928, '2023-03-20', 2510),
(1006, 53749, '2023-04-17', 3000),
(1007, 54206, '2023-04-21', 1740),
(1008, 54838, '2023-04-30', 3250);

/*
(b). Display the return details along with the customer details of those who have 
churned and have made complaints.*/
SELECT 
cr.ReturnID,cr.CustomerID,cr.ReturnDate,
cr.RefundAmount,cc.ChurnStatus,cc.ComplaintReceived,
cc.PreferredOrderCat,cc.PreferredPaymentMode,
cc.SatisfactionScore
FROM customer_returns cr
JOIN customer_churn cc 
ON cr.CustomerID = cc.CustomerID
WHERE cc.ChurnStatus = 'Churned'
AND cc.ComplaintReceived = 'Yes';




  
  
  
  
  
  
  
  
  
  
  
  
  














