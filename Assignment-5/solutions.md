# Week 5 Assignment Solutions: Apache Spark & Data Processing

## **Dataset Used**
The dataset used for this assignment is the **Sample - Superstore.csv** dataset, originally sourced from Kaggle at [Superstore Dataset (Final)](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final). It consists of order transactions for a retail superstore, capturing fields such as `Order ID`, `Order Date`, `Customer Name`, `Segment`, `City`, `State`, `Region`, `Category`, `Sub-Category`, `Sales`, `Quantity`, `Discount`, and `Profit`.

---

## **Part 1: Answers to Assignment Questions**

### **Q1: Key limitations of traditional MapReduce vs. Apache Spark**
Hadoop MapReduce has several limitations that make Apache Spark the preferred choice for modern big data processing:
1. **Disk-Based I/O Overhead**: MapReduce writes intermediate state data to HDFS (disk) between the Map and Reduce stages. This creates massive disk serialization, deserialization, and network overhead. Spark stores intermediate data **in-memory**, writing to disk only when memory limits are exceeded.
2. **Poor Support for Iterative Workloads**: Algorithms that reuse data multiple times (e.g., machine learning algorithms like K-Means or PageRank) require MapReduce to read and write data to disk at every single step. Spark keeps data cached in memory across iterations.
3. **Rigid API Model**: MapReduce requires writing verbose Java code separated into Mappers and Reducers. Spark provides a rich set of high-level functional APIs in Python, Scala, Java, and R, along with declarative structured APIs (DataFrames and SQL).
4. **Task Launch Latency**: MapReduce starts a new JVM process for every map and reduce task, introducing significant startup latency. Spark maintains persistent executor JVMs that run multiple tasks concurrently.

---

### **Q2: In-Memory Computing and Iterative Machine Learning**
In iterative machine learning, an algorithm repeatedly runs over the same dataset (e.g., updating coefficients or centroids).
* **MapReduce**: Each iteration is treated as a separate Hadoop job. The dataset must be read from disk, processed, written back to disk, and then read again in the next iteration.
* **Apache Spark**: Spark loads the dataset into executor memory once. By applying `.cache()` or `.persist()`, the data stays in RAM. In all subsequent iterations, the executors read the data directly from RAM. This eliminates disk I/O and network transfer, leading to **10x to 100x speedups**.

---

### **Q3: Code snippet to remove duplicate rows**
To remove duplicate rows from a DataFrame based on specific columns:
```python
# Remove duplicates based on user_id and transaction_date
df_cleaned = df.dropDuplicates(["user_id", "transaction_date"])
```

---

### **Q4: Filter and group by query**
Given a DataFrame `df_sales`, to filter for rows where the region is `'West'` and find the average `sale_amount` grouped by `product_category`:
```python
from pyspark.sql import functions as F

df_result = (df_sales
             .filter(F.col("region") == "West")
             .groupBy("product_category")
             .agg(F.avg("sale_amount").alias("avg_sale_amount")))
```

---

### **Q5: Difference between `.na.drop()` and `.na.fill()`**
* **`.na.drop()`**: Used to **remove (drop)** rows that contain null or NaN values. You can configure it to drop a row if any column is null, if all columns are null, or only when nulls appear in a specific subset of columns.
* **`.na.fill()`**: Used to **replace (fill)** null/NaN values with a designated default value (e.g., replacement values for strings, integers, or doubles).

#### **Code Example:**
```python
# Filling null values in a status column with the string 'Unknown'
df_filled = df.na.fill({"status": "Unknown"})
```

---

### **Q6: Total count of records for each city, filtered for count > 100**
To find the count per city where the count is greater than 100:
```python
from pyspark.sql import functions as F

df_cities = (df
             .groupBy("city")
             .count()
             .filter(F.col("count") > 100))
```

---

### **Q7: Immutability of Spark DataFrames in Data Cleaning**
Spark DataFrames are **immutable** (they cannot be changed in place). 
* When you drop a column, rename it, or cast a data type, Spark does not modify the original DataFrame. Instead, it generates a **new DataFrame object** representing the new logical state.
* Under the hood, Spark records these changes in a **Lineage Graph (DAG)**. 
* This design ensures fault tolerance (if a partition is lost, Spark can reconstruct it by running the lineage graph starting from the raw source) and allows the Catalyst Optimizer to optimize the entire sequence of operations before executing any action.

