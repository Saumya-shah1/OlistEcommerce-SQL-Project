---Data Understanding...
SELECT TOP 5 * FROM OlistEcommerce..Orders;
SELECT TOP 5 * FROM OlistEcommerce..Customers;
SELECT TOP 5 * FROM OlistEcommerce..OrderItems;
SELECT TOP 5 * FROM OlistEcommerce..Products;
SELECT TOP 5 * FROM OlistEcommerce..Reviews;


----Data Cleaning----
---- Step 1 : Check Nulls for all Tables----
SELECT 
    COUNT(*) AS Null_Customers
FROM OlistEcommerce..Customers
WHERE customer_id IS NULL 
   OR customer_unique_id IS NULL 
   OR customer_city IS NULL 
   OR customer_state IS NULL;

----Customer Table have no null values from Selected columns

SELECT 
    COUNT(*) AS Null_Orders
FROM OlistEcommerce..Orders
WHERE order_id IS NULL 
   OR customer_id IS NULL 
   OR order_status IS NULL 
   OR order_purchase_timestamp IS NULL 
   OR order_estimated_delivery_date IS NULL;

----Order Table have no null values from Selected columns

SELECT 
    COUNT(*) AS Null_OrderItems
FROM OlistEcommerce..OrderItems
WHERE order_id IS NULL 
   OR order_item_id IS NULL 
   OR product_id IS NULL 
   OR seller_id IS NULL 
   OR price IS NULL 
   OR freight_value IS NULL;

----OrderItems Table have no null values from Selected columns

SELECT 
    COUNT(*) AS Null_Products
FROM OlistEcommerce..Products
WHERE product_id IS NULL 
   OR product_category_name IS NULL 
   OR product_weight_g IS NULL 
   OR product_length_cm IS NULL 
   OR product_height_cm IS NULL 
   OR product_width_cm IS NULL;

----Products have 611 Rows have  Null values in selected columns, now have check which columns have null values----

SELECT 
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS Null_Category,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS Null_Weight,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS Null_Length,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS Null_Height,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS Null_Width
FROM OlistEcommerce..Products;

----product_category_name have 610 columns null values and rest of the columns have 2 null values in it----


----Replace Null values in Product_category_name with unknown and averages rest of numeric values---
----Replace other null values in product_name_length,product_description_length and product_photos_qty too.----

UPDATE OlistEcommerce..Products
SET product_category_name = 'Unknown'
WHERE product_category_name IS NULL;

UPDATE  OlistEcommerce..Products
SET product_weight_g = (
    SELECT AVG(product_weight_g)
    FROM  OlistEcommerce..Products
    WHERE product_weight_g IS NOT NULL
)
WHERE product_weight_g IS NULL;

UPDATE  OlistEcommerce..Products
SET product_length_cm = (
    SELECT AVG(product_length_cm)
    FROM  OlistEcommerce..Products
    WHERE product_length_cm IS NOT NULL
)
WHERE product_length_cm IS NULL;

UPDATE  OlistEcommerce..Products
SET product_height_cm = (
    SELECT AVG(product_height_cm)
    FROM  OlistEcommerce..Products
    WHERE product_height_cm IS NOT NULL
)
WHERE product_height_cm IS NULL;

UPDATE  OlistEcommerce..Products
SET product_width_cm = (
    SELECT AVG(product_width_cm)
    FROM  OlistEcommerce..Products
    WHERE product_width_cm IS NOT NULL
)
WHERE product_width_cm IS NULL;

UPDATE OlistEcommerce..Products
SET 
    product_name_lenght = COALESCE(product_name_lenght, 0),
    product_description_lenght = COALESCE(product_description_lenght, 0),
    product_photos_qty = COALESCE(product_photos_qty, 0);

------------------------------------------------------------------------------------------------------------------------------------Done With Null Values------------------------------------------------------------------

----Step 2 : Check for Duplicates values in Primary keys and composite keys ----

SELECT customer_id, COUNT(*) AS Duplicate_Count
FROM OlistEcommerce..Customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS Duplicate_Count
FROM OlistEcommerce..Orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_id, order_item_id, COUNT(*) AS Duplicate_Count
FROM OlistEcommerce..OrderItems
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*) AS Duplicate_Count
FROM OlistEcommerce..Products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT review_id, COUNT(*) AS Duplicate_Count
FROM OlistEcommerce..Reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

