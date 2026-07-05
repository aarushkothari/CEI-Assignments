# Week-6 Solutions

### **Q1: Explain the roles of the Driver, Cluster Manager, and Executor in a Spark application.**

#### **Brief Insights on Performance and Architecture**:
* **Driver**: Acts as the master node coordinator. It runs the main application program, parses code, maintains the SparkSession, translates user code into a Directed Acyclic Graph (DAG) of execution stages, and distributes tasks to Executor nodes. The driver must have sufficient memory to collect execution summaries, but calling operations like `.collect()` can crash it if the data is too large.
* **Cluster Manager**: An external service (YARN, Kubernetes, Standalone, Mesos) responsible for allocating resources across the cluster. It acts as an intermediary, reserving executor containers on behalf of the Driver.
* **Executor**: Individual worker processes launched on cluster nodes. They execute tasks concurrently in separate threads, handle local data caching/storage, and send computed results back to the Driver. Scaling executors vertically (more cores/RAM per executor) or horizontally (more executors) determines the parallel execution capacity of the Spark cluster.

---

### **Q2: How does Spark’s Lazy Evaluation strategy improve performance when chain-processing large datasets?**

#### **Brief Insights on Performance and Architecture**:
* **Logical Plan Optimization**: Because Spark does not compute transformations immediately (e.g., `filter`, `select`, `join`), it can build a full Directed Acyclic Graph (DAG) representing the complete lineage of computations. 
* **Catalyst Optimizer**: Once an Action triggers execution, the Catalyst Optimizer evaluates the entire DAG and restructures the logical plan into an optimized physical plan.
* **Predicate Pushdown & Projection Pruning**: The optimizer pushes filters down to the source data reader and skips loading unused columns, minimizing disk I/O and JVM memory consumption.
* **Pipelining**: Multiple narrow transformations are combined into a single stage, allowing rows to be processed in CPU/cache memory without serialization or writing intermediate state data to local disks.

---

### **Q3: Write a Spark command to read a CSV file located at "data/source.csv", ensuring the first row is treated as a header and inferSchema is enabled.**

#### **Spark Code (PySpark)**:
```python
df_csv = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("data/source.csv")
```

#### **Execution Results**:
* **Inferred Schema**:
  ```text
  root
   |-- user_id: integer (nullable = true)
   |-- product_id: string (nullable = true)
   |-- price: double (nullable = true)
   |-- category: string (nullable = true)
   |-- old_name: string (nullable = true)
   |-- status: string (nullable = true)
   |-- amount: integer (nullable = true)
   |-- base_price: double (nullable = true)
   |-- region: string (nullable = true)
   |-- priority: string (nullable = true)
  ```
* **DataFrame Contents**:
  ```text
  +-------+----------+------+-----------+----------+---------+------+----------+------+--------+
  |user_id|product_id| price|   category|  old_name|   status|amount|base_price|region|priority|
  +-------+----------+------+-----------+----------+---------+------+----------+------+--------+
  |   1001|       P01| 120.5|Electronics|     Phone|Completed|  1500|     100.0| North|    High|
  |   1002|       P02| 15.99|      Books|     Novel|Completed|   500|      15.0| South|     Low|
  |   1003|       P03|299.99|Electronics|    Tablet|  Pending|  1200|     250.0| North|  Medium|
  |   1004|       P04|  45.0|       Home|      Lamp|Completed|  1100|      40.0|  West|    High|
  |   NULL|       P05| 89.99|Electronics|Headphones|Completed|    80|      75.0|  East|     Low|
  |   1006|       P06|1050.0|Electronics|    Laptop|Completed|  2200|    1000.0| South|    High|
  |   1007|       P07|   5.5|     Office|       Pen|Cancelled|    20|       5.0| North|     Low|
  |   1008|       P08| 799.0|Electronics|        TV|Completed|   900|     700.0|  West|  Medium|
  +-------+----------+------+-----------+----------+---------+------+----------+------+--------+
  ```

