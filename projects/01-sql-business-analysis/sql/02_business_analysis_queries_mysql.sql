-- ============================================================
-- Project: Revenue Leakage and Business Performance Analysis
-- File: 02_business_analysis_queries_mysql.sql
-- Author: Anisha Mogal
-- Description:
-- This script analyzes revenue trends, billing adjustments,
-- pricing discrepancies, pending payments, and revenue leakage.
-- ============================================================

USE revenue_leakage_analysis;

-- ============================================================
-- 1. Preview all base tables
-- ============================================================

SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM locations;
SELECT * FROM transactions;
SELECT * FROM billing_adjustments;

-- ============================================================
-- 2. Total revenue generated
-- Business Question:
-- How much total revenue was generated from all transactions?
-- ============================================================

SELECT 
    SUM(total_amount) AS total_revenue
FROM transactions;

-- ============================================================
-- 3. Monthly revenue trend
-- Business Question:
-- How does revenue change month over month?
-- ============================================================

SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS revenue_month,
    SUM(total_amount) AS monthly_revenue,
    COUNT(transaction_id) AS total_transactions
FROM transactions
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY revenue_month;

-- ============================================================
-- 4. Revenue by location
-- Business Question:
-- Which office/location generates the most revenue?
-- ============================================================

SELECT
    l.location_name,
    l.region,
    SUM(t.total_amount) AS total_revenue,
    COUNT(t.transaction_id) AS total_transactions
FROM transactions t
JOIN locations l
    ON t.location_id = l.location_id
GROUP BY l.location_name, l.region
ORDER BY total_revenue DESC;

-- ============================================================
-- 5. Revenue by customer segment
-- Business Question:
-- Which customer segment contributes the most revenue?
-- ============================================================

SELECT
    c.customer_segment,
    SUM(t.total_amount) AS total_revenue,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(AVG(t.total_amount), 2) AS avg_transaction_value
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;

-- ============================================================
-- 6. Product-level performance
-- Business Question:
-- Which products generate the most revenue?
-- ============================================================

SELECT
    p.product_name,
    p.product_category,
    SUM(t.total_amount) AS total_revenue,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.quantity) AS total_units_sold
FROM transactions t
JOIN products p
    ON t.product_id = p.product_id
GROUP BY p.product_name, p.product_category
ORDER BY total_revenue DESC;

-- ============================================================
-- 7. Pricing difference analysis
-- Business Question:
-- Are products being sold below their standard price?
-- ============================================================

SELECT
    t.transaction_id,
    p.product_name,
    p.standard_price,
    t.unit_price,
    p.standard_price - t.unit_price AS price_difference,
    t.quantity,
    (p.standard_price - t.unit_price) * t.quantity AS estimated_revenue_loss
FROM transactions t
JOIN products p
    ON t.product_id = p.product_id
WHERE t.unit_price < p.standard_price
ORDER BY estimated_revenue_loss DESC;

-- ============================================================
-- 8. Total estimated revenue loss from pricing differences
-- Business Question:
-- How much revenue may have been lost due to below-standard pricing?
-- ============================================================

SELECT
    SUM((p.standard_price - t.unit_price) * t.quantity) AS total_estimated_revenue_loss
FROM transactions t
JOIN products p
    ON t.product_id = p.product_id
WHERE t.unit_price < p.standard_price;

-- ============================================================
-- 9. Billing adjustment summary
-- Business Question:
-- What is the total impact of discounts and refunds?
-- ============================================================

SELECT
    adjustment_type,
    COUNT(adjustment_id) AS total_adjustments,
    SUM(adjustment_amount) AS total_adjustment_amount
FROM billing_adjustments
GROUP BY adjustment_type
ORDER BY total_adjustment_amount DESC;

-- ============================================================
-- 10. Billing adjustments by location
-- Business Question:
-- Which locations have the highest billing adjustment amount?
-- ============================================================

SELECT
    l.location_name,
    l.region,
    COUNT(ba.adjustment_id) AS total_adjustments,
    SUM(ba.adjustment_amount) AS total_adjustment_amount
FROM billing_adjustments ba
JOIN transactions t
    ON ba.transaction_id = t.transaction_id
JOIN locations l
    ON t.location_id = l.location_id
GROUP BY l.location_name, l.region
ORDER BY total_adjustment_amount DESC;

-- ============================================================
-- 11. Revenue leakage estimate by location
-- Business Question:
-- Which locations show the highest combined revenue leakage?
-- Revenue leakage = pricing loss + billing adjustment amount
-- ============================================================

