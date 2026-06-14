# Assignment 3 - SQL Query Results

This document contains the execution output of all SQL queries in `solutions.sql` run against the normalized SQLite database `assignment3.db`.


## STEP 1: SETUP DATA & NORMALIZATION


## STEP 2: PERFORMING REQUIRED QUERIES

### Q1. Find all orders where sales are greater than the average sales. (Subquery)
*Group and sum sales by order_id to get order totals, then filter for those above the average of all order totals.*

```sql
with ord_totals as (
    select order_id, customer_id, sum(sales) as total_order_sales
    from orders
    group by order_id, customer_id
)
select order_id, customer_id, total_order_sales
from ord_totals
where total_order_sales > (select avg(total_order_sales) from ord_totals)
order by total_order_sales desc
limit 10
```

| order_id       | customer_id   | total_order_sales   |
|:---------------|:--------------|:--------------------|
| CA-2014-145317 | SM-20320      | 23661.228           |
| CA-2016-118689 | TC-20980      | 18336.74            |
| CA-2017-140151 | RB-19360      | 14052.48            |
| CA-2017-127180 | TA-21385      | 13716.458           |
| CA-2014-139892 | BM-11140      | 10539.896           |
| CA-2017-166709 | HL-15040      | 10499.97            |
| CA-2014-116904 | SC-20095      | 9900.19             |
| CA-2016-117121 | AB-10105      | 9892.74             |
| US-2016-107440 | BS-11365      | 9135.19             |
| CA-2016-158841 | SE-20110      | 8805.04             |


### Q2. Find the highest sales order for each customer. (Subquery)
*Group by customer and order to calculate order totals, then select the highest total for each customer using a correlated subquery.*

```sql
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
limit 10
```

| customer_id   | customer_name   | order_id       | total_order_sales   |
|:--------------|:----------------|:---------------|:--------------------|
| SM-20320      | Sean Miller     | CA-2014-145317 | 23661.228           |
| TC-20980      | Tamara Chand    | CA-2016-118689 | 18336.74            |
| RB-19360      | Raymond Buch    | CA-2017-140151 | 14052.48            |
| TA-21385      | Tom Ashbrook    | CA-2017-127180 | 13716.458           |
| BM-11140      | Becky Martin    | CA-2014-139892 | 10539.896           |
| HL-15040      | Hunter Lopez    | CA-2017-166709 | 10499.97            |
| SC-20095      | Sanjit Chand    | CA-2014-116904 | 9900.19             |
| AB-10105      | Adrian Barton   | CA-2016-117121 | 9892.74             |
| BS-11365      | Bill Shonely    | US-2016-107440 | 9135.19             |
| SE-20110      | Sanjit Engle    | CA-2016-158841 | 8805.04             |


### Q3. Calculate total sales for each customer. (CTE)
*Calculate total sales per customer in a CTE, then join with customers to display their names.*

```sql
with cust_sales_cte as (
    select customer_id, sum(sales) as total_sales
    from orders
    group by customer_id
)
select cs.customer_id, c.customer_name, cs.total_sales
from cust_sales_cte cs
join customers c on cs.customer_id = c.customer_id
order by cs.total_sales desc
limit 10
```

| customer_id   | customer_name      | total_sales   |
|:--------------|:-------------------|:--------------|
| SM-20320      | Sean Miller        | 25043.05      |
| TC-20980      | Tamara Chand       | 19052.218     |
| RB-19360      | Raymond Buch       | 15117.339     |
| TA-21385      | Tom Ashbrook       | 14595.62      |
| AB-10105      | Adrian Barton      | 14473.571     |
| KL-16645      | Ken Lonsdale       | 14175.229     |
| SC-20095      | Sanjit Chand       | 14142.334     |
| HL-15040      | Hunter Lopez       | 12873.298     |
| SE-20110      | Sanjit Engle       | 12209.438     |
| CC-12370      | Christopher Conant | 12129.072     |


### Q4. Find customers whose total sales are above average. (CTE + Subquery)
*Calculate total sales per customer in a CTE, then use a subquery to filter for those whose sales exceed the average customer sales.*

```sql
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
limit 10
```

| customer_id   | customer_name      | total_sales   |
|:--------------|:-------------------|:--------------|
| SM-20320      | Sean Miller        | 25043.05      |
| TC-20980      | Tamara Chand       | 19052.218     |
| RB-19360      | Raymond Buch       | 15117.339     |
| TA-21385      | Tom Ashbrook       | 14595.62      |
| AB-10105      | Adrian Barton      | 14473.571     |
| KL-16645      | Ken Lonsdale       | 14175.229     |
| SC-20095      | Sanjit Chand       | 14142.334     |
| HL-15040      | Hunter Lopez       | 12873.298     |
| SE-20110      | Sanjit Engle       | 12209.438     |
| CC-12370      | Christopher Conant | 12129.072     |


