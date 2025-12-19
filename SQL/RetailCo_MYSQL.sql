CREATE DATABASE retailco;
USE retailco;

-- CUSTOMER-FOCUSED SQL QUESTIONS

-- 1.1 Customer Lifetime Value (SQL Version)
-- Question:
-- Calculate total revenue, total transactions, and average order value per customer.
-- Business Use:
-- Identify long-term value customers
 

SELECT customer_id, SUM(net_amount) as total_revenue, COUNT(invoice_id) as total_transactions, ROUND(AVG(net_amount), 2) as average_order
FROM transaction_data
GROUP BY customer_id
ORDER BY total_revenue desc, total_transactions desc, average_order desc;


-- 1.2 Customer Purchase Frequency Buckets
-- Question:
-- Classify customers into:
-- One-time buyers
-- Occasional buyers (2–5)
-- Frequent buyers (>5)

-- Business Use:
-- Retention & loyalty planning

SELECT customer_id, COUNT(invoice_id) AS purchase_count,
	CASE
		WHEN COUNT(invoice_id) = 1 THEN "One-time buyers"
        WHEN COUNT(invoice_id) BETWEEN 2 AND 5 THEN "Occasional buyers"
        ELSE "Frequent buyers"
	END AS purchase_frequency
FROM transaction_data
GROUP BY customer_id;

-- 1.3 Inactive Customer Detection (SQL)
-- Question:
-- Identify customers who have not purchased in the last 90 days.
-- Business Use:
-- Win-back campaigns

SELECT DISTINCT(customer_id) FROM transaction_data
WHERE customer_id NOT IN (SELECT DISTINCT(customer_id)
FROM transaction_data
WHERE invoice_date BETWEEN DATE_SUB((SELECT MAX(invoice_date) FROM transaction_data), INTERVAL 90 DAY)
AND (SELECT MAX(invoice_date) FROM transaction_data)
);

-- 1.4 Customer Discount Dependency
-- Question:
-- Identify customers whose average discount rate is above the company average.
-- Business Use:
-- Detect discount-sensitive customers

SELECT DISTINCT(customer_id) FROM transaction_data
WHERE discount_amount > (SELECT AVG(discount_amount) FROM transaction_data);

        
-- STORE & REGIONAL INTELLIGENCE

-- 2.1 Store Revenue vs Discount Efficiency
-- Question:
-- For each store:
-- Total net revenue
-- Average discount
-- Revenue per transaction
-- Business Use:
-- Find stores that sell well without heavy discounts

SELECT
    s.store_id,
    s.store_name,
    SUM(t.net_amount) AS total_net_revenue,
    ROUND(AVG(t.discount_amount), 2) AS average_discount,
    ROUND(AVG(t.net_amount), 2) AS revenue_per_transaction
FROM transaction_data t
JOIN store_data s ON t.store_id = s.store_id
GROUP BY s.store_id, s.store_name;

-- 2.2 Store Ranking Within Region
-- Question:
-- Rank stores by revenue within each region.
-- Business Use:
-- Regional benchmarking

SELECT
	s.store_id,
    s.region,
    SUM(t.net_amount) as net_revenue
FROM store_data s
JOIN transaction_data t ON s.store_id = t.store_id
GROUP BY s.store_id, s.region
ORDER BY net_revenue desc;
    
-- 2.3 Revenue Concentration Risk
-- Question:
-- What % of total revenue comes from the top 20% stores?
-- Business Use:
-- Business risk analysis
    
SOLVE IT AGAIN

-- EMPLOYEE & DISCOUNT GOVERNANCE (REAL-WORLD)

-- 3.1 Employee Discount Authority Impact
-- Question:
-- Compare revenue and average discount between:
-- Employees who can approve discounts
-- Employees who cannot

-- Business Use:
-- Policy evaluation
 
SELECT
    e.user_id,
    SUM(t.net_amount) AS total_revenue,
    ROUND(AVG(t.discount_amount), 2) AS average_discount
FROM employee_data e
JOIN transaction_data t
    ON e.user_id = t.created_by
WHERE e.can_approve_discount = 'Y'
GROUP BY e.user_id;

SELECT
    e.user_id,
    SUM(t.net_amount) AS total_revenue,
    ROUND(AVG(t.discount_amount), 2) AS average_discount
FROM employee_data e
JOIN transaction_data t
    ON e.user_id = t.created_by
WHERE e.can_approve_discount = 'N'
GROUP BY e.user_id;


-- 3.2 Discount Abuse Detection
-- Question:
-- Identify employees whose average discount is significantly higher than store average.
-- Business Use:
-- Internal audit & fraud prevention

