-- BUSINESS PROBLEM 1: Payment Method Performance Analysis
-- Question: Which payment methods do customers prefer and generate most revenue?
-- HomeLane Relevance: Understanding customer payment preferences for interior design projects

SELECT 
    payment_method, 
    COUNT(*) as no_of_transactions,
    SUM(quantity) as total_items_sold,
    ROUND(SUM(total), 2) as total_revenue,
    ROUND(AVG(total), 2) as avg_transaction_value
FROM walmart 
GROUP BY payment_method 
ORDER BY total_revenue DESC;

-- BUSINESS PROBLEM 2: Best Performing Category by Branch Location
-- Question: Which product category performs best in each branch?
-- HomeLane Relevance: Understanding regional preferences for interior design services

WITH branch_category_performance AS (
  SELECT 
    branch, 
    category, 
    AVG(rating) AS avg_rating,
    COUNT(*) as total_transactions,
    SUM(total) as category_revenue
  FROM walmart
  GROUP BY branch, category
),
ranked_categories AS (
  SELECT
    branch,
    category,
    ROUND(avg_rating, 2) as avg_rating,
    total_transactions,
    ROUND(category_revenue, 2) as revenue,
    RANK() OVER (PARTITION BY branch ORDER BY avg_rating DESC) AS performance_rank
  FROM branch_category_performance
)
SELECT 
    branch, 
    category, 
    avg_rating,
    total_transactions,
    revenue
FROM ranked_categories
WHERE performance_rank = 1
ORDER BY branch;

-- BUSINESS PROBLEM 3: Peak Operating Days by Branch
-- Question: Which days are busiest for each branch location?
-- HomeLane Relevance: Optimal scheduling for design consultations and site visits

SELECT 
    branch, 
    day_name, 
    total_transactions,
    total_revenue
FROM (
    SELECT 
        branch,
        DATE_FORMAT(STR_TO_DATE(date, '%d/%m/%y'), '%W') AS day_name,
        COUNT(*) AS total_transactions,
        ROUND(SUM(total), 2) as total_revenue,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS day_rank
    FROM walmart
    GROUP BY branch, day_name
) ranked_days
WHERE day_rank = 1
ORDER BY total_transactions DESC;

-- BUSINESS PROBLEM 4: Customer Satisfaction Analysis by City
-- Question: How do customer ratings vary across different cities and categories?
-- HomeLane Relevance: Regional service quality benchmarking

SELECT
    city, 
    category,
    COUNT(*) as total_reviews,
    ROUND(MIN(rating), 1) as lowest_rating,
    ROUND(MAX(rating), 1) as highest_rating,
    ROUND(AVG(rating), 1) as average_rating
FROM walmart 
GROUP BY city, category
HAVING total_reviews >= 5  -- Only cities with significant data
ORDER BY average_rating DESC, total_reviews DESC
LIMIT 20;

-- BUSINESS PROBLEM 5: Category Profitability Analysis
-- Question: Which product categories generate the highest profits?
-- HomeLane Relevance: Focus resources on most profitable interior design services

SELECT 
    category,
    COUNT(*) as total_transactions,
    ROUND(SUM(total), 2) AS total_revenue,
    ROUND(SUM(total * profit_margin), 2) AS total_profit,
    ROUND(AVG(profit_margin * 100), 2) as avg_profit_margin_percent,
    ROUND((SUM(total * profit_margin) / SUM(total)) * 100, 2) as overall_margin_percent
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;

-- BUSINESS PROBLEM 6: Branch Payment Method Preferences
-- Question: What is the most popular payment method for each branch?
-- HomeLane Relevance: Optimize payment processing systems per location

SELECT 
    branch, 
    payment_method, 
    transaction_count,
    revenue_share
FROM (
  SELECT 
    branch,
    payment_method,
    COUNT(*) AS transaction_count,
    ROUND(SUM(total), 2) as revenue_share,
    RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS preference_rank
  FROM walmart
  GROUP BY branch, payment_method
) payment_preferences
WHERE preference_rank = 1
ORDER BY transaction_count DESC;

-- BUSINESS PROBLEM 7: Sales Performance by Time of Day
-- Question: Which time periods generate the most business?
-- HomeLane Relevance: Optimize consultant scheduling and service delivery timing

SELECT
    time_period,
    total_transactions,
    total_revenue,
    avg_transaction_value,
    ROUND((total_revenue / SUM(total_revenue) OVER()) * 100, 2) as revenue_percentage
FROM (
    SELECT
        CASE 
            WHEN HOUR(TIME(time)) < 12 THEN 'Morning (6AM-12PM)'
            WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon (12PM-5PM)'
            ELSE 'Evening (5PM-10PM)'
        END AS time_period,
        COUNT(*) AS total_transactions,
        ROUND(SUM(total), 2) as total_revenue,
        ROUND(AVG(total), 2) as avg_transaction_value
    FROM walmart
    GROUP BY time_period
) time_analysis
ORDER BY total_revenue DESC;

-- BUSINESS PROBLEM 8: Year-over-Year Performance Decline Analysis
-- Question: Which branches show declining performance that need intervention?
-- HomeLane Relevance: Early warning system for underperforming locations

WITH yearly_performance AS (
    SELECT 
        branch,
        YEAR(STR_TO_DATE(date, '%d/%m/%Y')) as year,
        COUNT(*) as transactions,
        ROUND(SUM(total), 2) AS annual_revenue,
        ROUND(AVG(rating), 2) as avg_rating
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) IN (2022, 2023)
    GROUP BY branch, year
),
performance_comparison AS (
    SELECT 
        branch,
        MAX(CASE WHEN year = 2022 THEN annual_revenue END) AS revenue_2022,
        MAX(CASE WHEN year = 2023 THEN annual_revenue END) AS revenue_2023,
        MAX(CASE WHEN year = 2022 THEN transactions END) AS transactions_2022,
        MAX(CASE WHEN year = 2023 THEN transactions END) AS transactions_2023
    FROM yearly_performance
    GROUP BY branch
    HAVING revenue_2022 IS NOT NULL AND revenue_2023 IS NOT NULL
)
SELECT 
    branch,
    revenue_2022,
    revenue_2023,
    transactions_2022,
    transactions_2023,
    ROUND(((revenue_2023 - revenue_2022) / revenue_2022) * 100, 2) AS revenue_growth_percent,
    ROUND(((transactions_2023 - transactions_2022) / transactions_2022) * 100, 2) AS transaction_growth_percent
FROM performance_comparison
ORDER BY revenue_growth_percent ASC
LIMIT 10;

-- BUSINESS PROBLEM 9: High-Value Customer Transaction Analysis
-- Question: What characterizes high-value transactions?
-- HomeLane Relevance: Understanding premium customer behavior for luxury interior projects

SELECT 
    branch,
    category,
    payment_method,
    COUNT(*) as high_value_transactions,
    ROUND(AVG(total), 2) as avg_transaction_value,
    ROUND(AVG(rating), 2) as avg_customer_satisfaction,
    ROUND(AVG(quantity), 2) as avg_items_per_transaction
FROM walmart
WHERE total > (SELECT AVG(total) * 1.5 FROM walmart)  -- Top 50% above average
GROUP BY branch, category, payment_method
HAVING high_value_transactions >= 5
ORDER BY avg_transaction_value DESC
LIMIT 15;