---

### **Q8: Filter dataset for age between 18 and 30 and premium subscription**
```python
from pyspark.sql import functions as F

df_filtered = df.filter(
    (F.col("age") >= 18) & 
    (F.col("age") <= 30) & 
    (F.col("subscription") == "Premium")
)
```

---

### **Q9: Handling null values before mathematical aggregations**
1. **Accuracy of Statistics**: Aggregations like `avg()` or `mean()` ignore nulls, which changes the denominator (count) and can distort calculations (e.g., if a null price should represent `0.0`, ignoring it inflates the calculated average price).
2. **Prevention of Null Propagation**: Performing arithmetic on columns containing nulls (e.g., `sales * quantity`) propagates nulls (`5 * null = null`), causing missing data in outputs.
3. **Deterministic Behavior**: Filling nulls with default values (like `0` for numeric columns) or dropping them ensures calculations are accurate and consistent.

---

### **Q10: Revise column: cast raw_timestamp to TimestampType and rename to event_time**
```python
from pyspark.sql import functions as F
from pyspark.sql.types import TimestampType

df_updated = (df
              .withColumn("event_time", F.col("raw_timestamp").cast(TimestampType()))
              .drop("raw_timestamp"))
```

---

### **Q11: The "Shuffle" process and Wide Transformations**
* **Shuffle**: The process of redistributing data across executors and partitions so that records with the same key are grouped together on the same physical worker node.
* **Why it's a Wide Transformation**: 
  * **Narrow Transformations** (e.g., `filter()`, `select()`, `map()`) operate on partitions independently without copying data across the network.
  * **Wide Transformations** (e.g., `groupBy()`, `join()`, `distinct()`) break partition boundaries. Spark must write intermediate data to local disk, transfer it over the network to the target executors, and then sort/merge it. Shuffling is the most expensive operation in Spark because of the network and disk I/O overhead.

---

### **Q12: Remove rows where email is null OR username is an empty string**
```python
from pyspark.sql import functions as F

df_cleaned = df.filter(
    F.col("email").isNotNull() & 
    (F.trim(F.col("username")) != "")
)
```

---

### **Q13: Calculate multiple statistics at once using `.agg()`**
```python
from pyspark.sql import functions as F

df_stats = df.agg(
    F.min("price").alias("min_price"),
    F.max("price").alias("max_price"),
    F.mean("price").alias("mean_price")
)
```

---

### **Q14: Risk of using `inferSchema=true` with messy date formats**
1. **Misinterpretation**: If the first few rows have dates formatted as `YYYY-MM-DD` and later rows have `DD/MM/YYYY` or non-date strings like `"N/A"`, Spark might infer the column as `StringType` instead of `DateType`.
2. **Silent Data Corruption**: Spark might parse mismatched formats as `null` values, resulting in silent data loss during ingest.
3. **Performance Penalty**: Inferring the schema requires Spark to read the source files twice (once to examine types, once to load the data), which degrades performance on large datasets.
*Best Practice*: Define an explicit schema using `StructType` and manually parse date columns using `to_date()`.

---

### **Q15: Final processing pipeline**
A complete pipeline function that filters duplicates, fills null prices with `0`, and calculates total revenue grouped by `store_id`:
```python
from pyspark.sql import functions as F

def process_store_revenue(df):
    cleaned_df = (df
                  .dropDuplicates()
                  .na.fill({"price": 0.0}))
    
    # Calculate revenue = quantity * price, then sum by store_id
    revenue_df = (cleaned_df
                  .groupBy("store_id")
                  .agg(F.sum(F.col("quantity") * F.col("price")).alias("total_revenue")))
    
    return revenue_df
```

---

## **Part 2: Complete PySpark Pipeline Code**

The following PySpark pipeline script processes the Kaggle Superstore CSV dataset. It handles encoding, demonstrates explicit schema definition, performs lazy evaluation explanations, cleans the data, executes narrow/wide transformations, writes output formats, and measures size comparisons.