WITH pricing_loss AS (
    SELECT
        t.location_id,
        SUM((p.standard_price - t.unit_price) * t.quantity) AS pricing_revenue_loss
    FROM transactions t
    JOIN products p
        ON t.product_id = p.product_id
    WHERE t.unit_price < p.standard_price
    GROUP BY t.location_id
),

adjustment_loss AS (
    SELECT
        t.location_id,
        SUM(ba.adjustment_amount) AS adjustment_revenue_loss
    FROM billing_adjustments ba
    JOIN transactions t
        ON ba.transaction_id = t.transaction_id
    GROUP BY t.location_id
)

SELECT
    l.location_name,
    l.region,
    COALESCE(pl.pricing_revenue_loss, 0) AS pricing_revenue_loss,
    COALESCE(al.adjustment_revenue_loss, 0) AS adjustment_revenue_loss,
    COALESCE(pl.pricing_revenue_loss, 0) + COALESCE(al.adjustment_revenue_loss, 0) AS total_estimated_leakage
FROM locations l
LEFT JOIN pricing_loss pl
    ON l.location_id = pl.location_id
LEFT JOIN adjustment_loss al
    ON l.location_id = al.location_id
ORDER BY total_estimated_leakage DESC;

-- ============================================================
-- 12. Pending payment analysis
-- Business Question:
-- How much revenue is pending collection?
-- ============================================================

SELECT
    payment_status,
    COUNT(transaction_id) AS total_transactions,
    SUM(total_amount) AS total_amount
FROM transactions
GROUP BY payment_status
ORDER BY total_amount DESC;

-- ============================================================
-- 13. Pending payments by customer
-- Business Question:
-- Which customers have pending payments?
-- ============================================================

SELECT
    c.customer_name,
    c.customer_segment,
    t.transaction_id,
    t.transaction_date,
    t.total_amount,
    t.payment_status
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
WHERE t.payment_status = 'Pending'
ORDER BY t.total_amount DESC;

-- ============================================================
-- 14. Top customers by revenue
-- Business Question:
-- Which customers contribute the most revenue?
-- ============================================================

SELECT
    c.customer_name,
    c.customer_segment,
    c.city,
    c.state,
    SUM(t.total_amount) AS total_revenue,
    COUNT(t.transaction_id) AS total_transactions
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY c.customer_name, c.customer_segment, c.city, c.state
ORDER BY total_revenue DESC;

-- ============================================================
-- 15. Customer ranking by revenue using window function
-- Business Question:
-- How do customers rank by revenue within their segment?
-- ============================================================

SELECT
    c.customer_segment,
    c.customer_name,
    SUM(t.total_amount) AS total_revenue,
    RANK() OVER (
        PARTITION BY c.customer_segment 
        ORDER BY SUM(t.total_amount) DESC
    ) AS segment_revenue_rank
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY c.customer_segment, c.customer_name
ORDER BY c.customer_segment, segment_revenue_rank;

-- ============================================================
-- 16. Monthly revenue with previous month comparison
-- Business Question:
-- How much did revenue increase or decrease each month?
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(transaction_date, '%Y-%m') AS revenue_month,
        SUM(total_amount) AS monthly_revenue
    FROM transactions
    GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
)

SELECT
    revenue_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY revenue_month) AS previous_month_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY revenue_month) AS revenue_change
FROM monthly_revenue
ORDER BY revenue_month;

-- ============================================================
-- 17. Transactions with billing adjustment details
-- Business Question:
-- Which transactions received discounts or refunds?
-- ============================================================

SELECT
    t.transaction_id,
    t.transaction_date,
    c.customer_name,
    p.product_name,
    l.location_name,
    t.total_amount,
    ba.adjustment_type,
    ba.adjustment_amount,
    ba.reason
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
JOIN products p
    ON t.product_id = p.product_id
JOIN locations l
    ON t.location_id = l.location_id
JOIN billing_adjustments ba
    ON t.transaction_id = ba.transaction_id
ORDER BY ba.adjustment_amount DESC;

-- ============================================================
-- 18. Final executive summary query
-- Business Question:
-- What are the key revenue, adjustment, and pending payment metrics?
-- ============================================================

SELECT
    (SELECT SUM(total_amount) FROM transactions) AS total_revenue,
    (SELECT SUM(adjustment_amount) FROM billing_adjustments) AS total_billing_adjustments,
    (
        SELECT SUM((p.standard_price - t.unit_price) * t.quantity)
        FROM transactions t
        JOIN products p
            ON t.product_id = p.product_id
        WHERE t.unit_price < p.standard_price
    ) AS total_pricing_revenue_loss,
    (
        SELECT SUM(total_amount)
        FROM transactions
        WHERE payment_status = 'Pending'
    ) AS pending_revenue;