SELECT
    created_by,
    ROUND(AVG(discount_amount), 2) AS average_discount
FROM transaction_data
GROUP BY created_by
HAVING AVG(discount_amount) >
       (SELECT AVG(discount_amount) FROM transaction_data);

-- 3.3 Employee Productivity Index
-- Question:
-- Calculate revenue per invoice per employee.
-- Business Use:
-- Performance appraisal
-- Incentive calculation


SELECT
    created_by AS employee_id,
    ROUND(SUM(net_amount) / COUNT(DISTINCT invoice_id), 2) AS revenue_per_invoice
FROM transaction_data
GROUP BY created_by;

-- PRODUCT & PRICING INTELLIGENCE (ADVANCED)

-- 4.1 Product Discount Elasticity
-- Question:
-- For each product:
-- Average discount %
-- Average quantity sold

-- Business Use:
-- Identify products where discounts actually increase volume
 
SELECT product_id, ROUND(AVG(quantity), 2) as avg_quantity, CONCAT(ROUND(((SUM(discount_amount)/SUM(net_amount))*100), 2), "%") AS avg_disc_per 
FROM transaction_data
GROUP BY product_id
ORDER BY avg_quantity desc; 

-- 4.2 High-Revenue, Low-Frequency Products
-- Question:
-- Identify products that:
-- Sell less frequently
-- Generate high net revenue per transaction
-- Business Use:
-- Premium product strategy

SELECT
    product_id,
    COUNT(DISTINCT invoice_id) AS purchase_frequency,
    ROUND(SUM(net_amount) / COUNT(DISTINCT invoice_id), 2) AS revenue_per_transaction
FROM transaction_data
GROUP BY product_id
HAVING
    COUNT(DISTINCT invoice_id) < (
        SELECT AVG(product_freq)
        FROM (
            SELECT COUNT(DISTINCT invoice_id) AS product_freq
            FROM transaction_data
            GROUP BY product_id
        ) x
    )
    AND
    (SUM(net_amount) / COUNT(DISTINCT invoice_id)) >
    (
        SELECT AVG(rev_per_txn)
        FROM (
            SELECT SUM(net_amount) / COUNT(DISTINCT invoice_id) AS rev_per_txn
            FROM transaction_data
            GROUP BY product_id
        ) y
    )
ORDER BY revenue_per_transaction DESC;

-- 4.3 Store–Product Dependency
-- Question:
-- Which products generate the most revenue per store?
-- Business Use:
-- Localized assortment planning


-- TIME-BASED & TREND ANALYSIS

-- 5.1 Month-over-Month Growth (SQL)
-- Question:
-- Calculate month-over-month revenue growth %.
-- Business Use:
-- Executive reporting
-- Growth tracking

SELECT MONTH(posting_date) as month, SUM(net_amount) FROM transaction_data
WHERE YEAR(posting_date) = "2024"
GROUP BY month
ORDER BY SUM(net_amount) desc;

-- 5.2 Sales Seasonality by Store
-- Question:
-- Identify peak sales months for each store.
-- Business Use:
-- Staffing & inventory planning


SELECT
    store_id,
    month,
    monthly_revenue
FROM (SELECT
        store_id,
        MONTH(posting_date) AS month,
        SUM(net_amount) AS monthly_revenue,
        RANK() OVER (PARTITION BY store_id 
			ORDER BY SUM(net_amount) DESC) AS sales_rank
    FROM transaction_data
    GROUP BY store_id, month
) t
WHERE sales_rank = 1
ORDER BY store_id;


-- 5.3 Posting Date vs Invoice Date Lag
-- Question:
-- Calculate average delay between invoice_date and posting_date per store.
-- Business Use:
-- Process efficiency
-- Finance operations improvement

SELECT store_id, ROUND(AVG(DATEDIFF(posting_date, invoice_date)), 2) AS avg_posting_delay_days
FROM transaction_data
GROUP BY store_id
ORDER BY avg_posting_delay_days DESC;

-- POWER BI–READY SQL VIEWS

-- Create Customer Summary View

CREATE VIEW customer_summary AS
SELECT customer_id, 
	SUM(net_amount) as total_revenue, 
	COUNT(invoice_id) as total_transactions, 
    ROUND(AVG(discount_amount), 2) as avg_discount
FROM transaction_data
GROUP BY customer_id;

SELECT * FROM customer_summary;

-- Store Performance View

CREATE VIEW store_summary AS
SELECT store_id, 
	SUM(net_amount) as total_revenue, 
	COUNT(invoice_id) as total_transactions, 
    ROUND(AVG(discount_amount), 2) as avg_discount
FROM transaction_data
GROUP BY store_id;


        