### Q5. Rank all customers based on total sales. (Window Function)
*Calculate total sales per customer in a CTE, then apply ROW_NUMBER(), RANK(), and DENSE_RANK() ordered by sales desc.*

```sql
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
limit 10
```

| customer_name      | total_sales   | row_num   | sales_rank   | sales_dense_rank   |
|:-------------------|:--------------|:----------|:-------------|:-------------------|
| Sean Miller        | 25043.05      | 1         | 1            | 1                  |
| Tamara Chand       | 19052.218     | 2         | 2            | 2                  |
| Raymond Buch       | 15117.339     | 3         | 3            | 3                  |
| Tom Ashbrook       | 14595.62      | 4         | 4            | 4                  |
| Adrian Barton      | 14473.571     | 5         | 5            | 5                  |
| Ken Lonsdale       | 14175.229     | 6         | 6            | 6                  |
| Sanjit Chand       | 14142.334     | 7         | 7            | 7                  |
| Hunter Lopez       | 12873.298     | 8         | 8            | 8                  |
| Sanjit Engle       | 12209.438     | 9         | 9            | 9                  |
| Christopher Conant | 12129.072     | 10        | 10           | 10                 |


### Q6. Assign row numbers to each order within a customer. (Window Function + PARTITION BY)
*Get unique order IDs per customer inside a CTE, then apply ROW_NUMBER() partitioned by customer and ordered by date.*

```sql
with uniq_ord as (
    select distinct customer_id, order_id, order_date
    from orders
)
select u.customer_id, c.customer_name, u.order_id, u.order_date,
       row_number() over (partition by u.customer_id order by u.order_date asc, u.order_id asc) as order_seq_num
from uniq_ord u
join customers c on u.customer_id = c.customer_id
order by u.customer_id, order_seq_num
limit 15
```

| customer_id   | customer_name   | order_id       | order_date   | order_seq_num   |
|:--------------|:----------------|:---------------|:-------------|:----------------|
| AA-10315      | Alex Avila      | CA-2014-128055 | 2014-03-31   | 1               |
| AA-10315      | Alex Avila      | CA-2014-138100 | 2014-09-15   | 2               |
| AA-10315      | Alex Avila      | CA-2015-121391 | 2015-10-04   | 3               |
| AA-10315      | Alex Avila      | CA-2016-103982 | 2016-03-03   | 4               |
| AA-10315      | Alex Avila      | CA-2017-147039 | 2017-06-29   | 5               |
| AA-10375      | Allen Armold    | CA-2014-158064 | 2014-04-21   | 1               |
| AA-10375      | Allen Armold    | CA-2014-130729 | 2014-10-24   | 2               |
| AA-10375      | Allen Armold    | CA-2015-140921 | 2015-02-03   | 3               |
| AA-10375      | Allen Armold    | CA-2015-109939 | 2015-05-08   | 4               |
| AA-10375      | Allen Armold    | CA-2015-114503 | 2015-11-13   | 5               |
| AA-10375      | Allen Armold    | CA-2016-126613 | 2016-07-10   | 6               |
| AA-10375      | Allen Armold    | CA-2016-131065 | 2016-11-14   | 7               |
| AA-10375      | Allen Armold    | US-2017-169488 | 2017-09-07   | 8               |
| AA-10375      | Allen Armold    | CA-2017-100230 | 2017-12-11   | 9               |
| AA-10480      | Andrew Allen    | CA-2014-155271 | 2014-05-04   | 1               |


### Q7. Display top 3 customers based on total sales. (Window Function)
*Calculate customer sales and ranks in a CTE, then filter for ranks 1, 2, and 3.*

```sql
with rank_cte as (
    select customer_id, sum(sales) as total_sales,
           dense_rank() over (order by sum(sales) desc) as sales_rank
    from orders
    group by customer_id
)
select c.customer_name, rc.total_sales, rc.sales_rank
from rank_cte rc
join customers c on rc.customer_id = c.customer_id
where rc.sales_rank <= 3
```

| customer_name   | total_sales   | sales_rank   |
|:----------------|:--------------|:-------------|
| Sean Miller     | 25043.05      | 1            |
| Tamara Chand    | 19052.218     | 2            |
| Raymond Buch    | 15117.339     | 3            |



## STEP 3: FINAL COMBINED QUERY

### STEP 3: FINAL COMBINED QUERY Display Customer Name, Total Sales, and Rank using JOIN + CTE + Window Function
*Combine CTE, JOIN, and DENSE_RANK() in a single statement to get customer sales rankings.*

```sql
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
limit 10
```

