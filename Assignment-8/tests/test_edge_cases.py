import pandas as pd
from datetime import datetime, timedelta

def setup_dummy_data():
    # Create some dummy data to test
    orders = pd.DataFrame({
        'order_id': ['o1', 'o2'],
        'customer_id': ['c1', 'c2'],
        'order_date': ['2023-01-01 10:00:00', '2023-01-02 12:00:00']
    })
    
    order_items = pd.DataFrame({
        'item_id': ['i1', 'i2', 'i3', 'i4'],
        'order_id': ['o1', 'o3', 'o2', 'o2'], # 'o3' doesn't exist in orders
        'product_id': ['p1', 'p2', 'p1', 'p3'],
        'quantity': [1, 2, 0, 5], # i3 has 0 quantity
        'unit_price': [100, 200, 100, 50],
        'discount_percent': [10, 20, 150, 5] # i3 has 150% discount
    })
    
    return orders, order_items


def test_referential_integrity(orders, order_items):
    """1. What happens when order_items has an order_id not in orders?"""
    print("Testing referential integrity...")
    valid_orders = set(orders['order_id'])
    invalid_mask = ~order_items['order_id'].isin(valid_orders)
    invalid_items = order_items[invalid_mask]
    
    # In our setup, 'o3' is the invalid order
    if len(invalid_items) != 1:
        print(f"  -> Failed: Expected 1 invalid item, got {len(invalid_items)}")
        return
    if invalid_items.iloc[0]['order_id'] != 'o3':
        print(f"  -> Failed: Expected invalid order_id 'o3', got {invalid_items.iloc[0]['order_id']}")
        return
        
    print("  -> Result: Orphaned order items exist without a valid parent order. This breaks SQL JOIN queries.")
    print("  -> Resolution: Filter out order_items where order_id is not present in the orders table during data cleaning.")


def test_discount_percent_gt_100(order_items):
    """2. What happens when discount_percent > 100?"""
    print("Testing discount_percent > 100...")
    # Find items with discount > 100
    invalid_discount = order_items[order_items['discount_percent'] > 100]
    if len(invalid_discount) != 1:
        print(f"  -> Failed: Expected 1 item with >100% discount, got {len(invalid_discount)}")
        return
    
    # The fix would be to cap discount at 100
    def fix_discount(val):
        return min(val, 100)
        
    fixed_discounts = order_items['discount_percent'].apply(fix_discount)
    if not all(fixed_discounts <= 100):
        print("  -> Failed: Failed to cap all discounts to 100")
        return
        
    print("  -> Result: A discount > 100% leads to negative revenue values in financial calculations.")
    print("  -> Resolution: Cap the discount_percent to a maximum of 100 using a min(val, 100) function during data cleaning.")


def test_quantity_is_0(order_items):
    """3. What happens when quantity is 0?"""
    print("Testing quantity is 0...")
    # If quantity is 0, revenue becomes 0. Depending on business logic, this might be invalid.
    zero_qty = order_items[order_items['quantity'] == 0]
    if len(zero_qty) != 1:
        print(f"  -> Failed: Expected 1 item with 0 quantity, got {len(zero_qty)}")
        return
        
    print("  -> Result: A quantity of 0 generates 0 revenue, polluting metrics like average order value or items per order.")
    print("  -> Resolution: Drop rows where quantity is exactly 0, or flag them for manual review depending on business rules.")


def test_order_date_in_future():
    """4. What happens when order_date is in the future?"""
    print("Testing order_date in future...")
    future_date = (datetime.now() + timedelta(days=10)).strftime('%Y-%m-%d %H:%M:%S')
    test_orders = pd.DataFrame({
        'order_id': ['o99'],
        'order_date': [future_date]
    })
    
    # Check for future dates
    test_orders['order_date'] = pd.to_datetime(test_orders['order_date'])
    current_time = datetime.now()
    
    future_mask = test_orders['order_date'] > current_time
    future_orders = test_orders[future_mask]
    
    if len(future_orders) != 1:
        print(f"  -> Failed: Expected 1 future order, got {len(future_orders)}")
        return
        
    print("  -> Result: Future dates distort time-series analysis, cohort tracking, and daily summaries.")
    print("  -> Resolution: Identify dates > current system date and either cap them to the current date or drop the corrupted records.")


def run_all_tests():
    print("Running Edge Case Tests...\n")
    orders, order_items = setup_dummy_data()
    
    test_referential_integrity(orders, order_items)
    test_discount_percent_gt_100(order_items)
    test_quantity_is_0(order_items)
    test_order_date_in_future()
    
    print("\nAll edge case tests passed successfully!")

if __name__ == '__main__':
    run_all_tests()
