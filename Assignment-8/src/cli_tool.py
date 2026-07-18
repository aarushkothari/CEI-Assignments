import sqlite3
from datetime import datetime, timedelta

def get_previous_period(start_date, end_date, report_type):
    fmt = "%Y-%m-%d"
    s_date = datetime.strptime(start_date, fmt)
    e_date = datetime.strptime(end_date, fmt)
    
    if report_type == 'daily':
        delta = (e_date - s_date).days + 1
        prev_end = s_date - timedelta(days=1)
        prev_start = prev_end - timedelta(days=delta - 1)
    elif report_type == 'weekly':
        delta = (e_date - s_date).days + 1
        prev_end = s_date - timedelta(days=1)
        prev_start = prev_end - timedelta(days=delta - 1)
    elif report_type == 'monthly':
        delta = (e_date - s_date).days + 1
        prev_end = s_date - timedelta(days=1)
        prev_start = prev_end - timedelta(days=delta - 1)
    else:
        delta = (e_date - s_date).days + 1
        prev_end = s_date - timedelta(days=1)
        prev_start = prev_end - timedelta(days=delta - 1)
        
    return prev_start.strftime(fmt), prev_end.strftime(fmt)

def run_report(db_path, report_type, start_date, end_date):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 1. Total orders, revenue, unique customers for CURRENT period
    curr_query = """
        SELECT 
            COUNT(DISTINCT o.order_id) as total_orders,
            COUNT(DISTINCT o.customer_id) as unique_customers,
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100.0)) as total_revenue
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE date(o.order_date) BETWEEN ? AND ?
    """
    cursor.execute(curr_query, (start_date, end_date))
    curr_orders, curr_customers, curr_revenue = cursor.fetchone()
    curr_revenue = curr_revenue or 0
    curr_orders = curr_orders or 0
    curr_customers = curr_customers or 0

    # 2. Top 3 products for CURRENT period
    top_products_query = """
        SELECT 
            p.product_name,
            SUM(oi.quantity) as items_sold
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        WHERE date(o.order_date) BETWEEN ? AND ?
        GROUP BY p.product_id, p.product_name
        ORDER BY items_sold DESC
        LIMIT 3
    """
    cursor.execute(top_products_query, (start_date, end_date))
    top_products = cursor.fetchall()

    # 3. Previous period comparison
    prev_start, prev_end = get_previous_period(start_date, end_date, report_type)
    
    cursor.execute(curr_query, (prev_start, prev_end))
    prev_orders, prev_customers, prev_revenue = cursor.fetchone()
    prev_revenue = prev_revenue or 0
    prev_orders = prev_orders or 0
    prev_customers = prev_customers or 0

    def calc_pct_change(curr, prev):
        if prev == 0:
            return "N/A (prev 0)"
        return f"{((curr - prev) / prev) * 100:.2f}%"

    print("\n" + "="*40)
    print(f" SUMMARY REPORT ({report_type.upper()})")
    print(f" Period: {start_date} to {end_date}")
    print("="*40)
    
    print("\n--- CURRENT METRICS ---")
    print(f"Total Orders:     {curr_orders}")
    print(f"Unique Customers: {curr_customers}")
    print(f"Total Revenue:    ${curr_revenue:.2f}")
    
    print("\n--- TOP 3 PRODUCTS ---")
    if not top_products:
        print("None found.")
    for i, (name, sold) in enumerate(top_products, 1):
        print(f"{i}. {name} (Sold: {sold})")
        
    print("\n--- COMPARISON (vs Previous Period: {prev_start} to {prev_end}) ---".format(prev_start=prev_start, prev_end=prev_end))
    print(f"Orders Change:   {calc_pct_change(curr_orders, prev_orders)}")
    print(f"Customer Change: {calc_pct_change(curr_customers, prev_customers)}")
    print(f"Revenue Change:  {calc_pct_change(curr_revenue, prev_revenue)}")
    print("="*40 + "\n")

    conn.close()

if __name__ == '__main__':
    print("Welcome to the E-Commerce Order Analytics CLI")
    
    report_type = input("Enter report type (daily/weekly/monthly): ").strip().lower()
    while report_type not in ['daily', 'weekly', 'monthly']:
        print("Invalid report type. Please enter daily, weekly, or monthly.")
        report_type = input("Enter report type (daily/weekly/monthly): ").strip().lower()

    start_date = input("Enter start date (YYYY-MM-DD): ").strip()
    end_date = input("Enter end date (YYYY-MM-DD): ").strip()
    
    try:
        run_report('../db/ecommerce.db', report_type, start_date, end_date)
    except Exception as e:
        print(f"Error running report: {e}")