#### **Brief Insights on Performance and Architecture**:
* Enabling `inferSchema` causes Spark to execute a pre-scan job over the CSV file to determine data types. This results in **double the disk/network read operations** (one read pass to infer types, and another pass to load data). For production pipelines on large datasets, defining an explicit schema using `StructType` is faster and avoids OOM risks.

---

### **Q4: What is the difference between CSV and Parquet in terms of storage (row-based vs. columnar) and why does it matter for performance?**

#### **Brief Insights on Performance and Architecture**:
* **Storage Layout**: CSV is a text-based, row-oriented format where entire records are stored contiguously. Parquet is a binary, column-oriented format where fields belonging to the same column are stored together in row groups.
* **I/O Efficiency**: For analytical queries that select a subset of columns (e.g., `SELECT price`), Parquet reads only the data blocks containing the target columns, skipping the rest (Projection Pruning). CSV requires reading the entire line, including irrelevant fields, causing excessive I/O.
* **Compression**: Columnar values of the same type compress much better than heterogeneous row values. Parquet utilizes lightweight encodings (Dictionary encoding, Run-Length encoding) and compression (Snappy/Gzip), lowering disk footprint and read time.
* **Metadata and Statistics**: Parquet files embed schemas and column-level statistics (min/max/null counts) in their footers, enabling the reader to skip non-matching row groups before loading data into memory (Predicate Pushdown).

---

### **Q5: Given a DataFrame df, write a query to select the columns product_id and price where the category is 'Electronics'.**

#### **Spark Code (PySpark)**:
```python
df_electronics = df.select("product_id", "price").filter(df.category == "Electronics")
```

#### **Execution Results**:
```text
+----------+------+
|product_id| price|
+----------+------+
|       P01| 120.5|
|       P03|299.99|
|       P05| 89.99|
|       P06|1050.0|
|       P08| 799.0|
+----------+------+
```

#### **Brief Insights on Performance and Architecture**:
* Spark uses logical query rewriting to ensure that the filter condition is applied as early as possible (filter pushdown), reducing the volume of records that need to undergo column extraction (`select`).

---

### **Q6: Write the code to "revise" a DataFrame by renaming the column old_name to new_name and casting the price column from a String to a Double.**

#### **Spark Code (PySpark)**:
```python
from pyspark.sql import functions as F
from pyspark.sql.types import DoubleType

df_revised = df \
    .withColumnRenamed("old_name", "new_name") \
    .withColumn("price", F.col("price").cast(DoubleType()))
```

#### **Execution Results**:
* **Revised Schema**:
  ```text
  root
   |-- user_id: integer (nullable = true)
   |-- product_id: string (nullable = true)
   |-- price: double (nullable = true)
   |-- category: string (nullable = true)
   |-- new_name: string (nullable = true)
   |-- status: string (nullable = true)
   |-- amount: integer (nullable = true)
   |-- base_price: double (nullable = true)
   |-- region: string (nullable = true)
   |-- priority: string (nullable = true)
  ```
* **Sample Output (Selected columns)**:
  ```text
  +-------+----------+------+
  |user_id|  new_name| price|
  +-------+----------+------+
  |   1001|     Phone| 120.5|
  |   1002|     Novel| 15.99|
  |   1003|    Tablet|299.99|
  |   1004|      Lamp|  45.0|
  |   NULL|Headphones| 89.99|
  |   1006|    Laptop|1050.0|
  |   1007|       Pen|   5.5|
  |   1008|        TV| 799.0|
  +-------+----------+------+
  ```

#### **Brief Insights on Performance and Architecture**:
* Columns in Spark are metadata structures. Renaming columns or casting basic types are metadata-only operations that execute as **Narrow Transformations**. They require zero data shuffling across the network and are performed in-memory inside a single stage.

---