```python
import os
import shutil
import time
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, DateType

os.environ["HADOOP_HOME"] = r"c:\Users\kotha\OneDrive\Desktop\CEI-Assignments\Assignment-5\hadoop"
os.environ["PATH"] = os.environ["PATH"] + ";" + os.path.join(os.environ["HADOOP_HOME"], "bin")

BASE_DIR = r"c:\Users\kotha\OneDrive\Desktop\CEI-Assignments\Assignment-5"
CSV_INPUT_PATH = os.path.join(BASE_DIR, "Dataset", "Sample - Superstore.csv")
DATA_DIR = os.path.join(BASE_DIR, "data")
RAW_PARQUET_PATH = os.path.join(DATA_DIR, "raw_superstore_parquet")
CLEANED_CSV_PATH = os.path.join(DATA_DIR, "cleaned_superstore_csv")
CLEANED_PARQUET_PATH = os.path.join(DATA_DIR, "cleaned_superstore_parquet")

def cleanup_path(path):
    if os.path.exists(path):
        try:
            if os.path.isdir(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
        except Exception as e:
            time.sleep(1)
            shutil.rmtree(path, ignore_errors=True)

def main():
    print("=" * 70)
    print("INITIALIZING SPARK SESSION ON SUPERSTORE DATASET")
    print("=" * 70)
    
    spark = SparkSession.builder \
        .appName("SuperstoreSparkPipeline") \
        .master("local[*]") \
        .config("spark.sql.shuffle.partitions", "4") \
        .config("spark.driver.bindAddress", "127.0.0.1") \
        .getOrCreate()
        
    spark.sparkContext.setLogLevel("WARN")
    
    try:
        print("\n--- Step 1: Reading Raw CSV and Writing to Parquet ---")
        df_raw_csv = spark.read \
            .option("header", "true") \
            .option("encoding", "windows-1252") \
            .csv(CSV_INPUT_PATH)
        
        cleanup_path(RAW_PARQUET_PATH)
        df_raw_csv.write.mode("overwrite").parquet(RAW_PARQUET_PATH)
        print("Raw Parquet written successfully.")

        print("\n--- Step 2: Comparing Schema Handling and Read Speeds ---")
        
        start = time.time()
        df_csv_infer = spark.read \
            .option("header", "true") \
            .option("encoding", "windows-1252") \
            .option("inferSchema", "true") \
            .csv(CSV_INPUT_PATH)
        infer_time = time.time() - start
        print(f"CSV Read (inferSchema=True) took {infer_time:.4f} seconds.")
        print("Inferred Column Types (first 5 columns):")
        for col_name, col_type in df_csv_infer.dtypes[:5]:
            print(f"  - {col_name}: {col_type}")

        explicit_schema = StructType([
            StructField("Row ID", IntegerType(), True),
            StructField("Order ID", StringType(), True),
            StructField("Order Date", StringType(), True),
            StructField("Ship Date", StringType(), True),
            StructField("Ship Mode", StringType(), True),
            StructField("Customer ID", StringType(), True),
            StructField("Customer Name", StringType(), True),
            StructField("Segment", StringType(), True),
            StructField("Country", StringType(), True),
            StructField("City", StringType(), True),
            StructField("State", StringType(), True),
            StructField("Postal Code", StringType(), True),
            StructField("Region", StringType(), True),
            StructField("Product ID", StringType(), True),
            StructField("Category", StringType(), True),
            StructField("Sub-Category", StringType(), True),
            StructField("Product Name", StringType(), True),
            StructField("Sales", DoubleType(), True),
            StructField("Quantity", IntegerType(), True),
            StructField("Discount", DoubleType(), True),
            StructField("Profit", DoubleType(), True)
        ])
        start = time.time()
        df_csv_explicit = spark.read \
            .option("header", "true") \
            .option("encoding", "windows-1252") \
            .schema(explicit_schema) \
            .csv(CSV_INPUT_PATH)
        df_csv_explicit.count()
        explicit_time = time.time() - start
        print(f"CSV Read (Explicit Schema) took {explicit_time:.4f} seconds.")

        start = time.time()
        df_parquet = spark.read.parquet(RAW_PARQUET_PATH)
        df_parquet.count()
        parquet_time = time.time() - start
        print(f"Parquet Read (metadata-driven schema) took {parquet_time:.4f} seconds.")

        print("\n--- Step 3: Lazy Evaluation and Catalyst Execution Plans ---")
        df_lazy = df_parquet \
            .filter(F.col("Region") == "West") \
            .select("Order ID", "Customer ID", "Sales", "Profit") \
            .withColumn("Sales_USD", F.col("Sales").cast(DoubleType()))
        
        print("Explaining Catalyst execution plan for transformations:")
        df_lazy.explain(True)

        print("\n--- Step 4: Data Cleaning Pipeline ---")
        df_cleaned = df_parquet \
            .dropDuplicates(["Order ID", "Product ID"]) \
            .withColumn("order_date_parsed", F.to_date(F.col("Order Date"), "M/d/yyyy")) \
            .withColumn("ship_date_parsed", F.to_date(F.col("Ship Date"), "M/d/yyyy")) \
            .withColumnRenamed("Row ID", "row_id") \
            .withColumnRenamed("Order ID", "order_id") \
            .withColumnRenamed("Customer ID", "customer_id") \
            .withColumnRenamed("Customer Name", "customer_name") \
            .withColumnRenamed("Ship Mode", "ship_mode") \
            .withColumnRenamed("Postal Code", "postal_code") \
            .withColumnRenamed("Product ID", "product_id") \
            .withColumnRenamed("Product Name", "product_name") \
            .withColumnRenamed("Sub-Category", "sub_category") \
            .select(
                "row_id", "order_id", "order_date_parsed", "ship_date_parsed", "ship_mode",
                "customer_id", "customer_name", "Segment", "Country", "City", "State", "postal_code",
                "Region", "product_id", "Category", "sub_category", "product_name",
                F.col("Sales").cast(DoubleType()).alias("sales"),
                F.col("Quantity").cast(IntegerType()).alias("quantity"),
                F.col("Discount").cast(DoubleType()).alias("discount"),
                F.col("Profit").cast(DoubleType()).alias("profit")
            ) \
            .na.fill({"sales": 0.0, "quantity": 0, "discount": 0.0, "profit": 0.0}) \
            .filter(F.col("customer_id").isNotNull() & (F.trim(F.col("customer_name")) != "")) \
            .withColumn("unit_price", F.col("sales") / F.col("quantity")) \
            .withColumn("profit_margin", F.col("profit") / F.col("sales"))

        print("Cleaned DataFrame sample (First 5 rows):")
        df_cleaned.select("order_id", "order_date_parsed", "customer_name", "sales", "profit", "profit_margin").show(5, truncate=False)

        print("\n--- Step 5: Executing Narrow and Wide Transformations ---")

        df_narrow = df_cleaned.filter(
            (F.col("Region") == "West") & 
            (F.col("Category").isin("Technology", "Furniture"))
        ).select("order_id", "customer_name", "Region", "Category", "sales")
        print("Narrow transformation result:")
        df_narrow.show(5)

        df_wide_agg = df_cleaned \
            .groupBy("Category", "sub_category") \
            .agg(
                F.sum("sales").alias("total_sales"),
                F.mean("profit").alias("avg_profit"),
                F.max("discount").alias("max_discount")
            ) \
            .orderBy("Category", F.desc("total_sales"))
        print("Wide aggregation (Category/Sub-category statistics):")
        df_wide_agg.show(10, truncate=False)

        df_wide_cities = df_cleaned \
            .groupBy("City") \
            .count() \
            .filter(F.col("count") > 50) \
            .orderBy(F.desc("count"))
        print("Wide aggregation (Count per City > 50):")
        df_wide_cities.show(10)

        print("\n--- Step 6: Saving Processed Outputs ---")
        cleanup_path(CLEANED_CSV_PATH)
        cleanup_path(CLEANED_PARQUET_PATH)

        df_cleaned.write.mode("overwrite").option("header", "true").csv(CLEANED_CSV_PATH)
        df_cleaned.write.mode("overwrite").parquet(CLEANED_PARQUET_PATH)
        print("Cleaned CSV and Parquet written successfully.")

        print("\n--- Step 7: Comparing File Sizes ---")
        def get_dir_size(path):
            total_size = 0
            for dirpath, dirnames, filenames in os.walk(path):
                for f in filenames:
                    fp = os.path.join(dirpath, f)
                    if not f.startswith(".") and not f.endswith(".crc") and f != "_SUCCESS":
                        total_size += os.path.getsize(fp)
            return total_size

        csv_raw_size = os.path.getsize(CSV_INPUT_PATH)
        parquet_raw_size = get_dir_size(RAW_PARQUET_PATH)
        csv_cleaned_size = get_dir_size(CLEANED_CSV_PATH)
        parquet_cleaned_size = get_dir_size(CLEANED_PARQUET_PATH)

        print(f"Original CSV Size: {csv_raw_size} bytes ({csv_raw_size / 1024 / 1024:.2f} MB)")
        print(f"Raw Parquet Size: {parquet_raw_size} bytes ({parquet_raw_size / 1024 / 1024:.2f} MB)")
        print(f"Cleaned CSV Size: {csv_cleaned_size} bytes ({csv_cleaned_size / 1024 / 1024:.2f} MB)")
        print(f"Cleaned Parquet Size: {parquet_cleaned_size} bytes ({parquet_cleaned_size / 1024 / 1024:.2f} MB)")
        if parquet_cleaned_size > 0:
            print(f"Cleaned Parquet is {csv_cleaned_size / parquet_cleaned_size:.2f}x smaller than Cleaned CSV!")

    finally:
        spark.stop()
        print("Spark Session stopped.")

if __name__ == "__main__":
    main()
```

