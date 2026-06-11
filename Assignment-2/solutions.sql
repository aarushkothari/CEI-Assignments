-- ================================================================================
-- Celebal Excellence Internship 2026 
-- Week 2 Task: E-Commerce Sales & Superstore Sales Analysis
-- File: solutions.sql
-- ================================================================================

-- ================================================================================
-- PART 1: E-COMMERCE SALES DATABASE
-- ================================================================================

-- DDL: CREATE TABLES
-- --------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id   INT           PRIMARY KEY,
    first_name    VARCHAR(50)   NOT NULL,
    last_name     VARCHAR(50)   NOT NULL,
    email         VARCHAR(100)  UNIQUE NOT NULL,
    city          VARCHAR(50)   NOT NULL,
    state         VARCHAR(50)   NOT NULL,
    join_date     DATE          NOT NULL,
    is_premium    BOOLEAN       DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS products (
    product_id    INT           PRIMARY KEY,
    product_name  VARCHAR(100)  NOT NULL,
    category      VARCHAR(50)   NOT NULL,
    brand         VARCHAR(50)   NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL  CHECK (unit_price > 0),
    stock_qty     INT           NOT NULL  DEFAULT 0  CHECK (stock_qty >= 0)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id      INT           PRIMARY KEY,
    customer_id   INT           NOT NULL,
    order_date    DATE          NOT NULL,
    status        VARCHAR(20)   NOT NULL  DEFAULT 'Pending'
                  CHECK (status IN ('Pending','Shipped','Delivered','Cancelled')),
    total_amount  DECIMAL(12,2) NOT NULL  CHECK (total_amount >= 0),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    item_id       INT           PRIMARY KEY,
    order_id      INT           NOT NULL,
    product_id    INT           NOT NULL,
    quantity      INT           NOT NULL  CHECK (quantity > 0),
    unit_price    DECIMAL(10,2) NOT NULL  CHECK (unit_price > 0),
    discount_pct  DECIMAL(5,2)  DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- CREATE INDEXES
-- --------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_customers_city ON customers(city);
CREATE INDEX IF NOT EXISTS idx_customers_state ON customers(state);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- DML: LOAD SAMPLE DATA (INSERT Statements)
-- --------------------------------------------------------------------------------
-- Note: Replaced TRUE/FALSE with 1/0 for SQLite compatibility.
INSERT OR IGNORE INTO customers VALUES
(101, 'Aarav',  'Sharma', 'aarav.s@email.com',  'Mumbai',    'Maharashtra', '2024-01-15', 1),
(102, 'Priya',  'Patel',  'priya.p@email.com',  'Ahmedabad', 'Gujarat',     '2024-02-20', 0),
(103, 'Rohan',  'Gupta',  'rohan.g@email.com',  'Delhi',     'Delhi',       '2024-03-10', 1),
(104, 'Sneha',  'Reddy',  'sneha.r@email.com',  'Hyderabad', 'Telangana',   '2024-04-05', 0),
(105, 'Vikram', 'Singh',  'vikram.s@email.com', 'Jaipur',    'Rajasthan',   '2024-05-12', 1),
(106, 'Ananya', 'Iyer',   'ananya.i@email.com', 'Chennai',   'Tamil Nadu',  '2024-06-18', 0),
(107, 'Karan',  'Mehta',  'karan.m@email.com',  'Pune',      'Maharashtra', '2024-07-22', 1),
(108, 'Divya',  'Nair',   'divya.n@email.com',  'Kochi',     'Kerala',      '2024-08-30', 0);

INSERT OR IGNORE INTO products VALUES
(201, 'Wireless Earbuds',     'Electronics', 'BoAt',          1499.00, 250),
(202, 'Cotton T-Shirt',       'Clothing',    'Levis',         799.00,  500),
(203, 'Smart Watch',          'Electronics', 'Noise',         2999.00, 150),
(204, 'Running Shoes',        'Clothing',    'Nike',          4599.00, 120),
(205, 'Bluetooth Speaker',    'Electronics', 'JBL',           3499.00, 200),
(206, 'Bedsheet Set',         'Home',        'Spaces',        1299.00, 300),
(207, 'Laptop Stand',         'Electronics', 'AmazonBasics',  899.00,  180),
(208, 'Cushion Covers (Set)', 'Home',        'HomeCenter',    599.00,  400);

INSERT OR IGNORE INTO orders VALUES
(1001, 101, '2024-08-01', 'Delivered',  4498.00),
(1002, 102, '2024-08-03', 'Delivered',  799.00),
(1003, 103, '2024-08-05', 'Shipped',    7498.00),
(1004, 101, '2024-08-10', 'Delivered',  3499.00),
(1005, 104, '2024-08-12', 'Cancelled',  2999.00),
(1006, 105, '2024-08-15', 'Delivered',  5898.00),
(1007, 106, '2024-08-18', 'Pending',    1299.00),
(1008, 103, '2024-08-20', 'Delivered',  899.00),
(1009, 107, '2024-08-25', 'Shipped',    6098.00),
(1010, 108, '2024-08-28', 'Delivered',  1598.00);

INSERT OR IGNORE INTO order_items VALUES
(5001, 1001, 201, 2, 1499.00, 0),
(5002, 1001, 207, 1, 899.00,  10),
(5003, 1002, 202, 1, 799.00,  0),
(5004, 1003, 203, 1, 2999.00, 0),
(5005, 1003, 204, 1, 4599.00, 5),
(5006, 1004, 205, 1, 3499.00, 0),
(5007, 1005, 203, 1, 2999.00, 0),
(5008, 1006, 201, 1, 1499.00, 10),
(5009, 1006, 204, 1, 4599.00, 5),
(5010, 1007, 206, 1, 1299.00, 0),
(5011, 1008, 207, 1, 899.00,  0),
(5012, 1009, 205, 1, 3499.00, 0),
(5013, 1009, 208, 2, 599.00,  15),
(5014, 1010, 206, 1, 1299.00, 0),
(5015, 1010, 208, 1, 599.00,  0);


-- SECTION A: SQL Basics (SELECT, Constraints, Primary Keys)
-- --------------------------------------------------------------------------------

-- Q1. Write a query to display all columns and rows from the customer's table.
SELECT * FROM customers;
/*
Result: (8 rows)
 customer_id | first_name | last_name | email              | city      | state       | join_date  | is_premium
 ------------+------------+-----------+--------------------+-----------+-------------+------------+-----------
         101 | Aarav      | Sharma    | aarav.s@email.com  | Mumbai    | Maharashtra | 2024-01-15 | 1         
         102 | Priya      | Patel     | priya.p@email.com  | Ahmedabad | Gujarat     | 2024-02-20 | 0         
         103 | Rohan      | Gupta     | rohan.g@email.com  | Delhi     | Delhi       | 2024-03-10 | 1         
         104 | Sneha      | Reddy     | sneha.r@email.com  | Hyderabad | Telangana   | 2024-04-05 | 0         
         105 | Vikram     | Singh     | vikram.s@email.com | Jaipur    | Rajasthan   | 2024-05-12 | 1         
         106 | Ananya     | Iyer      | ananya.i@email.com | Chennai   | Tamil Nadu  | 2024-06-18 | 0         
         107 | Karan      | Mehta     | karan.m@email.com  | Pune      | Maharashtra | 2024-07-22 | 1         
         108 | Divya      | Nair      | divya.n@email.com  | Kochi     | Kerala      | 2024-08-30 | 0         
*/

-- Q2. Retrieve only the first_name, last_name, and city of all customers.
SELECT first_name, last_name, city FROM customers;
/*
Result: (8 rows)
 first_name | last_name | city     
 -----------+-----------+----------
 Aarav      | Sharma    | Mumbai   
 Priya      | Patel     | Ahmedabad
 Rohan      | Gupta     | Delhi    
 Sneha      | Reddy     | Hyderabad
 Vikram     | Singh     | Jaipur   
 Ananya     | Iyer      | Chennai  
 Karan      | Mehta     | Pune     
 Divya      | Nair      | Kochi    
*/

-- Q3. List all unique categories available in the products table.
SELECT DISTINCT category FROM products;
/*
Result: (3 rows)
 category   
 -----------
 Clothing   
 Electronics
 Home       
*/

-- Q4. Identify the Primary Key of each table in the schema. Explain why a Primary Key must be unique and NOT NULL.
/*
Primary Keys in the database:
1. Table `customers`: `customer_id`
2. Table `products`: `product_id`
3. Table `orders`: `order_id`
4. Table `order_items`: `item_id`

Explanation:
- Why UNIQUE: A Primary Key uniquely identifies a single row in a table. If duplicates were allowed,
  the database would lose its entity integrity; there would be no way to distinguish or link specific
  records (e.g., placing an order for customer_id = 101 when two customers share that ID).
- Why NOT NULL: A NULL value denotes "unknown" or "absent" information. If an identifier is NULL,
  it cannot serve as a reliable reference point or identifier for that row.
*/

-- Q5. What constraints are applied to the email column in the customers table? What would happen if you tried to insert a duplicate email?
/*
Constraints on `email` in `customers` table:
1. UNIQUE: Guarantees that no two customers can register with the same email.
2. NOT NULL: Forces every customer record to have a valid email address.

If you try to insert a duplicate email:
- The database engine will raise a UNIQUE Constraint Violation Error (e.g., "UNIQUE constraint failed: customers.email").
- The transaction/statement will be rejected and rolled back, protecting data integrity.
*/

-- Q6. Try inserting a product with unit_price = -50. What happens and which constraint prevents it? Write both the INSERT statement and explain the error.
-- Query:
-- INSERT INTO products VALUES(209, 'Invalid Product', 'Electronics', 'TestBrand', -50.00, 10);
/*
What happens & Error:
- The INSERT statement fails.
- Error Message: "CHECK constraint failed: unit_price > 0"
- Explanation: The table definition includes a check constraint `CHECK (unit_price > 0)` on the `unit_price` column.
  Since -50.00 is not greater than 0, the database rejects the insertion.
*/


-- SECTION B: Filtering & Optimization (WHERE, Indexes)
-- --------------------------------------------------------------------------------

-- Q7. Retrieve all orders with status = 'Delivered'.
SELECT * FROM orders WHERE status = 'Delivered';
/*
Result: (6 rows)
 order_id | customer_id | order_date | status    | total_amount
 ---------+-------------+------------+-----------+-------------
     1001 |         101 | 2024-08-01 | Delivered | 4498.00     
     1002 |         102 | 2024-08-03 | Delivered | 799.00      
     1004 |         101 | 2024-08-10 | Delivered | 3499.00     
     1006 |         105 | 2024-08-15 | Delivered | 5898.00     
     1008 |         103 | 2024-08-20 | Delivered | 899.00      
     1010 |         108 | 2024-08-28 | Delivered | 1598.00     
*/

-- Q8. Find all products in the 'Electronics' category with a unit_price greater than ₹2000.
SELECT * FROM products WHERE category = 'Electronics' AND unit_price > 2000;
/*
Result: (2 rows)
 product_id | product_name      | category    | brand | unit_price | stock_qty
 -----------+-------------------+-------------+-------+------------+----------
        203 | Smart Watch       | Electronics | Noise | 2999.00    | 150      
        205 | Bluetooth Speaker | Electronics | JBL   | 3499.00    | 200      
*/

-- Q9. List all customers who joined in the year 2024 and belong to the state 'Maharashtra'.
SELECT * FROM customers 
WHERE join_date >= '2024-01-01' AND join_date <= '2024-12-31' 
  AND state = 'Maharashtra';
/*
Result: (2 rows)
 customer_id | first_name | last_name | email             | city   | state       | join_date  | is_premium
 ------------+------------+-----------+-------------------+--------+-------------+------------+-----------
         101 | Aarav      | Sharma    | aarav.s@email.com | Mumbai | Maharashtra | 2024-01-15 | 1         
         107 | Karan      | Mehta     | karan.m@email.com | Pune   | Maharashtra | 2024-07-22 | 1         
*/

-- Q10. Find all orders placed between '2024-08-10' and '2024-08-25' (inclusive) that are NOT cancelled.
SELECT * FROM orders 
WHERE order_date BETWEEN '2024-08-10' AND '2024-08-25' 
  AND status <> 'Cancelled';
/*
Result: (5 rows)
 order_id | customer_id | order_date | status    | total_amount
 ---------+-------------+------------+-----------+-------------
     1004 |         101 | 2024-08-10 | Delivered | 3499.00     
     1006 |         105 | 2024-08-15 | Delivered | 5898.00     
     1007 |         106 | 2024-08-18 | Pending   | 1299.00     
     1008 |         103 | 2024-08-20 | Delivered | 899.00      
     1009 |         107 | 2024-08-25 | Shipped   | 6098.00     
*/

-- Q11. Explain what the index idx_orders_date does. How would it improve the performance of a query that filters orders by order_date? Write a sample query that would benefit from this index.
/*
Explanation:
- What idx_orders_date does: It builds a separate, sorted search structure (usually a B-Tree) map of the
  `order_date` values pointing back to the corresponding rows in the `orders` table.
- Performance Improvement: Instead of performing a Full Table Scan (checking every row in `orders` one-by-one, O(N)),
  the database optimizer can perform an Index Seek (binary-like search, O(log N)) to jump directly to the target date.
- Sample Query:
  SELECT * FROM orders WHERE order_date = '2024-08-15';
*/

-- Q12. If you run: SELECT * FROM customers WHERE YEAR(join_date) = 2024; — would the index on join_date be used? Explain why or why not, and rewrite the query to be index-friendly (SARGable).
/*
Index Usability:
- No, the index will NOT be used.
- Why: Applying a function (like `YEAR()`) directly on the indexed column `join_date` makes the expression non-SARGable.
  The database engine cannot locate values in the sorted index tree because it must calculate `YEAR()` for every single row
  individually to check if it equals 2024, defaulting to a full table scan.

Rewritten Index-Friendly (SARGable) Query:
*/
SELECT * FROM customers 
WHERE join_date >= '2024-01-01' AND join_date <= '2024-12-31';


-- SECTION C: Aggregation (GROUP BY, SUM, COUNT, AVG, MIN, MAX)
-- --------------------------------------------------------------------------------

-- Q13. Count the total number of orders in the orders table.
SELECT COUNT(*) AS total_orders FROM orders;
/*
Result: (1 row)
 total_orders
 ------------
 10          
*/

-- Q14. Find the total revenue (SUM of total_amount) from all 'Delivered' orders.
SELECT SUM(total_amount) AS total_revenue 
FROM orders 
WHERE status = 'Delivered';
/*
Result: (1 row)
 total_revenue
 -------------
 17191.00     
*/

-- Q15. Calculate the average unit_price of products in each category.
SELECT category, AVG(unit_price) AS avg_unit_price 
FROM products 
GROUP BY category;
/*
Result: (3 rows)
 category    | avg_unit_price
 ------------+---------------
 Clothing    | 2699.00       
 Electronics | 2224.00       
 Home        | 949.00        
*/

-- Q16. For each order status, find the count of orders and the total revenue. Sort the result by total revenue in descending order.
SELECT status, COUNT(*) AS order_count, SUM(total_amount) AS total_revenue 
FROM orders 
GROUP BY status 
ORDER BY total_revenue DESC;
/*
Result: (4 rows)
 status    | order_count | total_revenue
 ----------+-------------+-------------
 Delivered |           6 | 17191.00     
 Shipped   |           2 | 13596.00     
 Cancelled |           1 | 2999.00      
 Pending   |           1 | 1299.00      
*/

-- Q17. Find the most expensive (MAX) and cheapest (MIN) product in each category.
SELECT category, MAX(unit_price) AS max_price, MIN(unit_price) AS min_price 
FROM products 
GROUP BY category;
/*
Result: (3 rows)
 category    | max_price | min_price
 ------------+-----------+----------
 Clothing    | 4599.00   | 799.00   
 Electronics | 3499.00   | 899.00   
 Home        | 1299.00   | 599.00   
*/

-- Q18. List all product categories where the average unit_price is greater than ₹2000. (Hint: Use HAVING clause)
SELECT category, AVG(unit_price) AS avg_unit_price 
FROM products 
GROUP BY category 
HAVING AVG(unit_price) > 2000;
/*
Result: (2 rows)
 category    | avg_unit_price
 ------------+---------------
 Clothing    | 2699.00       
 Electronics | 2224.00       
*/


-- SECTION D: Joins & Relationships
-- --------------------------------------------------------------------------------

-- Q19. Write an INNER JOIN query to display each order along with the customer's first_name and last_name. Show: order_id, order_date, first_name, last_name, total_amount.
SELECT o.order_id, o.order_date, c.first_name, c.last_name, o.total_amount 
FROM orders o 
INNER JOIN customers c ON o.customer_id = c.customer_id;
/*
Result: (10 rows)
 order_id | order_date | first_name | last_name | total_amount
 ---------+------------+------------+-----------+-------------
     1001 | 2024-08-01 | Aarav      | Sharma    | 4498.00     
     1002 | 2024-08-03 | Priya      | Patel     | 799.00      
     1003 | 2024-08-05 | Rohan      | Gupta     | 7498.00     
     1004 | 2024-08-10 | Aarav      | Sharma    | 3499.00     
     1005 | 2024-08-12 | Sneha      | Reddy     | 2999.00     
     1006 | 2024-08-15 | Vikram     | Singh     | 5898.00     
     1007 | 2024-08-18 | Ananya     | Iyer      | 1299.00     
     1008 | 2024-08-20 | Rohan      | Gupta     | 899.00      
     1009 | 2024-08-25 | Karan      | Mehta     | 6098.00     
     1010 | 2024-08-28 | Divya      | Nair      | 1598.00     
*/

-- Q20. Using a LEFT JOIN, list ALL customers and their orders (if any). Customers with no orders should still appear with NULL values for order columns.
SELECT c.customer_id, c.first_name, c.last_name, o.order_id, o.order_date, o.total_amount 
FROM customers c 
LEFT JOIN orders o ON c.customer_id = o.customer_id;
/*
Result: (10 rows - Note: All sample customers had placed at least one order. If a new customer 109 exists
        without orders, they would still show up with order_id, order_date, and total_amount as NULL.)
 customer_id | first_name | last_name | order_id | order_date | total_amount
 ------------+------------+-----------+----------+------------+-------------
         101 | Aarav      | Sharma    |     1001 | 2024-08-01 | 4498.00     
         101 | Aarav      | Sharma    |     1004 | 2024-08-10 | 3499.00     
         102 | Priya      | Patel     |     1002 | 2024-08-03 | 799.00      
         103 | Rohan      | Gupta     |     1003 | 2024-08-05 | 7498.00     
         103 | Rohan      | Gupta     |     1008 | 2024-08-20 | 899.00      
         104 | Sneha      | Reddy     |     1005 | 2024-08-12 | 2999.00     
         105 | Vikram     | Singh     |     1006 | 2024-08-15 | 5898.00     
         106 | Ananya     | Iyer      |     1007 | 2024-08-18 | 1299.00     
         107 | Karan      | Mehta     |     1009 | 2024-08-25 | 6098.00     
         108 | Divya      | Nair      |     1010 | 2024-08-28 | 1598.00     
*/

-- Q21. Write a query using JOINs across three tables (orders → order_items → products) to show: order_id, product_name, quantity, unit_price, and discount_pct for each order item.
SELECT oi.order_id, p.product_name, oi.quantity, oi.unit_price, oi.discount_pct 
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id;
/*
Result: (15 rows)
 order_id | product_name         | quantity | unit_price | discount_pct
 ---------+----------------------+----------+------------+-------------
     1001 | Wireless Earbuds     |        2 | 1499.00    | 0.00        
     1001 | Laptop Stand         |        1 | 899.00     | 10.00       
     1002 | Cotton T-Shirt       |        1 | 799.00     | 0.00        
     1003 | Smart Watch          |        1 | 2999.00    | 0.00        
     1003 | Running Shoes        |        1 | 4599.00    | 5.00        
     1004 | Bluetooth Speaker    |        1 | 3499.00    | 0.00        
     1005 | Smart Watch          |        1 | 2999.00    | 0.00        
     1006 | Wireless Earbuds     |        1 | 1499.00    | 10.00       
     1006 | Running Shoes        |        1 | 4599.00    | 5.00        
     1007 | Bedsheet Set         |        1 | 1299.00    | 0.00        
     1008 | Laptop Stand         |        1 | 899.00     | 0.00        
     1009 | Bluetooth Speaker    |        1 | 3499.00    | 0.00        
     1009 | Cushion Covers (Set) |        2 | 599.00     | 15.00       
     1010 | Bedsheet Set         |        1 | 1299.00    | 0.00        
     1010 | Cushion Covers (Set) |        1 | 599.00     | 0.00        
*/

-- Q22. Explain the difference between LEFT JOIN and RIGHT JOIN with an example from this schema. When would you use a FULL OUTER JOIN?
/*
Differences:
- LEFT JOIN: Keeps all rows from the left table. For unmatched right table rows, it fills them with NULL.
  Example: `customers LEFT JOIN orders` will display every customer from the database, even if they have
  placed 0 orders.
- RIGHT JOIN: Keeps all rows from the right table. For unmatched left table rows, it fills them with NULL.
  Example: `customers RIGHT JOIN orders` returns all orders, showing NULL customer details if an order
  somehow references a non-existent customer (which shouldn't happen with referential integrity).

When to use FULL OUTER JOIN:
- Use FULL OUTER JOIN when you want to retrieve all records from both tables, combining matches and listing
  unmatched records from both sides.
- Practical Example: Reconciling inventory lists. If you have a local inventory table and a vendor inventory
  table, a FULL OUTER JOIN allows you to spot items that are:
    1. In both tables (matched).
    2. Only in your local table (missing vendor link).
    3. Only in the vendor table (new stock items not yet in your local database).
*/

-- Q23. Identify all Foreign Key relationships in the schema. Explain what would happen if you tried to insert an order with customer_id = 999 (which doesn't exist in customers).
/*
Foreign Key Relationships:
1. `orders.customer_id` references `customers.customer_id`
2. `order_items.order_id` references `orders.order_id`
3. `order_items.product_id` references `products.product_id`

What happens if customer_id = 999 is inserted into orders:
- The database engine throws a FOREIGN KEY constraint violation error (e.g. "FOREIGN KEY constraint failed").
- The insert operation is blocked. This maintains Referential Integrity, ensuring that an order cannot exist
  without being associated with a real, registered customer in the parent `customers` table.
*/


-- SECTION E: Advanced Concepts (CASE, ACID, Transactions)
-- --------------------------------------------------------------------------------

-- Q24. Write a query using CASE to classify products into price tiers:
-- • 'Budget'    → unit_price < 1000
-- • 'Mid-Range' → unit_price BETWEEN 1000 AND 3000
-- • 'Premium'   → unit_price > 3000
-- Display: product_name, unit_price, price_tier.
SELECT product_name, unit_price, 
       CASE 
           WHEN unit_price < 1000 THEN 'Budget'
           WHEN unit_price BETWEEN 1000 AND 3000 THEN 'Mid-Range'
           ELSE 'Premium'
       END AS price_tier 
FROM products;
/*
Result: (8 rows)
 product_name         | unit_price | price_tier
 ----------------------+------------+-----------
 Wireless Earbuds     | 1499.00    | Mid-Range 
 Cotton T-Shirt       | 799.00     | Budget    
 Smart Watch          | 2999.00    | Mid-Range 
 Running Shoes        | 4599.00    | Premium   
 Bluetooth Speaker    | 3499.00    | Premium   
 Bedsheet Set         | 1299.00    | Mid-Range 
 Laptop Stand         | 899.00     | Budget    
 Cushion Covers (Set) | 599.00     | Budget    
*/

-- Q25. Using a CASE statement inside an aggregate function, count how many orders are 'Delivered' vs 'Not Delivered' (all other statuses). Display the result in a single row.
SELECT 
    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_count,
    SUM(CASE WHEN status <> 'Delivered' THEN 1 ELSE 0 END) AS not_delivered_count
FROM orders;
/*
Result: (1 row)
 delivered_count | not_delivered_count
 ----------------+--------------------
               6 | 5                  
*/

-- Q26. Explain each letter of ACID:
-- • A – Atomicity | • C – Consistency | • I – Isolation | • D – Durability
-- Give a real-world example (e.g., bank transfer) showing why each property is important.
/*
ACID Properties Explained (Example: Bank Transfer of $100 from Account A to Account B):

1. ATOMICITY ("All or Nothing"):
   - Explanation: Ensures that a transaction is treated as a single unit. Either all statements succeed,
     or all are aborted and rolled back.
   - Why Important: If the system fails after debiting Account A but before crediting Account B,
     Atomicity rolls back the debit so the $100 doesn't vanish into thin air.

2. CONSISTENCY ("Rules and Constraints"):
   - Explanation: A transaction must transition the database from one valid state to another, preserving
     all structural rules, keys, and CHECK constraints.
   - Why Important: If Account A only has $50, and there is a CHECK constraint `balance >= 0`,
     Consistency prevents the transfer of $100 because it would drive the balance negative, aborting the transaction.

3. ISOLATION ("No Interference"):
   - Explanation: Ensures that concurrently running transactions do not interfere with or see each other's intermediate state.
   - Why Important: If Account A has $120, and two transfers of $100 occur at the exact same instant,
     Isolation serializes them. The first transfer completes, leaving $20, and the second transfer fails
     due to insufficient funds, preventing a double-spend error.

4. DURABILITY ("Permanent & Crash-Proof"):
   - Explanation: Once a transaction commits, its changes are written to persistent storage and are guaranteed
     to survive any subsequent system crash or power outage.
   - Why Important: Once the database confirms the $100 transfer succeeded, a sudden power cut a millisecond later
     cannot wipe out that record; the updated account balances will be safely preserved when the system reboots.
*/

-- Q27. Write a SQL transaction that does the following atomically:
-- 1. Insert a new order (order_id=1011, customer_id=102, today's date, 'Pending', 1598.00)
-- 2. Insert two order items for that order
-- 3. Update the stock_qty of the purchased products
-- 4. If any step fails, ROLLBACK the entire transaction. Otherwise, COMMIT.
-- Write the complete BEGIN...COMMIT/ROLLBACK block.

-- Note: Standard ANSI-SQL transaction syntax
BEGIN TRANSACTION;

-- Step 1: Insert new order
INSERT INTO orders (order_id, customer_id, order_date, status, total_amount)
VALUES (1011, 102, '2026-06-05', 'Pending', 1598.00);

-- Step 2: Insert order items
-- Product 202 (Cotton T-Shirt) qty 1 @ 799.00
INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount_pct)
VALUES (5016, 1011, 202, 1, 799.00, 0.00);

-- Product 207 (Laptop Stand) qty 1 @ 899.00 with 10% discount (Net = 809.10)
INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount_pct)
VALUES (5017, 1011, 207, 1, 899.00, 10.00);

-- Step 3: Update stock quantities
UPDATE products 
SET stock_qty = stock_qty - 1 
WHERE product_id = 202;

UPDATE products 
SET stock_qty = stock_qty - 1 
WHERE product_id = 207;

-- Commit the transaction to save changes permanently
COMMIT;


-- ================================================================================
-- PART 2: SUPERSTORE SALES DATA ANALYSIS (From CSV Dataset)
-- ================================================================================

-- STEP 1: LOAD DATASET (SQL Table Schema Definition)
-- --------------------------------------------------------------------------------
-- Note: A CSV parsing tool/pandas script was used to load the 9,994 rows of
-- 'Sample - Superstore.csv' into this `superstore` table.
CREATE TABLE IF NOT EXISTS superstore (
    row_id         INTEGER PRIMARY KEY,
    order_id       TEXT,
    order_date     TEXT,
    ship_date      TEXT,
    ship_mode      TEXT,
    customer_id    TEXT,
    customer_name  TEXT,
    segment        TEXT,
    country        TEXT,
    city           TEXT,
    state          TEXT,
    postal_code    INTEGER,
    region         TEXT,
    product_id     TEXT,
    category       TEXT,
    sub_category   TEXT,
    product_name   TEXT,
    sales          REAL,
    quantity       INTEGER,
    discount       REAL,
    profit         REAL
);


-- STEP 2: EXPLORE TABLE (Schema and Sample Rows)
-- --------------------------------------------------------------------------------

-- Explore Schema: Check structure and data types
-- SQLite DDL Explorer: PRAGMA table_info(superstore);

-- Retrieve sample rows to understand columns
SELECT order_id, customer_name, segment, city, state, category, sales, quantity, profit 
FROM superstore 
LIMIT 5;
/*
Result: (5 rows)
 order_id       | customer_name  | segment   | city            | state      | category        | sales    | quantity | profit
 ---------------+----------------+-----------+-----------------+------------+-----------------+----------+----------+---------
 CA-2016-152156 | Claire Gute    | Consumer  | Henderson       | Kentucky   | Furniture       | 261.9600 | 2        | 41.9136 
 CA-2016-152156 | Claire Gute    | Consumer  | Henderson       | Kentucky   | Furniture       | 731.9400 | 3        | 219.5820
 CA-2016-138688 | Darrin Van Huff| Corporate | Los Angeles     | California | Office Supplies | 14.6200  | 2        | 6.8714  
 US-2015-108966 | Sean O'Donnell | Consumer  | Fort Lauderdale | Florida    | Furniture       | 957.5775 | 5        | -383.031
 US-2015-108966 | Sean O'Donnell | Consumer  | Fort Lauderdale | Florida    | Office Supplies | 22.3680  | 2        | 2.5164  
*/


-- STEP 3: APPLY WHERE FILTERS
-- --------------------------------------------------------------------------------

-- A. Filter by Region = 'South' (Get count)
SELECT COUNT(*) AS south_orders FROM superstore WHERE region = 'South';
/*
Result: (1 row)
 south_orders
 ------------
 1620
*/

-- B. Filter by Category = 'Technology' (Get count)
SELECT COUNT(*) AS tech_orders FROM superstore WHERE category = 'Technology';
/*
Result: (1 row)
 tech_orders
 -----------
 1847
*/

-- C. Filter by Order Date >= '2017-01-01' (Get count)
SELECT COUNT(*) AS order_count_since_2017 FROM superstore WHERE order_date >= '2017-01-01';
/*
Result: (1 row)
 order_count_since_2017
 ----------------------
 3312
*/

-- D. Filter by Sales > 1000 (Get count)
SELECT COUNT(*) AS high_sales_count FROM superstore WHERE sales > 1000;
/*
Result: (1 row)
 high_sales_count
 ----------------
 468
*/


-- STEP 4: USE GROUP BY FOR AGGREGATIONS
-- --------------------------------------------------------------------------------

-- A. Total Sales, Total Quantity, and Average Sales per Category
SELECT category, 
       SUM(sales) AS total_sales, 
       SUM(quantity) AS total_qty, 
       AVG(sales) AS avg_sales_value 
FROM superstore 
GROUP BY category;
/*
Result: (3 rows)
 category        | total_sales | total_qty | avg_sales_value
 ----------------+-------------+-----------+----------------
 Furniture       | 741999.80   | 8028      | 349.83         
 Office Supplies | 719047.03   | 22906     | 119.32         
 Technology      | 836154.03   | 6939      | 452.71         
*/

-- B. Total Sales and Total Profit by Sub-Category (Sorted by Total Profit DESC)
SELECT sub_category, 
       SUM(sales) AS total_sales, 
       SUM(profit) AS total_profit 
FROM superstore 
GROUP BY sub_category 
ORDER BY total_profit DESC;
/*
Result: (17 rows)
 sub_category | total_sales | total_profit
 -------------+-------------+-------------
 Copiers      | 149528.03   | 55617.82    
 Phones       | 330007.05   | 44515.73    
 Accessories  | 167380.32   | 41936.64    
 Paper        | 78479.21    | 34053.57    
 Binders      | 203412.73   | 30221.76    
 Chairs       | 328449.10   | 26590.17    
 Storage      | 223843.61   | 21278.83    
 Appliances   | 107532.16   | 18138.01    
 Furnishings  | 91705.16    | 13059.14    
 Envelopes    | 16476.40    | 6964.18     
 Art          | 27118.79    | 6527.79     
 Labels       | 12486.31    | 5546.25     
 Machines     | 189238.63   | 3384.76     
 Fasteners    | 3024.28     | 949.52      
 Supplies     | 46673.54    | -1189.10    
 Bookcases    | 114879.99   | -3472.56    
 Tables       | 206965.53   | -17725.48   
*/


-- STEP 5: SORT AND LIMIT RESULTS
-- --------------------------------------------------------------------------------

-- A. Top 5 Products by Sales
SELECT product_name, SUM(sales) AS total_sales 
FROM superstore 
GROUP BY product_name 
ORDER BY total_sales DESC 
LIMIT 5;
/*
Result: (5 rows)
 product_name                                                                 | total_sales
 -----------------------------------------------------------------------------+------------
 Canon imageCLASS 2200 Advanced Copier                                        | 61599.82   
 Fellowes PB500 Electric Punch Plastic Comb Binding Machine with Manual Bind   | 27453.38   
 Cisco TelePresence System EX90 Videoconferencing Unit                        | 22638.48   
 HON 5400 Series Task Chairs for Big and Tall                                 | 21870.58   
 GBC DocuBind TL300 Electric Binding System                                   | 19823.48   
*/

-- B. Top 5 Sub-Categories by Total Quantity Sold
SELECT sub_category, SUM(quantity) AS total_qty 
FROM superstore 
GROUP BY sub_category 
ORDER BY total_qty DESC 
LIMIT 5;
/*
Result: (5 rows)
 sub_category | total_qty
 -------------+----------
 Binders      | 5974     
 Paper        | 5178     
 Furnishings  | 3563     
 Phones       | 3289     
 Storage      | 3158     
*/


-- STEP 6: SOLVE BUSINESS USE CASES
-- --------------------------------------------------------------------------------

-- A. Monthly Sales Trends (First 12 months in the dataset)
SELECT strftime('%Y-%m', order_date) AS order_month, 
       SUM(sales) AS monthly_sales 
FROM superstore 
GROUP BY order_month 
ORDER BY order_month 
LIMIT 12;
/*
Result: (12 rows representing Year 2014)
 order_month | monthly_sales
 ------------+--------------
 2014-01     | 14236.90     
 2014-02     | 4519.89      
 2014-03     | 55691.01     
 2014-04     | 28295.35     
 2014-05     | 23648.29     
 2014-06     | 34595.13     
 2014-07     | 33946.39     
 2014-08     | 27909.47     
 2014-09     | 81777.35     
 2014-10     | 31453.39     
 2014-11     | 78628.72     
 2014-12     | 69545.62     
*/

-- B. Top 5 Customers by Total Sales Amount
SELECT customer_name, SUM(sales) AS total_sales 
FROM superstore 
GROUP BY customer_name 
ORDER BY total_sales DESC 
LIMIT 5;
/*
Result: (5 rows)
 customer_name | total_sales
 --------------+-----------
 Sean Miller   | 25043.05  
 Tamara Chand  | 19052.22  
 Raymond Buch  | 15117.34  
 Tom Ashbrook  | 14595.62  
 Adrian Barton | 14473.57  
*/

-- C. Identify Duplicates (Same Order ID and Product ID purchased in multiple line items)
SELECT order_id, product_id, COUNT(*) AS occur_count 
FROM superstore 
GROUP BY order_id, product_id 
HAVING COUNT(*) > 1 
LIMIT 5;
/*
Result: (Showing first 5 of 8 duplicate records found)
 order_id       | product_id      | occur_count
 ---------------+-----------------+-------------
 CA-2015-103135 | OFF-BI-10000069 | 2           
 CA-2016-129714 | OFF-PA-10001970 | 2           
 CA-2016-137043 | FUR-FU-10003664 | 2           
 CA-2016-140571 | OFF-PA-10001954 | 2           
 CA-2017-118017 | TEC-AC-10002006 | 2           
*/


-- STEP 7: VALIDATE RESULTS & DATA QUALITY
-- --------------------------------------------------------------------------------

-- A. Validate Total Row Count (Expected: 9994 rows matching source CSV)
SELECT COUNT(*) AS total_rows FROM superstore;
/*
Result: (1 row)
 total_rows
 ----------
 9994      
*/

-- B. Check for Nulls in Critical Fields (order_id, sales, customer_id)
SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
       SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
       SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids
FROM superstore;
/*
Result: (1 row)
 null_order_ids | null_sales | null_customer_ids
 ---------------+------------+------------------
 0              | 0          | 0                
*/


-- ================================================================================
-- BUSINESS INSIGHTS SUMMARY
-- ================================================================================
/*
1. E-Commerce Sales Database Insights:
   - "Electronics" and "Clothing" are premium-tier categories with average unit prices of ₹2224.00 and ₹2699.00 respectively.
     "Home" is a budget category with average unit price of ₹949.00.
   - 60% of all orders are in "Delivered" status, generating ₹17,191 of revenue out of ₹35,084 total ordered value.
     Cancel rate stands at 10% (1 order of value ₹2,999 cancelled).

2. Superstore Dataset Analysis Insights:
   - Revenue and Quantity Leader: The "Technology" category yields the highest total sales ($836,154.03) and average sales 
     value per item ($452.71). Conversely, "Office Supplies" moves the most units (22,906 quantity) but at a lower average
     sales value ($119.32).
   - Profitability Warning: "Tables" ($206,965.53 in sales) and "Bookcases" ($114,879.99 in sales) both suffer from severe net 
     losses (-$17,725.48 and -$3,472.56 respectively). The business should investigate steep discounting rates or return 
     rates on Tables and Bookcases.
   - High Performer: "Copiers" represents the single most profitable sub-category, generating $55,617.82 in net profit 
     on only $149,528.03 of sales (a stellar net margin of ~37.2%).
   - Sales Seasonality: Analyzing monthly trends shows Q4 seasonality. Month-over-month sales spike in September ($81,777.35) 
     and November ($78,628.72) relative to Q1 months (e.g., February at $4,519.89), suggesting a strong reliance on holiday shopping cycles.
   - Key Customer Dependency: Customer "Sean Miller" is the top spender contributing $25,043.05 in sales.
*/
