/* “I know that the price/standard_qty paper varies from one order to the next.
I would like this ratio across all of the sales made.” */

SELECT
  SUM(standard_amt_usd) / SUM(standard_qty) AS avg_price_per_standard_paper
FROM `backwoodpaper_sql_tutorial.orders`
WHERE standard_qty > 0

  
/* “When did the most recent web activities occur?” */

SELECT
  MAX(occurred_at)
FROM `backwoodpaper_sql_tutorial.web_events`

  
/* “What is the mean (average) amount spent per order on each paper type,
as well as the mean amount of each paper type purchased per order?” */ 

SELECT
  AVG(standard_amt_usd) AS avg_standard_usd,
  AVG(standard_qty) AS avg_standard_qty,
  AVG(gloss_amt_usd) AS avg_gloss_usd,
  AVG(gloss_qty) AS avg_gloss_qty,
  AVG(poster_amt_usd) AS avg_poster_usd,
  AVG(poster_qty) AS avg_poster_qty
FROM `backwoodpaper_sql_tutorial.orders`

  
/* “What was the smallest order placed by each account in terms of total usd spent?
I would like to know the account and the product.” */

SELECT
  account_id,
  MIN(standard_amt_usd) AS standard_smallest,
  MIN(gloss_amt_usd) AS gloss_smallest,
  MIN(poster_amt_usd) AS poster_smallest
FROM `backwoodpaper_sql_tutorial.orders`
GROUP BY 1
ORDER BY 1

  
/* “Which accounts used twitter as a channel of contact form more than 5 times?” */

SELECT
  ac.name,
  w.channel,
  COUNT(w.channel) AS freq
FROM `backwoodpaper_sql_tutorial.web_events` AS w
LEFT JOIN `backwoodpaper_sql_tutorial.accounts` AS ac
ON w.account_id=ac.id
GROUP BY 1, 2
HAVING w.channel='twitter' AND freq > 5
ORDER BY freq DESC

  
/* “I would like to know in which year did Backwoods Paper had the highest sales in terms of total number of orders.” */

SELECT
  EXTRACT(YEAR FROM occurred_at) AS year,
  SUM(standard_qty) AS total_standard,
  SUM(gloss_qty) AS total_gloss,
  SUM(poster_qty) AS total_poster,
  SUM(total) as total_qty
FROM `backwoodpaper_sql_tutorial.orders`
GROUP BY 1
ORDER BY 5 DESC
LIMIT 3

  
/* “I would like to know the top performing sales reps, which are sales reps associated with more than 
300 orders or more than 500,000 in total sales, in the middle group should be any sales rep with more than
200 orders or 350,000 in total sales, and any sales rep that doesn't fit the above should be in the low group.” */

SELECT
  s.id,
  s.name,
  COUNT(o.total) as total_orders,
  SUM(o.total_amt_usd) as total_sales,
  CASE
    WHEN COUNT(o.total) >= 300 OR SUM(o.total_amt_usd) >= 500000 THEN 'Top'
    WHEN COUNT(o.total) BETWEEN 200 AND 300 OR SUM(o.total_amt_usd) BETWEEN 350000 AND 500000 THEN 'Middle'
    ELSE 'Low'
END AS Performance
FROM `backwoodpaper_sql_tutorial.sales_reps` AS s
LEFT JOIN `backwoodpaper_sql_tutorial.accounts` as ac
ON s.id=ac.sales_rep_id
LEFT JOIN `backwoodpaper_sql_tutorial.orders` as o
ON ac.id=o.account_id
GROUP BY 1, 2
ORDER BY 5 DESC

  
/* “I would like to know the sales rep name in each region who has the largest amount of total sales in dollars.” */

SELECT 
  *
FROM (SELECT 
        s.name AS name,
        r.name AS region, 
        SUM(o.total_amt_usd) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.name ORDER BY SUM(o.total_amt_usd) DESC) AS region_sales_rank,
      FROM `backwoodpaper_sql_tutorial.orders` AS o
      JOIN `backwoodpaper_sql_tutorial.accounts` AS ac
        ON o.account_id=ac.id
      JOIN `backwoodpaper_sql_tutorial.sales_reps` AS s
        ON ac.sales_rep_id=s.id
      JOIN `backwoodpaper_sql_tutorial.region` AS r
        ON s.region_id=r.id
      GROUP BY 1, 2) AS com
WHERE region_sales_rank = 1
ORDER BY 3

  
/* “How many accounts had more more total purchases than the account name which has
bought the most standard_qty paper thorughout their lifetime as a customer?” */

WITH t1 AS (
      SELECT 
        o1.account_id AS account_id,
        SUM(o1.standard_qty) AS total_standard_qty,
        SUM(o1.total_amt_usd) AS accum_usd
      FROM `backwoodpaper_sql_tutorial.orders` AS o1
      GROUP BY account_id
      ),
t2 AS (
      SELECT
        MAX_BY(t1.accum_usd, t1.total_standard_qty) AS accum_usd_max_std
      FROM t1)

SELECT
  o2.account_id,
  SUM(o2.total_amt_usd) AS accum_usd2
FROM `backwoodpaper_sql_tutorial.orders` AS o2
GROUP BY 1
HAVING SUM(o2.total_amt_usd) > (SELECT accum_usd_max_std FROM t2);


/* “I would like to have the running total of the quantity of standar paper ordered so far.” */

SELECT
  occurred_at,
  standard_qty,
  DATE_TRUNC(occurred_at, MONTH) AS month,
  SUM(standard_qty) OVER (PARTITION BY DATE_TRUNC(occurred_at, MONTH) ORDER BY occurred_at) AS running_total
FROM `backwoodpaper_sql_tutorial.orders`

  
/* “I would like to know how much standard paper has each account purchased over another accounts” */

WITH sub AS(
      SELECT
        account_id,
        SUM(standard_qty) AS standard_sum
      FROM `backwoodpaper_sql_tutorial.orders`
      GROUP BY 1
)
SELECT
  account_id,
  standard_sum,
  LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag_value,
  standard_sum - LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag_difference
FROM sub
ORDER BY standard_sum  
