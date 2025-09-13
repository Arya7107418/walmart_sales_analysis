SELECT COUNT(DISTINCT BRANCH) BRANCH FROM walmart;
SELECT MAX(quantity) FROM walmart;
SELECT MIN(quantity) FROM walmart;

-- Business Problems
-- Q.1 Find different payment method and number of transactions, number of qty sold
SELECT payment_method, COUNT(*) as no_of_transactions,
SUM(quantity) as no_of_qty_sold
 FROM walmart GROUP BY payment_method 
 ORDER BY no_of_transactions DESC;
 
 -- Q.2 Identify the highest-rated category in each branch , displaying the branch, category
 -- AVG RATING
 
WITH agg AS (
  SELECT branch, category, AVG(rating) AS avg_rating
  FROM walmart
  GROUP BY branch, category
),
ranked AS (
  SELECT
    branch,
    category,
    avg_rating,
    RANK() OVER (PARTITION BY branch ORDER BY avg_rating DESC) AS rank_in_branch
  FROM agg
)
SELECT *
FROM ranked
WHERE rank_in_branch = 1
ORDER BY branch;

-- Q3 Identify the busiest date for each branch based on the number of transactions
SELECT *
FROM (
    SELECT 
        branch,
        DATE_FORMAT(STR_TO_DATE(date, '%d/%m/%y'), '%W') AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER (
            PARTITION BY branch 
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM walmart
    GROUP BY branch, day_name
) t
WHERE rnk = 1
ORDER BY branch;

-- Q4 Calculate the total quantity of items sold per payment methods. List the payment_method and total_quantity.
SELECT payment_method , SUM(quantity) as no_of_qty_sold
FROM walmart
GROUP BY payment_method
ORDER BY no_of_qty_sold DESC;

-- Q5 Determine the average, minimum and maximum rating of products for each city. 
-- List the city, average_rating, min_rating, max_rating.
SELECT
 city, category,
 MIN(rating) as min_rating,
 MAX(rating) as max_rating,
 AVG(rating) as avg_rating
 FROM walmart GROUP BY city, category;

-- Q6 Calculate the total profit for each category by considering total_profit as (unit_price * quantity * profit_margin).
-- List category and total_profit, ordered from highest to lowest profit.
SELECT 
    category,
    SUM(total) AS total_revenue,
    SUM(total * profit_margin) AS profit
FROM walmart
GROUP BY category;

-- Q7 Determine the most common payment method for each Branch.
-- Display Branch and the preferred_payment_method.
SELECT branch, payment_method, total_trans, rnk
FROM (
  SELECT branch,
         payment_method,
         COUNT(*) AS total_trans,
         RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
  FROM walmart
  GROUP BY branch, payment_method
) t
WHERE rnk = 1;

-- Q8 Categorise sales into 3 group MORNING, AFTERNOON, EVENING
-- Find out each of the shift and number of invoices
SELECT
    branch,
    CASE 
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;

-- Q9 Identify 5 branch with highest decrease ratio in
-- revenue compare to last year (current year 2023 and last year 2022)
WITH revenue_2022 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2023
    GROUP BY branch
)
SELECT 
    r2022.branch,
    r2022.revenue AS last_year_revenue,
    r2023.revenue AS current_year_revenue,
    ROUND(((r2022.revenue - r2023.revenue) / r2022.revenue) * 100, 2) AS revenue_decrease_ratio
FROM revenue_2022 AS r2022
JOIN revenue_2023 AS r2023 ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;
