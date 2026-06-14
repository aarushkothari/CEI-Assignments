-- ================================================================================
-- Celebal Excellence Internship 2026 
-- Week 3 Task: Advanced SQL (Subqueries, CTEs, and Window Functions)
-- File: solutions.sql
-- ================================================================================

-- ================================================================================
-- STEP 1: SETUP DATA & NORMALIZATION
-- ================================================================================

-- 1. Create the normalized tables

-- Customers Table
create table if not exists customers (
    customer_id   text primary key,
    customer_name text not null,
    segment       text not null
);

-- Products Table
CREATE TABLE IF NOT EXISTS products(
    product_id   TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    sub_category TEXT NOT NULL
);

-- Orders Table
create table if not exists orders (
    row_id      integer primary key,
    order_id    text not null,
    customer_id text not null,
    product_id  text not null,
    order_date  text not null,
    ship_date   text not null,
    ship_mode   text not null,
    sales       real not null,
    quantity    integer not null,
    discount    real not null,
    profit      real not null,
    foreign key (customer_id) references customers(customer_id),
    foreign key (product_id) references products(product_id)
);

-- 2. Populate tables using SELECT DISTINCT from superstore_raw

-- Insert into customers (uniquely by customer_id)
insert or ignore into customers (customer_id, customer_name, segment)
select distinct customer_id, customer_name, segment
from superstore_raw;

-- Insert into products (uniquely by product_id, choosing the latest product name)
INSERT OR IGNORE INTO products (product_id, product_name, category, sub_category)
SELECT product_id, product_name, category, sub_category
FROM (
    select product_id, product_name, category, sub_category,
           row_number() over (partition by product_id order by row_id desc) as rn
    from superstore_raw
)
WHERE rn = 1;

-- Insert into orders
insert or ignore into orders (row_id, order_id, customer_id, product_id, order_date, ship_date, ship_mode, sales, quantity, discount, profit)
select row_id, order_id, customer_id, product_id, order_date, ship_date, ship_mode, sales, quantity, discount, profit
from superstore_raw;


-- ================================================================================
-- STEP 2: PERFORMING REQUIRED QUERIES
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Q1. Find all orders where sales are greater than the average sales. (Subquery)
-- Logic: Group and sum sales by order_id to get order totals, then filter for those above the average of all order totals.
-- --------------------------------------------------------------------------------
with ord_totals as (
    select order_id, customer_id, sum(sales) as total_order_sales
    from orders
    group by order_id, customer_id
)
select order_id, customer_id, total_order_sales
from ord_totals
where total_order_sales > (select avg(total_order_sales) from ord_totals)
order by total_order_sales desc
limit 10;


-- --------------------------------------------------------------------------------
-- Q2. Find the highest sales order for each customer. (Subquery)
-- Logic: Group by customer and order to calculate order totals, then select the highest total for each customer using a correlated subquery.
-- --------------------------------------------------------------------------------
with ot_val as (
    select customer_id, order_id, sum(sales) as total_order_sales
    from orders
    group by customer_id, order_id
)
select ot1.customer_id, c.customer_name, ot1.order_id, ot1.total_order_sales
from ot_val ot1
join customers c on ot1.customer_id = c.customer_id
where ot1.total_order_sales = (
    select max(ot2.total_order_sales)
    from ot_val ot2
    where ot2.customer_id = ot1.customer_id
)
order by ot1.total_order_sales desc
limit 10;


-- --------------------------------------------------------------------------------
-- Q3. Calculate total sales for each customer. (CTE)
-- Logic: Calculate total sales per customer in a CTE, then join with customers to display their names.
-- --------------------------------------------------------------------------------
with cust_sales_cte as (
    select customer_id, sum(sales) as total_sales
    from orders
    group by customer_id
)
select cs.customer_id, c.customer_name, cs.total_sales
from cust_sales_cte cs
join customers c on cs.customer_id = c.customer_id
order by cs.total_sales desc
limit 10;


-- --------------------------------------------------------------------------------
-- Q4. Find customers whose total sales are above average. (CTE + Subquery)
-- Logic: Calculate total sales per customer in a CTE, then use a subquery to filter for those whose sales exceed the average customer sales.
-- --------------------------------------------------------------------------------
with cust_tot as (
    select customer_id, sum(sales) as total_sales
    from orders
    group by customer_id
)
select ct.customer_id, c.customer_name, ct.total_sales
from cust_tot ct
join customers c on ct.customer_id = c.customer_id
where ct.total_sales > (select avg(total_sales) from cust_tot)
order by ct.total_sales desc
limit 10;


