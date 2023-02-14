USE gdb023;
SELECT * FROM dim_product;

-- Q1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region?

SELECT distinct market FROM dim_customer 
WHERE customer='Atliq Exclusive' and region='APAC' ;

-- Q2. What is the percentage of unique product increase in 2021 vs. 2020?

with unique_2020 as(
	SELECT count(distinct product_code) as product_count_2020
	from fact_gross_price
	WHERE fiscal_year=2020),
unique_2021 as (
	SELECT count(distinct product_code) as product_count_2021
    from fact_gross_price
	WHERE fiscal_year=2021)    
SELECT x.product_count_2020,
		y.product_count_2021,
        ROUND(((y.product_count_2021-x.product_count_2020)/x.product_count_2020)*100,2) as percentage_change
FROM unique_2020 as x
inner join unique_2021 as y;

-- Q3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts?

SELECT segment,count(distinct product) as Product_Count from dim_product group by segment order by Product_Count desc;

-- Q4. Which segment had the most increase in unique products in 2021 vs 2020?

with product_count_2020 as(
	SELECT dp.segment,count(distinct dp.product_code) as product_count_20
	from dim_product dp
	inner join fact_gross_price fp
	on dp.product_code=fp.product_code
	where fp.fiscal_year=2020
	group by dp.segment
    order by product_count_20 desc),
product_count_2021 as (
		SELECT dp.segment,count(distinct dp.product_code) as product_count_21
		from dim_product dp
		inner join fact_gross_price f
		on dp.product_code=f.product_code
		where f.fiscal_year=2021
		group by dp.segment
        order by product_count_21 desc)
SELECT 	x.segment,
		x.product_count_20,
		y.product_count_21,
        (y.product_count_21-x.product_count_20) as difference,
        round(((y.product_count_21-x.product_count_20)/x.product_count_20)*100,2) as percent_difference
FROM product_count_2020 as x
inner join product_count_2021 as y
on x.segment=y.segment;

-- Q5. Get the products that have the highest and lowest manufacturing costs?

SELECT 
p.product,
p.product_code,
m.manufacturing_cost
FROM dim_product p
inner join fact_manufacturing_cost m
on p.product_code=m.product_code
WHERE manufacturing_cost=(SELECT max(manufacturing_cost) from fact_manufacturing_cost)
UNION
SELECT 
p.product,
p.product_code,
m.manufacturing_cost
FROM dim_product p
inner join fact_manufacturing_cost m
on p.product_code=m.product_code
WHERE manufacturing_cost=(SELECT min(manufacturing_cost) from fact_manufacturing_cost);

-- Q6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market?
 
 SELECT c.customer_code,
	c.customer,
	round(avg(i.pre_invoice_discount_pct),2) as avg_discount
FROM dim_customer c
inner join fact_pre_invoice_deductions i
on c.customer_code=i.customer_code
where fiscal_year=2021 and market='India'
group by customer_code,customer
order by avg_discount desc
LIMIT 5;

-- Q7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month?

SELECT month(date) as fmonth,Year(date) as fyear,
        round(sum(f.sold_quantity * m.gross_price),2) as Gross_sale_amount
FROM fact_sales_monthly f
INNER JOIN fact_gross_price m
ON f.product_code =m.product_code
INNER JOIN dim_customer c
ON f.customer_code=c.customer_code
group by fmonth,fyear
order by fyear;

-- Q8. In which quarter of 2020, got the maximum total_sold_quantity?

SELECT 
CASE 
	WHEN month(date) in (9,10,11) then 'qtr1'
    WHEN month(date) in (12,1,2) then 'qtr2'
    WHEN month(date) in (3,4,5) then 'qtr3'
    WHEN month(date) in (6,7,8) then 'qtr4'
END as Quarterno,
sum(sold_quantity) as total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year=2020
group by quarterNo
order by total_sold_quantity desc;

-- Q9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

WITH gross_sales AS(
	SELECT c.channel,
		ROUND(sum(m.sold_quantity * g.gross_price)/100000,2) as Gross_sales_in_mln
FROM dim_customer c
INNER JOIN fact_sales_monthly m
ON c.customer_code=m.customer_code
INNER JOIN fact_gross_price g
ON m.Product_code=g.product_code
WHERE m.fiscal_year=2021
GROUP BY c.channel
ORDER BY Gross_sales_in_mln desc)
SELECT *,
	Gross_sales_in_mln*100/sum(Gross_sales_in_mln) over() as Percentage
FROM gross_sales;

-- Q10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

WITH sold_quantity AS(
	SELECT p.division,p.product_code,p.product,
		   sum(m.sold_quantity) as Total_sold_quantity
FROM dim_product p
INNER JOIN fact_sales_monthly m
ON p.product_code=m.product_code
WHERE m.fiscal_year=2021
group by p.division,p.product_code,p.product),
	rank_order as (
		SELECT *, rank() over(partition by division order by Total_sold_quantity desc) as rnk 
        FROM sold_quantity)
SELECT *
FROM rank_order 
WHERE rnk <= 3;