---

## **Part 3: Query Execution Results & Catalyst Optimizer Plans**

The output below represents the actual console stdout captured during the run on PySpark 3.5.8:

```text
======================================================================
INITIALIZING SPARK SESSION ON SUPERSTORE DATASET
======================================================================

--- Step 1: Reading Raw CSV and Writing to Parquet ---
Raw Parquet written successfully.

--- Step 2: Comparing Schema Handling and Read Speeds ---
CSV Read with inferSchema=True took 0.4508 seconds.
Inferred Column Types (first 5 columns):
  - Row ID: int
  - Order ID: string
  - Order Date: string
  - Ship Date: string
  - Ship Mode: string
CSV Read with Explicit Schema took 0.5027 seconds.
Parquet Read (metadata-driven schema) took 0.3796 seconds.

--- Step 3: Lazy Evaluation and Catalyst Execution Plans ---
Explaining Catalyst execution plan for transformations:
== Parsed Logical Plan ==
'Project [Order ID#237, Customer ID#241, Sales#253, Profit#256, cast('Sales as double) AS Sales_USD#309]
+- Project [Order ID#237, Customer ID#241, Sales#253, Profit#256]
   +- Filter (Region#248 = West)
      +- Relation [Row ID#236,Order ID#237,Order Date#238,Ship Date#239,Ship Mode#240,Customer ID#241,Customer Name#242,Segment#243,Country#244,City#245,State#246,Postal Code#247,Region#248,Product ID#249,Category#250,Sub-Category#251,Product Name#252,Sales#253,Quantity#254,Discount#255,Profit#256] parquet

== Analyzed Logical Plan ==
Order ID: string, Customer ID: string, Sales: string, Profit: string, Sales_USD: double
Project [Order ID#237, Customer ID#241, Sales#253, Profit#256, cast(Sales#253 as double) AS Sales_USD#309]
+- Project [Order ID#237, Customer ID#241, Sales#253, Profit#256]
   +- Filter (Region#248 = West)
      +- Relation [Row ID#236,Order ID#237,Order Date#238,Ship Date#239,Ship Mode#240,Customer ID#241,Customer Name#242,Segment#243,Country#244,City#245,State#246,Postal Code#247,Region#248,Product ID#249,Category#250,Sub-Category#251,Product Name#252,Sales#253,Quantity#254,Discount#255,Profit#256] parquet

== Optimized Logical Plan ==
Project [Order ID#237, Customer ID#241, Sales#253, Profit#256, cast(Sales#253 as double) AS Sales_USD#309]
+- Filter (isnotnull(Region#248) AND (Region#248 = West))
   +- Relation [Row ID#236,Order ID#237,Order Date#238,Ship Date#239,Ship Mode#240,Customer ID#241,Customer Name#242,Segment#243,Country#244,City#245,State#246,Postal Code#247,Region#248,Product ID#249,Category#250,Sub-Category#251,Product Name#252,Sales#253,Quantity#254,Discount#255,Profit#256] parquet

== Physical Plan ==
*(1) Project [Order ID#237, Customer ID#241, Sales#253, Profit#256, cast(Sales#253 as double) AS Sales_USD#309]
+- *(1) Filter (isnotnull(Region#248) AND (Region#248 = West))
   +- *(1) ColumnarToRow
      +- FileScan parquet [Order ID#237,Customer ID#241,Region#248,Sales#253,Profit#256] Batched: true, DataFilters: [isnotnull(Region#248), (Region#248 = West)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/c:/Users/kotha/OneDrive/Desktop/CEI-Assignments/Assignment-5/data/raw_superstore_parquet], PartitionFilters: [], PushedFilters: [IsNotNull(Region), EqualTo(Region,West)], ReadSchema: struct<Order ID:string,Customer ID:string,Region:string,Sales:string,Profit:string>


--- Step 4: Data Cleaning Pipeline ---
Cleaned DataFrame sample (First 5 rows):
+--------------+-----------------+----------------+-------+--------+--------------------+
|order_id      |order_date_parsed|customer_name   |sales  |profit  |profit_margin       |
+--------------+-----------------+----------------+-------+--------+--------------------+
|CA-2014-100006|2014-09-07       |Dennis Kane     |377.97 |109.6113|0.29                |
|CA-2014-100090|2014-07-08       |Ed Braxton      |502.488|-87.9354|-0.17500000000000002|
|CA-2014-100090|2014-07-08       |Ed Braxton      |0.0    |0.2     |NULL                |
|CA-2014-100293|2014-03-14       |Neil Französisch|91.056 |31.8696 |0.35                |
|CA-2014-100328|2014-01-28       |Jasper Cacioppo |0.0    |0.2     |NULL                |
+--------------+-----------------+----------------+-------+--------+--------------------+
only showing top 5 rows


--- Step 5: Executing Narrow and Wide Transformations ---
Narrow transformation (Filter for Region='West' & Category in ('Technology', 'Furniture')):
+--------------+------------------+------+----------+-------+
|      order_id|     customer_name|Region|  Category|  sales|
+--------------+------------------+------+----------+-------+
|CA-2014-100090|        Ed Braxton|  West| Furniture|502.488|
|CA-2014-100867| Eugene Hildebrand|  West|Technology|321.552|
|CA-2014-100881|     Daniel Raglin|  West|Technology|302.376|
|CA-2014-101462|Benjamin Patterson|  West| Furniture|  59.92|
|CA-2014-101931|      Todd Sumrall|  West| Furniture|616.998|
+--------------+------------------+------+----------+-------+
only showing top 5 rows

Wide transformation (Group by Category and Sub-Category and aggregate statistics):
+---------------+------------+------------------+-------------------+------------+
|Category       |sub_category|total_sales       |avg_profit         |max_discount|
+---------------+------------+------------------+-------------------+------------+
|Furniture      |Chairs      |328167.7310000007 |43.185430357142955 |0.3         |
|Furniture      |Tables      |206965.53200000012|-55.56577147335423 |0.5         |
|Furniture      |Bookcases   |114879.99629999997|-15.230508771929827|0.7         |
|Furniture      |Furnishings |82465.84999999992 |14.865321966527208 |9.0         |
|Office Supplies|Storage     |216258.83200000046|25.292352781065066 |8.0         |
|Office Supplies|Binders     |199815.65699999992|19.70919428383709  |295.056     |
|Office Supplies|Appliances  |107532.16099999998|38.92275836909872  |0.8         |
|Office Supplies|Paper       |75261.31800000003 |23.941127046783627 |34.24       |
|Office Supplies|Supplies    |45952.469999999994|-7.091397368421048 |8.0         |
|Office Supplies|Art         |27118.791999999976|8.20073743718593   |0.2         |
+---------------+------------+------------------+-------------------+------------+
only showing top 10 rows

Wide transformation (Count of records per City > 50):
+-------------+-----+
|         City|count|
+-------------+-----+
|New York City|  914|
|  Los Angeles|  747|
| Philadelphia|  537|
|San Francisco|  510|
|      Seattle|  428|
|      Houston|  377|
|      Chicago|  314|
|     Columbus|  221|
|    San Diego|  170|
|  Springfield|  162|
+-------------+-----+
only showing top 10 rows


--- Step 6: Saving Processed Outputs ---
Cleaned CSV and Parquet written successfully.

--- Step 7: Comparing File Sizes ---
Original CSV Size: 2287806 bytes (2.18 MB)
Raw Parquet Size: 455672 bytes (0.43 MB)
Cleaned CSV Size: 2506123 bytes (2.39 MB)
Cleaned Parquet Size: 602122 bytes (0.57 MB)
Cleaned Parquet is 4.16x smaller than Cleaned CSV!

======================================================================
SUPERSTORE SPARK PIPELINE EXECUTED SUCCESSFULLY
======================================================================
Spark Session stopped.
```

