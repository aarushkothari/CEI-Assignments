import sqlite3
import pandas as pd

def setup_database():
    conn = sqlite3.connect('../db/ecommerce.db')
    
    try:
        # Load cleaned data
        orders = pd.read_csv('../data/cleaned/cleaned_orders.csv')
        order_items = pd.read_csv('../data/cleaned/cleaned_order_items.csv')
        products = pd.read_csv('../data/cleaned/cleaned_products.csv')
        customers = pd.read_csv('../data/cleaned/cleaned_customers.csv')
        
        # Write to sqlite
        orders.to_sql('orders', conn, if_exists='replace', index=False)
        order_items.to_sql('order_items', conn, if_exists='replace', index=False)
        products.to_sql('products', conn, if_exists='replace', index=False)
        customers.to_sql('customers', conn, if_exists='replace', index=False)
        
        print("Database setup complete.")
    except FileNotFoundError:
        print("Cleaned CSV files not found. Run data_cleaning.py first.")
    
    return conn

def run_queries(conn):
    cursor = conn.cursor()
    
    queries = {
        "1. Total revenue per category": """
            SELECT 
                p.category, 
                SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as total_revenue
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.quantity > 0 -- exclude returns if needed, but the formula handles quantity
            GROUP BY p.category;
        """,
        "2. Top 10 customers by total order value": """
            SELECT 
                c.customer_id, 
                c.customer_name, 
                SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as total_value
            FROM customers c
            JOIN orders o ON c.customer_id = o.customer_id
            JOIN order_items oi ON o.order_id = oi.order_id
            GROUP BY c.customer_id, c.customer_name
            ORDER BY total_value DESC
            LIMIT 10;
        """,
        "3. Month-wise order count for the last 12 months": """
            SELECT 
                strftime('%Y-%m', order_date) as order_month, 
                COUNT(order_id) as order_count
            FROM orders
            WHERE order_date >= date('now', '-12 months')
            GROUP BY order_month
            ORDER BY order_month;
        """,
        "4. Find customers who placed orders but never had any item delivered": """
            SELECT DISTINCT c.customer_id, c.customer_name
            FROM customers c
            JOIN orders o ON c.customer_id = o.customer_id
            WHERE c.customer_id NOT IN (
                SELECT customer_id FROM orders WHERE status = 'DELIVERED'
            );
        """,
        "5. Products that were ordered but had more returns than purchases": """
            SELECT 
                p.product_id, 
                p.product_name,
                SUM(CASE WHEN oi.quantity > 0 THEN oi.quantity ELSE 0 END) as total_purchased,
                SUM(CASE WHEN oi.quantity < 0 THEN ABS(oi.quantity) ELSE 0 END) as total_returned
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            GROUP BY p.product_id, p.product_name
            HAVING total_returned > total_purchased;
        """,
        "6. Calculate the return rate (returned items / total items) per category": """
            SELECT 
                p.category,
                CAST(SUM(CASE WHEN oi.quantity < 0 THEN ABS(oi.quantity) ELSE 0 END) AS FLOAT) / 
                NULLIF(SUM(ABS(oi.quantity)), 0) as return_rate
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            GROUP BY p.category;
        """,
        "7. Running Totals with Window Functions": """
            SELECT 
                o.region_code, 
                date(o.order_date) as order_date, 
                SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as daily_revenue,
                SUM(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0))) OVER (
                    PARTITION BY o.region_code 
                    ORDER BY date(o.order_date)
                ) as running_total
            FROM orders o
            JOIN order_items oi ON o.order_id = oi.order_id
            GROUP BY o.region_code, date(o.order_date)
            ORDER BY o.region_code, date(o.order_date);
        """,
        "8. Ranking with DENSE_RANK": """
            WITH CategoryRevenue AS (
                SELECT 
                    p.category, 
                    p.product_name, 
                    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as total_revenue
                FROM order_items oi
                JOIN products p ON oi.product_id = p.product_id
                GROUP BY p.category, p.product_id, p.product_name
            )
            SELECT 
                category, 
                product_name, 
                total_revenue,
                DENSE_RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) as rank_in_category
            FROM CategoryRevenue;
        """,
        "9. LAG/LEAD Analysis": """
            WITH OrderDates AS (
                SELECT 
                    customer_id, 
                    date(order_date) as order_date,
                    LAG(date(order_date)) OVER (PARTITION BY customer_id ORDER BY date(order_date)) as previous_order_date
                FROM orders
            ),
            Gaps AS (
                SELECT 
                    customer_id,
                    order_date,
                    previous_order_date,
                    julianday(order_date) - julianday(previous_order_date) as days_gap
                FROM OrderDates
                WHERE previous_order_date IS NOT NULL
            ),
            AvgGaps AS (
                SELECT 
                    customer_id, 
                    AVG(days_gap) as avg_gap
                FROM Gaps
                GROUP BY customer_id
            )
            SELECT 
                g.customer_id, 
                g.order_date, 
                g.previous_order_date, 
                g.days_gap,
                CASE WHEN a.avg_gap > 30 THEN 'At Risk' ELSE 'Safe' END as risk_status
            FROM Gaps g
            JOIN AvgGaps a ON g.customer_id = a.customer_id;
        """,
        "10. CTE with Multiple Levels": """
            WITH MonthlyRevenue AS (
                SELECT 
                    c.customer_id,
                    strftime('%Y-%m', o.order_date) as order_month,
                    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as revenue
                FROM customers c
                JOIN orders o ON c.customer_id = o.customer_id
                JOIN order_items oi ON o.order_id = oi.order_id
                GROUP BY c.customer_id, strftime('%Y-%m', o.order_date)
            ),
            CustomerCategories AS (
                SELECT 
                    customer_id,
                    order_month,
                    revenue,
                    CASE 
                        WHEN revenue > 10000 THEN 'High'
                        WHEN revenue BETWEEN 5000 AND 10000 THEN 'Medium'
                        ELSE 'Low'
                    END as category
                FROM MonthlyRevenue
            )
            SELECT 
                order_month,
                category,
                COUNT(customer_id) as customer_count
            FROM CustomerCategories
            GROUP BY order_month, category
            ORDER BY order_month, category;
        """,
        "11. NTILE for Segmentation": """
            WITH LifetimeValue AS (
                SELECT 
                    c.customer_id,
                    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as total_value
                FROM customers c
                JOIN orders o ON c.customer_id = o.customer_id
                JOIN order_items oi ON o.order_id = oi.order_id
                GROUP BY c.customer_id
            ),
            Quartiles AS (
                SELECT 
                    customer_id,
                    total_value,
                    NTILE(4) OVER (ORDER BY total_value DESC) as quartile
                FROM LifetimeValue
                WHERE total_value IS NOT NULL
            )
            SELECT 
                customer_id,
                total_value,
                quartile,
                CASE quartile 
                    WHEN 1 THEN 'Platinum'
                    WHEN 2 THEN 'Gold'
                    WHEN 3 THEN 'Silver'
                    WHEN 4 THEN 'Bronze'
                END as quartile_label
            FROM Quartiles;
        """,
        "12. Year-over-Year Comparison": """
            WITH MonthlyRev AS (
                SELECT 
                    CAST(strftime('%Y', order_date) AS INTEGER) as year,
                    strftime('%m', order_date) as month,
                    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as revenue
                FROM orders o
                JOIN order_items oi ON o.order_id = oi.order_id
                GROUP BY year, month
            )
            SELECT 
                curr.year,
                curr.month,
                curr.revenue,
                prev.revenue as prev_year_revenue,
                CASE 
                    WHEN prev.revenue IS NULL THEN NULL
                    ELSE ((curr.revenue - prev.revenue) / prev.revenue) * 100 
                END as yoy_growth_percent
            FROM MonthlyRev curr
            LEFT JOIN MonthlyRev prev 
                ON curr.year = prev.year + 1 AND curr.month = prev.month
            ORDER BY curr.year, curr.month;
        """,
        "13. First/Last Value Analysis": """
            WITH CustomerOrders AS (
                SELECT 
                    o.customer_id,
                    p.category,
                    o.order_date,
                    FIRST_VALUE(p.category) OVER (
                        PARTITION BY o.customer_id 
                        ORDER BY o.order_date ASC
                    ) as first_category,
                    FIRST_VALUE(p.category) OVER (
                        PARTITION BY o.customer_id 
                        ORDER BY o.order_date DESC
                    ) as last_category
                FROM orders o
                JOIN order_items oi ON o.order_id = oi.order_id
                JOIN products p ON oi.product_id = p.product_id
            )
            SELECT DISTINCT 
                customer_id,
                first_category,
                last_category,
                CASE WHEN first_category != last_category THEN 'Yes' ELSE 'No' END as category_shift
            FROM CustomerOrders;
        """,
        "14. Cumulative Distribution": """
            WITH CustomerRevenue AS (
                SELECT 
                    c.customer_id,
                    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as revenue
                FROM customers c
                JOIN orders o ON c.customer_id = o.customer_id
                JOIN order_items oi ON o.order_id = oi.order_id
                GROUP BY c.customer_id
                HAVING revenue IS NOT NULL
            ),
            TotalRev AS (
                SELECT SUM(revenue) as total_company_revenue FROM CustomerRevenue
            ),
            Ranked AS (
                SELECT 
                    customer_id,
                    revenue,
                    SUM(revenue) OVER (ORDER BY revenue DESC) as cumulative_revenue
                FROM CustomerRevenue
            )
            SELECT 
                r.customer_id,
                r.revenue,
                r.cumulative_revenue,
                (r.cumulative_revenue / t.total_company_revenue) * 100 as cumulative_percent
            FROM Ranked r
            CROSS JOIN TotalRev t
            ORDER BY r.revenue DESC;
        """,
        "15. Complex CTE: Cohort Analysis": """
            WITH Cohorts AS (
                SELECT 
                    customer_id,
                    strftime('%Y-%m', MIN(order_date)) as cohort_month
                FROM orders
                GROUP BY customer_id
            ),
            CustomerActivity AS (
                SELECT 
                    o.customer_id,
                    c.cohort_month,
                    strftime('%Y-%m', o.order_date) as activity_month,
                    CAST(strftime('%Y', o.order_date) AS INTEGER) * 12 + CAST(strftime('%m', o.order_date) AS INTEGER)
                    - (CAST(substr(c.cohort_month, 1, 4) AS INTEGER) * 12 + CAST(substr(c.cohort_month, 6, 2) AS INTEGER)) as month_number
                FROM orders o
                JOIN Cohorts c ON o.customer_id = c.customer_id
            ),
            CohortSizes AS (
                SELECT cohort_month, COUNT(DISTINCT customer_id) as cohort_size
                FROM Cohorts
                GROUP BY cohort_month
            ),
            ActivityCounts AS (
                SELECT 
                    cohort_month,
                    month_number,
                    COUNT(DISTINCT customer_id) as active_customers
                FROM CustomerActivity
                WHERE month_number <= 3 -- Just get months 0, 1, 2, 3
                GROUP BY cohort_month, month_number
            )
            SELECT 
                a.cohort_month,
                a.month_number,
                a.active_customers,
                s.cohort_size,
                CAST(a.active_customers AS FLOAT) / s.cohort_size * 100 as retention_rate
            FROM ActivityCounts a
            JOIN CohortSizes s ON a.cohort_month = s.cohort_month
            ORDER BY a.cohort_month, a.month_number;
        """,
        "16. Self-Join with Window Function": """
            WITH BoughtTogether AS (
                SELECT 
                    oi1.product_id as product_a,
                    oi2.product_id as product_b,
                    COUNT(*) as times_bought_together
                FROM order_items oi1
                JOIN order_items oi2 
                    ON oi1.order_id = oi2.order_id 
                    AND oi1.product_id < oi2.product_id -- Exclude same pairs and duplicates
                GROUP BY oi1.product_id, oi2.product_id
            )
            SELECT * FROM BoughtTogether
            ORDER BY times_bought_together DESC
            LIMIT 20;
        """
    }
    
    for title, query in queries.items():
        print(f"\n--- {title} ---")
        try:
            df = pd.read_sql_query(query, conn)
            print(df.head(10))  # Print first 10 rows for brevity
        except Exception as e:
            print(f"Error executing query: {e}")

if __name__ == '__main__':
    conn = setup_database()
    if conn:
        run_queries(conn)
        conn.close()