| customer_name      | total_sales   | sales_rank   |
|:-------------------|:--------------|:-------------|
| Sean Miller        | 25043.05      | 1            |
| Tamara Chand       | 19052.218     | 2            |
| Raymond Buch       | 15117.339     | 3            |
| Tom Ashbrook       | 14595.62      | 4            |
| Adrian Barton      | 14473.571     | 5            |
| Ken Lonsdale       | 14175.229     | 6            |
| Sanjit Chand       | 14142.334     | 7            |
| Hunter Lopez       | 12873.298     | 8            |
| Sanjit Engle       | 12209.438     | 9            |
| Christopher Conant | 12129.072     | 10           |



## MINI PROJECT: CUSTOMER SALES INSIGHTS

### MINI PROJECT: CUSTOMER SALES INSIGHTS 1. Who are the top 5 customers?
*Rank customers by sales descending and filter for rank <= 5.*

```sql
with top_ranks as (
    select customer_id, sum(sales) as total_sales,
           dense_rank() over (order by sum(sales) desc) as sales_rank
    from orders
    group by customer_id
)
select c.customer_name, tr.total_sales, tr.sales_rank
from top_ranks tr
join customers c on tr.customer_id = c.customer_id
where tr.sales_rank <= 5
```

| customer_name   | total_sales   | sales_rank   |
|:----------------|:--------------|:-------------|
| Sean Miller     | 25043.05      | 1            |
| Tamara Chand    | 19052.218     | 2            |
| Raymond Buch    | 15117.339     | 3            |
| Tom Ashbrook    | 14595.62      | 4            |
| Adrian Barton   | 14473.571     | 5            |


### 2. Who are the bottom 5 customers?
*Rank customers by sales ascending and filter for rank <= 5.*

```sql
with bottom_ranks as (
    select customer_id, sum(sales) as total_sales,
           dense_rank() over (order by sum(sales) asc) as sales_rank
    from orders
    group by customer_id
)
select c.customer_name, br.total_sales, br.sales_rank
from bottom_ranks br
join customers c on br.customer_id = c.customer_id
where br.sales_rank <= 5
```

| customer_name   | total_sales   | sales_rank   |
|:----------------|:--------------|:-------------|
| Thais Sissman   | 4.833         | 1            |
| Lela Donovan    | 5.304         | 2            |
| Carl Jackson    | 16.52         | 3            |
| Mitch Gastineau | 16.739        | 4            |
| Roy Skaria      | 22.328        | 5            |


### 3. Which customers made only one order?
*Group orders by customer, count distinct order IDs, and filter for total = 1.*

```sql
select c.customer_name, count(distinct o.order_id) as total_orders
from orders o
join customers c on o.customer_id = c.customer_id
group by o.customer_id
having count(distinct o.order_id) = 1
order by c.customer_name asc
limit 10
```

| customer_name     | total_orders   |
|:------------------|:---------------|
| Anemone Ratner    | 1              |
| Anthony O'Donnell | 1              |
| Carl Jackson      | 1              |
| Jenna Caffey      | 1              |
| Jocasta Rupert    | 1              |
| Lela Donovan      | 1              |
| Mitch Gastineau   | 1              |
| Patricia Hirasaki | 1              |
| Ricardo Emerson   | 1              |
| Roland Murray     | 1              |


### 4. Which customers have above-average sales? (Total sales > average customer sales)
*Filter customers whose total sales are greater than the average customer sales.*

```sql
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
limit 10
```

| customer_id   | customer_name      | total_sales   |
|:--------------|:-------------------|:--------------|
| SM-20320      | Sean Miller        | 25043.05      |
| TC-20980      | Tamara Chand       | 19052.218     |
| RB-19360      | Raymond Buch       | 15117.339     |
| TA-21385      | Tom Ashbrook       | 14595.62      |
| AB-10105      | Adrian Barton      | 14473.571     |
| KL-16645      | Ken Lonsdale       | 14175.229     |
| SC-20095      | Sanjit Chand       | 14142.334     |
| HL-15040      | Hunter Lopez       | 12873.298     |
| SE-20110      | Sanjit Engle       | 12209.438     |
| CC-12370      | Christopher Conant | 12129.072     |


### 5. What is the highest order value per customer?
*Group by order to find totals, then find the max order total per customer.*

```sql
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
limit 10
```

| customer_name   | highest_order_value   |
|:----------------|:----------------------|
| Sean Miller     | 23661.228             |
| Tamara Chand    | 18336.74              |
| Raymond Buch    | 14052.48              |
| Tom Ashbrook    | 13716.458             |
| Becky Martin    | 10539.896             |
| Hunter Lopez    | 10499.97              |
| Sanjit Chand    | 9900.19               |
| Adrian Barton   | 9892.74               |
| Bill Shonely    | 9135.19               |
| Sanjit Engle    | 8805.04               |