-- --------------------------------------------------------------------------------
-- Q5. Rank all customers based on total sales. (Window Function)
-- Logic: Calculate total sales per customer in a CTE, then apply ROW_NUMBER(), RANK(), and DENSE_RANK() ordered by sales desc.
-- --------------------------------------------------------------------------------
with c_rank as (
    select customer_id, sum(sales) as total_sales
    from orders
    group by customer_id
)
select c.customer_name, cr.total_sales,
       row_number() over (order by cr.total_sales desc) as row_num,
       rank() over (order by cr.total_sales desc) as sales_rank,
       dense_rank() over (order by cr.total_sales desc) as sales_dense_rank
from c_rank cr
join customers c on cr.customer_id = c.customer_id
limit 10;


-- --------------------------------------------------------------------------------
-- Q6. Assign row numbers to each order within a customer. (Window Function + PARTITION BY)
-- Logic: Get unique order IDs per customer inside a CTE, then apply ROW_NUMBER() partitioned by customer and ordered by date.
-- --------------------------------------------------------------------------------
with uniq_ord as (
    select distinct customer_id, order_id, order_date
    from orders
)
select u.customer_id, c.customer_name, u.order_id, u.order_date,
       row_number() over (partition by u.customer_id order by u.order_date asc, u.order_id asc) as order_seq_num
from uniq_ord u
join customers c on u.customer_id = c.customer_id
order by u.customer_id, order_seq_num
limit 15;


-- --------------------------------------------------------------------------------
-- Q7. Display top 3 customers based on total sales. (Window Function)
-- Logic: Calculate customer sales and ranks in a CTE, then filter for ranks 1, 2, and 3.
-- --------------------------------------------------------------------------------
with rank_cte as (
    select customer_id, sum(sales) as total_sales,
           dense_rank() over (order by sum(sales) desc) as sales_rank
    from orders
    group by customer_id
)
select c.customer_name, rc.total_sales, rc.sales_rank
from rank_cte rc
join customers c on rc.customer_id = c.customer_id
where rc.sales_rank <= 3;


-- ================================================================================
-- STEP 3: FINAL COMBINED QUERY
-- Logic: Combine CTE, JOIN, and DENSE_RANK() in a single statement to get customer sales rankings.
-- ================================================================================

-- Display Customer Name, Total Sales, and Rank using JOIN + CTE + Window Function
with combined_cte as (
    select customer_id, sum(sales) as total_sales
    from orders
    group by customer_id
)
select c.customer_name, cc.total_sales,
       dense_rank() over (order by cc.total_sales desc) as sales_rank
from combined_cte cc
join customers c on cc.customer_id = c.customer_id
order by sales_rank asc
limit 10;


-- ================================================================================
-- MINI PROJECT: CUSTOMER SALES INSIGHTS
-- ================================================================================

-- 1. Who are the top 5 customers?
-- Logic: Rank customers by sales descending and filter for rank <= 5.
with top_ranks as (
    select customer_id, sum(sales) as total_sales,
           dense_rank() over (order by sum(sales) desc) as sales_rank
    from orders
    group by customer_id
)
select c.customer_name, tr.total_sales, tr.sales_rank
from top_ranks tr
join customers c on tr.customer_id = c.customer_id
where tr.sales_rank <= 5;

-- 2. Who are the bottom 5 customers?
-- Logic: Rank customers by sales ascending and filter for rank <= 5.
with bottom_ranks as (
    select customer_id, sum(sales) as total_sales,
           dense_rank() over (order by sum(sales) asc) as sales_rank
    from orders
    group by customer_id
)
select c.customer_name, br.total_sales, br.sales_rank
from bottom_ranks br
join customers c on br.customer_id = c.customer_id
where br.sales_rank <= 5;

-- 3. Which customers made only one order?
-- Logic: Group orders by customer, count distinct order IDs, and filter for total = 1.
select c.customer_name, count(distinct o.order_id) as total_orders
from orders o
join customers c on o.customer_id = c.customer_id
group by o.customer_id
having count(distinct o.order_id) = 1
order by c.customer_name asc
limit 10;

-- 4. Which customers have above-average sales? (Total sales > average customer sales)
-- Logic: Filter customers whose total sales are greater than the average customer sales.
with avg_cust as (
    select customer_id, sum(sales) as total_sales
    from orders
    group by customer_id
)
select ac.customer_id, c.customer_name, ac.total_sales
from avg_cust ac
join customers c on ac.customer_id = c.customer_id
where ac.total_sales > (select avg(total_sales) from avg_cust)
order by ac.total_sales desc
limit 10;

-- 5. What is the highest order value per customer?
-- Logic: Group by order to find totals, then find the max order total per customer.
with ord_sums as (
    select customer_id, order_id, sum(sales) as total_order_sales
    from orders
    group by customer_id, order_id
)
select c.customer_name, max(os.total_order_sales) as highest_order_value
from ord_sums os
join customers c on os.customer_id = c.customer_id
group by os.customer_id
order by highest_order_value desc
limit 10;
