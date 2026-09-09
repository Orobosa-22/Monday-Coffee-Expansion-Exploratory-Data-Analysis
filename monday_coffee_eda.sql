-- Monday Coffee Analysis

SELECT * FROM city;
SELECT *FROM customers;
SELECT *FROM products;
SELECT *FROM sales;

-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) AS estimated_consumption_millions,
	city_rank
FROM city
ORDER BY estimated_consumption_millions DESC;
    
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT
    city.city_name,
    SUM(sales.total) AS total_sales
FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
WHERE EXTRACT(YEAR FROM sales.sale_date) = 2023 AND EXTRACT(QUARTER FROM sales.sale_date) = 4
GROUP BY city.city_name
ORDER BY total_sales DESC;

-- Units of each coffee product have been sold

SELECT 
	products.product_name,
	SUM(sales.total)/products.price AS units_sold
FROM sales
LEFT JOIN products 
	ON sales.product_id = products.product_id
GROUP BY 
	products.product_name,
    products.price
ORDER BY units_sold DESC;

-- 0r

SELECT 
	products.product_name,
	COUNT(sales.sale_id) units_sold
FROM sales
LEFT JOIN products 
	ON sales.product_id = products.product_id
GROUP BY 
	products.product_name
ORDER BY units_sold DESC;

-- Average sales amount per customer in each city

SELECT 
    city.city_name,
    SUM(sales.total) AS total_revenue,
    COUNT(DISTINCT sales.customer_id) AS total_customer,
    ROUND(SUM(sales.total) / COUNT(DISTINCT sales.customer_id), 2) AS avg_sale_per_customer
FROM sales
JOIN customers
    ON sales.customer_id = customers.customer_id
JOIN city AS city
    ON city.city_id = customers.city_id
GROUP BY city.city_name
ORDER BY total_revenue DESC;

-- list of cities along with their populations and estimated coffee consumers.

SELECT
	city.city_name,
    ROUND(SUM(city.population*0.25)/1000000, 1) AS population_in_millions,
    COUNT(DISTINCT customer_id) AS estimated_coffee_consumers
FROM city
LEFT JOIN customers ON city.city_id = customers.city_id
GROUP BY city.city_name
ORDER BY estimated_coffee_consumers DESC;

-- Top 3 selling products in each city based on sales volume

WITH product_sales AS (
SELECT 
	ci.city_name,
    p.product_name,
    COUNT(s.sale_id) AS sales_volume
FROM sales AS s
JOIN customers AS cu
	ON s.customer_id = cu.customer_id
JOIN city AS ci
	ON cu.city_id = ci.city_id
JOIN products AS p
	ON s.product_id = p.product_id
GROUP BY 
	ci.city_name,
    p.product_name
),
ranked_products AS (
SELECT 
	city_name,
    product_name,
    sales_volume,
	ROW_NUMBER() OVER(
		PARTITION BY city_name 
        ORDER BY sales_volume DESC
	) AS product_rank
FROM product_sales
)
SELECT 
	city_name,
    product_name,
    sales_volume,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
GROUP BY 
	city_name,
    product_name;

-- Unique customers in each city who have purchased coffee products

SELECT
    ci.city_name,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM sales AS s
JOIN customers AS c
    ON s.customer_id = c.customer_id
JOIN city AS ci
    ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY unique_customers DESC;

-- find each city and their average sale per customer and avg rent per customer

SELECT 
	ci.city_name,
    ROUND(SUM(sa.total) / COUNT(DISTINCT sa.customer_id), 2) AS avg_sale_per_customer,
    ROUND(ci.estimated_rent / COUNT(DISTINCT sa.customer_id), 2) AS avg_rent_per_customer
FROM city AS ci
JOIN customers AS cu
    ON ci.city_id = cu.city_id
JOIN sales AS sa
    ON cu.customer_id = sa.customer_id
GROUP BY
    ci.city_name,
    ci.estimated_rent
ORDER BY avg_sale_per_customer DESC;
 
 
 
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) for eachcity.

WITH monthly_sales AS (
    SELECT
        ci.city_name,
        DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
        SUM(s.total) AS monthly_revenue
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON c.city_id = ci.city_id
    GROUP BY
        ci.city_name,
        DATE_FORMAT(s.sale_date, '%Y-%m')
),

sales_growth AS (
    SELECT
        city_name,
        month,
        monthly_revenue,

        LAG(monthly_revenue) OVER (
            PARTITION BY city_name
            ORDER BY month
        ) AS previous_month_revenue

    FROM monthly_sales
)

SELECT
    city_name,
    month,
    monthly_revenue,
    previous_month_revenue,

    ROUND(
        (monthly_revenue - previous_month_revenue)
        / previous_month_revenue * 100,
        2
    ) AS growth_rate

FROM sales_growth
ORDER BY city_name, month;


-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT
    ci.city_name,
    SUM(s.total) AS total_sale,
    ci.estimated_rent AS total_rent,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(ci.population * 0.25, 0) AS estimated_coffee_consumer
FROM city AS ci
JOIN customers AS c
    ON ci.city_id = c.city_id
JOIN sales AS s
    ON c.customer_id = s.customer_id
GROUP BY
    ci.city_name,
    ci.population,
    ci.estimated_rent
ORDER BY total_sale DESC
LIMIT 3;












