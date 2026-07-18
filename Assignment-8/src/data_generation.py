import csv
import random
from datetime import datetime, timedelta
import uuid

def generate_data():
    num_customers = 500
    num_products = 500
    num_orders = 500
    num_order_items = 600

    categories = ['Electronics', 'Clothing', 'Home', 'Books']
    subcategories = {'Electronics': ['Phones', 'Laptops', 'Accessories'],
                     'Clothing': ['Men', 'Women', 'Kids'],
                     'Home': ['Furniture', 'Decor', 'Kitchen'],
                     'Books': ['Fiction', 'Non-Fiction', 'Comics']}
    statuses = ['PLACED', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'RETURNED']
    regions = ['NORTH', 'SOUTH', 'EAST', 'WEST']
    customer_types = ['REGULAR', 'PREMIUM', 'VIP']

    # 4. customers.csv
    customers = []
    customer_ids = [str(uuid.uuid4()) for _ in range(num_customers)]
    for i in range(num_customers):
        cid = customer_ids[i]
        name = f"Customer {i}"
        # 2% invalid emails
        if random.random() < 0.02:
            email = f"customer{i}invalid" if random.random() < 0.5 else f"customer{i}@"
        else:
            email = f"customer{i}@example.com"
        
        reg_date = (datetime.now() - timedelta(days=random.randint(100, 1000))).strftime('%Y-%m-%d')
        ctype = random.choice(customer_types)
        customers.append([cid, name, email, reg_date, ctype])

    with open('../data/raw/customers.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['customer_id', 'customer_name', 'email', 'registration_date', 'customer_type'])
        writer.writerows(customers)

    # 3. products.csv
    products = []
    product_ids = [str(uuid.uuid4()) for _ in range(num_products)]
    for i in range(num_products):
        pid = product_ids[i]
        cat = random.choice(categories)
        subcat = random.choice(subcategories[cat])
        cost = round(random.uniform(5.0, 500.0), 2)
        pname = f"{subcat} Item {i}"
        
        # Intentional issue: Some product names have extra spaces or mixed case
        if random.random() < 0.1:
            if random.random() < 0.5:
                pname = f"   {pname}   "
            else:
                pname = pname.lower() if random.random() < 0.5 else pname.upper()
                
        products.append([pid, pname, cat, subcat, cost])

    with open('../data/raw/products.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['product_id', 'product_name', 'category', 'subcategory', 'cost_price'])
        writer.writerows(products)

    # 1. orders.csv
    orders = []
    order_ids = [str(uuid.uuid4()) for _ in range(num_orders)]
    for i in range(num_orders):
        oid = order_ids[i]
        
        # 5% NULL customer_id
        if random.random() < 0.05:
            cid = ''
        else:
            cid = random.choice(customer_ids)
            
        status = random.choice(statuses)
        region = random.choice(regions)
        
        # Some order_date in wrong format (DD-MM-YYYY)
        dt = datetime.now() - timedelta(days=random.randint(0, 365), hours=random.randint(0, 23))
        if random.random() < 0.1:
            order_date = dt.strftime('%d-%m-%Y')
        else:
            order_date = dt.strftime('%Y-%m-%d %H:%M:%S')
            
        orders.append([oid, cid, order_date, status, region])

    with open('../data/raw/orders.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['order_id', 'customer_id', 'order_date', 'status', 'region_code'])
        writer.writerows(orders)

    # 2. order_items.csv
    order_items = []
    for i in range(num_order_items):
        iid = str(uuid.uuid4())
        oid = random.choice(order_ids)
        
        # Add some order_items with non-existent orders to test referential integrity? 
        # Actually it just says "How will you ensure order_id in order_items actually exists in orders table?"
        # The prompt for Data Generation doesn't explicitly require non-existent orders here, but Part 2 asks to check for them. Let's add a few!
        if random.random() < 0.02:
            oid = str(uuid.uuid4()) # Non-existent order_id
            
        pid = random.choice(product_ids)
        
        # 3% negative quantity
        if random.random() < 0.03:
            qty = -random.randint(1, 5)
        else:
            qty = random.randint(1, 10)
            
        unit_price = round(random.uniform(10.0, 600.0), 2)
        discount = round(random.uniform(0, 30), 2)
        
        order_items.append([iid, oid, pid, qty, unit_price, discount])

    with open('../data/raw/order_items.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['item_id', 'order_id', 'product_id', 'quantity', 'unit_price', 'discount_percent'])
        writer.writerows(order_items)

if __name__ == '__main__':
    generate_data()
    print("Data generated successfully.")