### **Q7: How does Spark use the Lineage Graph (DAG) to provide fault tolerance if a worker node fails?**

#### **Brief Insights on Performance and Architecture**:
* **Immutability**: DataFrames/RDDs are immutable, and their state cannot be changed in place. Every operation generates a new DataFrame reference.
* **Lineage Tracking**: Spark records the precise chain of transformations used to construct each DataFrame. This directed dependency map is the Lineage Graph (DAG).
* **Self-Healing Partition Recomputation**: If a worker node crashes and loses a partition of data, the Driver refers to the Lineage Graph and schedules tasks to re-evaluate *only* the missing partition from the original source block. Spark re-computes the lost partition deterministically without having to restart the entire application or replicate intermediate state across executors.

---

### **Q8: Write a query to filter a DataFrame df_orders for rows where the status is 'Completed' AND the amount is greater than 1000.**

#### **Spark Code (PySpark)**:
```python
from pyspark.sql import functions as F

df_completed_high = df_orders.filter(
    (F.col("status") == "Completed") & 
    (F.col("amount") > 1000)
)
```

#### **Execution Results**:
```text
+-------+----------+---------+------+
|user_id|product_id|   status|amount|
+-------+----------+---------+------+
|   1001|       P01|Completed|  1500|
|   1004|       P04|Completed|  1100|
|   1006|       P06|Completed|  2200|
+-------+----------+---------+------+
```

#### **Brief Insights on Performance and Architecture**:
* Combining conditions using bitwise operators (`&`) compiles into a single filter evaluation block in the physical execution engine. This narrow transformation filters records inside the input executor threads before they are cached or processed further, avoiding extra task generation.

---

### **Q9: Explain the concept of Predicate Pushdown in Parquet and how it affects the amount of data loaded into memory.**

#### **Brief Insights on Performance and Architecture**:
* **Metadata Statistics**: Parquet files are written in independent Row Groups, each writing metadata statistics (min, max, and null values) for each column in its file header.
* **Storage-Level Filtering**: When a filter is issued, Spark passes the filter expression (the predicate) down to the Parquet reader. The reader checks the row group statistics. If the condition (e.g., `amount > 1000`) falls completely outside the `[min, max]` range of a Row Group (e.g., `max(amount) = 500`), that entire Row Group is skipped.
* **Memory and Performance Impact**: Since non-matching records are excluded before they are parsed, disk I/O, network footprint, and JVM garbage collection overhead are significantly reduced, preventing memory bloating.

---

### **Q10: Write a code snippet to add a new column final_price which is the base_price multiplied by 1.18 (18% tax).**

#### **Spark Code (PySpark)**:
```python
from pyspark.sql import functions as F

df_with_tax = df.withColumn("final_price", F.col("base_price") * 1.18)
```

#### **Execution Results**:
```text
+-------+----------+------------------+
|user_id|base_price|       final_price|
+-------+----------+------------------+
|   1001|     100.0|             118.0|
|   1002|      15.0|              17.7|
|   1003|     250.0|             295.0|
|   1004|      40.0|47.199999999999996|
|   NULL|      75.0|              88.5|
|   1006|    1000.0|            1180.0|
|   1007|       5.0|5.8999999999999995|
|   1008|     700.0|             826.0|
+-------+----------+------------------+
```

#### **Brief Insights on Performance and Architecture**:
* Adding columns via scalar multiplication is a narrow, element-wise transformation. Since it does not require aggregating keys across partitions, there is no Shuffle operation, allowing it to execute at memory-to-CPU bandwidth speeds.

---

### **Q11: What is the difference between Transformations and Actions? Provide two examples of each.**

#### **Brief Insights on Performance and Architecture**:
* **Transformations (Lazy)**: Operations that define logical transformations on a DataFrame but do not execute them. They update the logical lineage graph and return a new DataFrame reference.
  * *Examples*: `.filter()`, `.groupBy()`