----789 Rows are duplicated in review id and in review_score, review_comment_message, review_creation_date column so remove redundant rows of data with qeury ----

WITH CTE AS 
     (SELECT *,
           ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_creation_date) AS rn
    FROM OlistEcommerce..Reviews)
DELETE FROM OlistEcommerce..Reviews
WHERE review_id IN
       (SELECT review_id FROM CTE WHERE rn > 1);

----------------------------------------------------------------------------Analysis of Dataset with some queries-------------------------------------------------------------------------------------------

----Total orders, Total Customers and Total Revenue----

SELECT 
  COUNT(DISTINCT o.order_id) AS Total_Orders,
  COUNT(DISTINCT c.customer_unique_id) AS Total_Customers,
  ROUND(SUM(oi.price + oi.freight_value), 2) AS Total_Revenue
FROM OlistEcommerce..Orders o
JOIN OlistEcommerce..OrderItems oi ON o.order_id = oi.order_id
JOIN OlistEcommerce..Customers c ON o.customer_id = c.customer_id;

-------Total_Orders = 98666 / Total_Customer = 95420 / Total_Revenue = 15843553.24-------

----Top 10 Best-Selling Product Categories----

SELECT TOP 10 
  p.product_category_name,
  COUNT(oi.order_id) AS Total_Sold,
  ROUND(SUM(oi.price),2) AS Revenue
FROM OlistEcommerce..OrderItems oi
JOIN OlistEcommerce..Products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY Revenue DESC;


----Calculating Revenue Trend for each Month----

SELECT 
  FORMAT(order_purchase_timestamp, 'yyyy-MM') AS Month,
  ROUND(SUM(oi.price), 2) AS Monthly_Revenue
FROM OlistEcommerce..Orders o
JOIN OlistEcommerce..OrderItems oi ON o.order_id = oi.order_id
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY Month;


----Calculating Average Delivery Time----

SELECT 
  ROUND(AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)),2) AS Avg_Delivery_Days
FROM OlistEcommerce..Orders
WHERE order_status = 'delivered';

----Avg_Delivery_Days are 12----
----Delivery Days for all orders----
SELECT 
  order_id,
  DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS Delivery_Days
FROM OlistEcommerce..Orders
WHERE order_status = 'delivered';

----who is Most Profitable Sellers----

SELECT TOP 10 
  oi.seller_id,
  ROUND(SUM(oi.price - oi.freight_value),2) AS Seller_Profit
FROM OlistEcommerce..OrderItems oi
GROUP BY oi.seller_id
ORDER BY Seller_Profit DESC;

----Review Score Distribution----

SELECT 
  review_score,
  COUNT(*) AS Review_Count
FROM OlistEcommerce..Reviews
GROUP BY review_score
ORDER BY review_score DESC;

----Correlation: Late Delivery vs Review Rating----

SELECT 
  CASE 
    WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) > 0 THEN 'Late'
    ELSE 'On Time'
  END AS Delivery_Status,
  ROUND(AVG(review_score),2) AS Avg_Review_Score,
  COUNT(*) AS Orders
FROM OlistEcommerce..Orders o
JOIN OlistEcommerce..Reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY 
  CASE 
    WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) > 0 THEN 'Late'
    ELSE 'On Time'
  END;

----Repeat Customers : who are the ones who comebcak for shopping another items----

SELECT 
  customer_unique_id,
  COUNT(DISTINCT order_id) AS Order_Count
FROM OlistEcommerce..Orders o
JOIN OlistEcommerce..Customers c ON o.customer_id = c.customer_id
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT order_id) > 1
ORDER BY Order_Count DESC;

----2997 Customers are Repeat Customers 
----Total_customers are 95420 and repeat customers are 2997.----
----Repeat_customer rate is  ~3.1%


----Most Used Payment Method----
SELECT 
  payment_type,
  COUNT(*) AS Number_of_Payments,
  ROUND(SUM(payment_value),2) AS Total_Revenue
FROM OlistEcommerce..Payments
GROUP BY payment_type
ORDER BY Number_of_Payments DESC;


----Average Payment Value by Method----

SELECT 
  payment_type,
  ROUND(AVG(payment_value),2) AS Avg_Payment
FROM OlistEcommerce..Payments
GROUP BY payment_type
ORDER BY Avg_Payment DESC;



----THE END----





