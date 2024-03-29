/*
E-list

Conduct some analysis on E-list sales

*/

--1. Quarterly Trends for Macbooks sold in North America

--How are our Macbook products sales in North America doing and how has the trend changed?

--avg_orders:122.875
--avg_sales: 248,582.79
--avg_aov: 1,556.08

--CTE to get tidy data by counting the of number of orders, total sales, and average order value (AOV) by quarter
with quarterly_trends as (
	select 
		date_trunc(orders.purchase_ts, quarter) as purchase_quarter,
	  count(distinct orders.id) as order_count,
	  round(sum(orders.usd_price),2) as total_sales,
	  round(avg(orders.usd_price),2) as aov
	from 
		core.orders
	left join core.customers 							on orders.customer_id = customers.id
	left join core.geo_lookup geo_lookup 	on customers.country_code = geo_lookup.country
	where 
		lower(orders.product_name) like '%macbook%' 
		and region = 'NA'
	group by purchase_quarter
	order by purchase_quarter desc, total_sales
	)

select * from quarterly_trends

--this select statement gets the average orders, sales dollars, and average order value for the entire company

--select avg(order_count) as avg_orders, 
	--avg(total_sales) as avg_sales, 
	--avg(aov) as avg_aov
--from quarterly_trends;


--2. Time to Deliver products analysis 

--For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? Analyze the different regions to see which ones takes the longest to deliver a product to do further investigation to improve processes. 


/*
region time_to_deliver
EMEA 7.53
NA 7.52
LATAM 7.51
APAC 7.51
null 7.32

*/

select 
	geo_lookup.region, 
  avg(date_diff(order_status.delivery_ts, order_status.purchase_ts, day)) as time_to_deliver
from 
	core.order_status
	left join core.orders on order_status.order_id = orders.id
	left join core.customers on customers.id = orders.customer_id
	left join core.geo_lookup on geo_lookup.country = customers.country_code
where 
	(extract(year from orders.purchase_ts) = 2022
  and purchase_platform = 'website')
  or purchase_platform = 'mobile app'
group by 
	geo_lookup.region
order by 
	time_to_deliver desc

--3. Product Refund Analysis
--Are there certain products that are getting refunded more frequently than others? Find what products are getting refunded more frequently and see if they are worth continuing to sell in further analysis. 

/*
product_clean							refunds			refund_rate
ThinkPad Laptop							342			0.11728395061728381
Macbook Air Laptop						453			0.11427850655903178
Apple iPhone							22			0.0763888888888889
27in 4K gaming monitor						1444		0.061688311688311542
Apple Airpods Headphones					2636		0.054458309230642148
Samsung Webcam							186			0.02584410170904548
Samsung Charging Cable Pack					294			0.013410573370432872
bose soundsport headphones					0				0.0
*/
select 
	case when product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as product_clean,
    sum(case when refund_ts is not null then 1 else 0 end) as refunds,
    avg(case when refund_ts is not null then 1 else 0 end) as refund_rate
from core.orders 
	left join core.order_status on orders.id = order_status.order_id
group by product_clean
order by refund_rate desc;


--4. Most Popular Product by Region Analysis
--Find out what the most popular products are by region. This would be a good talking point for execs to prevent in the next town hall. 
/*
region	product_name	total_orders	order_ranking
APAC	Apple Airpods Headphones	5662	1
EMEA	Apple Airpods Headphones	15090	1
LATAM	Apple Airpods Headphones	2636	1
NA	Apple Airpods Headphones	24734	1
Apple Airpods Headphones	285	1

*/

with sales_by_product as (
  select 
	region,
  product_name,
  count(distinct orders.id) as total_orders
from core.orders
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup
  on geo_lookup.country = customers.country_code
group by region,product_name)

select *, 
	row_number() over (partition by region order by 	total_orders desc) as order_ranking
from sales_by_product
qualify row_number() over (partition by region order by total_orders desc) = 1;

/*Marketing Channel and Loyalty Program Analysis
Find out which marketing channel is the most sucessful in getting people to sign up for the loyalty program in terms of signup rate and total people signed up

This will allow for further analysis to see which marketing channels are performing the best and whether or not we should get rid of certain marketing channels and/or focus more efforts into certain marketing channels

marketing_channel	loyalty_signup_rate	loyalty_signup_count
unknown								0.79								52
email									0.58								9329
null									0.57								678
social media					0.5									568
direct								0.39							28274
affiliate							0.17								412

*/



select 
	marketing_channel,
  round(avg(loyalty_program),2) as loyalty_signup_rate,
  sum(loyalty_program) as loyalty_signup_count
from 
	core.customers
group by 
	marketing_channel
order by 
	loyalty_signup_rate desc