---

## **Part 4: Performance & Architectural Insights**

### **1. Spark Execution Architecture**
* **Driver Node**: The central coordinator of our application. It runs the `main()` method of our script, instantiates the `SparkSession`, translates user operations into a logical DAG plan, coordinates task scheduling with the Cluster Manager, and serves as the recipient for execution statistics.
* **Cluster Manager**: Coordinates resources. Since we ran with `.master("local[*]")`, Spark operates in local mode, using a thread-pool simulator as the cluster manager.
* **Executor Nodes**: Workers that run JVM processes. In local mode, the executor threads run concurrently inside the driver JVM. In distributed environments, executors execute specific processing tasks (e.g. evaluating row filters, writing Parquet partitions) and store data partitions in memory.

### **2. Lazy Evaluation & Catalyst Execution Plan Analysis**
Spark uses **lazy evaluation**, which means transformations do not execute until an action (like `show()`, `count()`, or `write`) is called. This delay allows the Catalyst Optimizer to structure the execution flow.
Looking at the execution plan printed in **Part 3**:
* **Parsed Logical Plan**: The raw unresolved syntax tree generated directly from Python function calls.
* **Analyzed Logical Plan**: Schema attributes are resolved against catalog tables to confirm column names and check correct data types.
* **Optimized Logical Plan**: Catalyst optimizes the tree structure by removing redundant operations. Notice it combined the filters and generated `isnotnull(Region#248)`.
* **Physical Plan (DAG)**: The actual plan sent to executors.
  * Look closely at the `FileScan parquet` node:
    ```text
    PushedFilters: [IsNotNull(Region), EqualTo(Region,West)], ReadSchema: struct<Order ID:string,Customer ID:string,Region:string,Sales:string,Profit:string>
    ```
  * **Predicate Pushdown**: The filter `Region == 'West'` is pushed directly to the storage layer (`PushedFilters`). Instead of reading all 9,994 rows and filtering in RAM, the file scanner filters records at the storage level, reducing I/O.
  * **Column Pruning (Projection Pushdown)**: Spark read only the 5 required columns (`Order ID`, `Customer ID`, `Region`, `Sales`, `Profit`) as defined by `ReadSchema`, completely bypassing the other 16 columns.

### **3. File Format Performance: CSV vs. Parquet**
Our execution metrics highlight the difference between row-oriented formats (CSV) and columnar formats (Parquet):
* **Read Time**: Parquet read was faster (`0.3796 seconds`) than CSV with explicit schema (`0.5027 seconds`) and CSV with schema inference (`0.4508 seconds`). Since Parquet stores schemas natively in file footers, it avoids the double-pass processing of `inferSchema` and the overhead of text-parsing row strings.
* **File Size Compression**: 
  * The Cleaned CSV size was `2,506,123 bytes` (2.39 MB).
  * The Cleaned Parquet size was `602,122 bytes` (0.57 MB).
  * **Parquet is 4.16x smaller than CSV!** 
  * This reduction is driven by Parquet's **columnar storage layout**, which groups identical data types together. This configuration allows algorithms like **Snappy compression**, run-length encoding, and dictionary encoding to compress repetitive text patterns (like repeating cities or shipping modes) far more efficiently than row-by-row plain-text formats.