* **Actions (Eager)**: Operations that trigger the physical computation of the recorded transformations. They compile the DAG into physical task stages, submit them to the executors, and either return the result back to the Driver or write data to an external sink.
  * *Examples*: `.show()`, `.write`

---

### **Q12: Write the Spark command to load a Parquet file from "path/to/input", filter out any rows where user_id is null, and save the result as a CSV at "path/to/output".**

#### **Spark Code (PySpark)**:
```python
from pyspark.sql import functions as F

# Load Parquet file
df = spark.read.parquet("path/to/input")

# Filter rows where user_id is null
df_filtered = df.filter(F.col("user_id").isNotNull())

# Save as CSV
df_filtered.write \
    .option("header", "true") \
    .mode("overwrite") \
    .csv("path/to/output")
```

#### **Execution Results**:
```text
Saved CSV Content (Filtered user_id is not null):
+-------+----------+-----------+
|user_id|product_id|   category|
+-------+----------+-----------+
|   1001|       P01|Electronics|
|   1002|       P02|      Books|
|   1003|       P03|Electronics|
|   1004|       P04|       Home|
|   1006|       P06|Electronics|
|   1007|       P07|     Office|
|   1008|       P08|Electronics|
+-------+----------+-----------+
```

#### **Brief Insights on Performance and Architecture**:
* Reading from Parquet is extremely fast due to metadata-driven schema retrieval. The subsequent write operation translates to a distributed task where each executor writes its local partition as a separate CSV file segment (`part-*.csv`) inside the target directory.

---

### **Q13: In Spark Architecture, what is the difference between Client Mode and Cluster Mode?**

#### **Brief Insights on Performance and Architecture**:
* **Client Mode**: The Driver process runs on the client machine submitting the job, while the executors run on the cluster nodes. If the client machine shuts down or loses connectivity, the job crashes. This mode also introduces network latency as executors stream results back to the external client. It is primarily used for interactive debugging or development.
* **Cluster Mode**: The Driver process is executed inside a container on one of the cluster worker nodes (managed by the Cluster Manager). The submitting client machine can safely disconnect after job submission. This mode collocates the Driver with the cluster network, avoiding bandwidth bottlenecks and providing high availability (automatic master failover). It is the standard for production jobs.

---

### **Q14: Write a query to filter a dataset for rows where the region is 'North' OR the priority is 'High'.**

#### **Spark Code (PySpark)**:
```python
from pyspark.sql import functions as F

df_filtered = df.filter(
    (F.col("region") == "North") | 
    (F.col("priority") == "High")
)
```

#### **Execution Results**:
```text
+-------+----------+------+--------+
|user_id|product_id|region|priority|
+-------+----------+------+--------+
|   1001|       P01| North|    High|
|   1003|       P03| North|  Medium|
|   1004|       P04|  West|    High|
|   1006|       P06| South|    High|
|   1007|       P07| North|     Low|
+-------+----------+------+--------+
```

#### **Brief Insights on Performance and Architecture**:
* Since the filter uses an `OR` condition across different columns, Spark's physical engine evaluates both columns in memory for each record. This operation remains narrow and is executed in a single stage, preserving partition alignment.

---

### **Q15: When exploring a dataset, why is it safer to use .show(5) instead of .collect() on a multi-terabyte dataset?**

#### **Brief Insights on Performance and Architecture**:
* **OutOfMemory (OOM) Danger**: `.collect()` forces Spark to fetch every single record from all partitions across all executors and serialize them over the network to the Driver process. On multi-terabyte datasets, this overwhelms the JVM heap space allocated to the Driver, crashing the application.
* **Driver Performance Protection**: `.show(5)` fetches only the first 5 records (usually from a single local partition) and prints them in a text table, consuming minimal network bandwidth and negligible memory.
* **Execution Limit**: The Spark optimizer halts processing once the target number of rows is reached, saving cluster resources and executing almost instantly.