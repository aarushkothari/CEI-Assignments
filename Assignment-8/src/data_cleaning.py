import pandas as pd
import re

def clean_orders(df):
    issues = {'null_customer_id': 0, 'wrong_date_format': 0}
    
    # Handle NULL customer_ids
    null_mask = df['customer_id'].isnull() | (df['customer_id'] == '')
    issues['null_customer_id'] = null_mask.sum()
    df.loc[null_mask, 'customer_id'] = 'UNKNOWN'
    
    # Fix date formats
    def fix_date(d):
        try:
            return pd.to_datetime(d, format='%Y-%m-%d %H:%M:%S').strftime('%Y-%m-%d %H:%M:%S')
        except ValueError:
            # Try the DD-MM-YYYY format
            try:
                issues['wrong_date_format'] += 1
                return pd.to_datetime(d, format='%d-%m-%Y').strftime('%Y-%m-%d 00:00:00')
            except ValueError:
                return d

    # Instead of element-wise try-except which is slow and doesn't update issues perfectly if applied multiple times, 
    # we can identify them using regex or pd.to_datetime errors.
    
    # Let's count wrong formats first
    wrong_format_mask = df['order_date'].str.match(r'^\d{2}-\d{2}-\d{4}$')
    issues['wrong_date_format'] = wrong_format_mask.sum()
    
    # Convert all to datetime
    df['order_date'] = pd.to_datetime(df['order_date'], format='mixed', dayfirst=True).dt.strftime('%Y-%m-%d %H:%M:%S')
    
    return df, issues

def clean_products(df):
    issues = {'messy_names': 0}
    
    # Normalize product names (trim spaces, title case)
    original_names = df['product_name'].copy()
    df['product_name'] = df['product_name'].str.strip().str.title()
    
    issues['messy_names'] = (original_names != df['product_name']).sum()
    
    return df, issues

def validate_emails(df):
    invalid_mask = ~df['email'].str.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', na=False)
    invalid_customer_ids = df[invalid_mask]['customer_id'].tolist()
    return invalid_customer_ids

def check_referential_integrity(order_items_df, orders_df):
    valid_order_ids = set(orders_df['order_id'])
    invalid_mask = ~order_items_df['order_id'].isin(valid_order_ids)
    invalid_items = order_items_df[invalid_mask]
    return invalid_items

def run_cleaning():
    print("Starting data cleaning...")
    
    # Load data
    try:
        orders = pd.read_csv('../data/raw/orders.csv')
        order_items = pd.read_csv('../data/raw/order_items.csv')
        products = pd.read_csv('../data/raw/products.csv')
        customers = pd.read_csv('../data/raw/customers.csv')
    except FileNotFoundError as e:
        print(f"Error loading files: {e}")
        return
        
    report = []
    
    # 1. Clean Orders
    cleaned_orders, order_issues = clean_orders(orders)
    report.append(f"Orders cleaned. Found {order_issues['null_customer_id']} NULL customer IDs and {order_issues['wrong_date_format']} wrong date formats.")
    
    # 2. Clean Products
    cleaned_products, product_issues = clean_products(products)
    report.append(f"Products cleaned. Fixed {product_issues['messy_names']} messy product names.")
    
    # 3. Validate Emails
    invalid_customer_ids = validate_emails(customers)
    report.append(f"Email validation found {len(invalid_customer_ids)} invalid emails.")
    
    # 4. Referential Integrity
    invalid_order_items = check_referential_integrity(order_items, cleaned_orders)
    report.append(f"Referential integrity check found {len(invalid_order_items)} order_items with non-existent order_ids.")
    
    # Fix the invalid items by removing them
    cleaned_order_items = order_items[~order_items['item_id'].isin(invalid_order_items['item_id'])].copy()
    
    # Also clean negative quantities as mentioned in part 1 "3% of order_items should have negative quantity (these are returns)"
    # Actually wait, are negative quantities allowed as returns or should they be cleaned? 
    # "Some rows have negative quantity (these are returns)" -> This implies negative quantity is valid for returns, so don't remove them.
    
    # Save cleaned files
    cleaned_orders.to_csv('../data/cleaned/cleaned_orders.csv', index=False)
    cleaned_order_items.to_csv('../data/cleaned/cleaned_order_items.csv', index=False)
    cleaned_products.to_csv('../data/cleaned/cleaned_products.csv', index=False)
    customers.to_csv('../data/cleaned/cleaned_customers.csv', index=False)
    
    print("\n--- Data Cleaning Report ---")
    for r in report:
        print(r)
    print("----------------------------\n")
    print("Cleaned CSV files saved.")

if __name__ == '__main__':
    run_cleaning()
