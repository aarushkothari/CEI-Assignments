# Delta Lake Incremental Data Processing Assignment

## Objective
Perform incremental data processing using Delta Lake via PySpark on the `Sample - Superstore` dataset. This assignment demonstrates loading data, performing basic cleaning, simulating incremental updates (SCD Type 1 logic), and validating the results.

## Steps Performed
1. **Load Data**: Ingested the `Sample - Superstore.csv` dataset. To simulate an incremental pipeline, we split the data: the first 8000 rows were used as the initial load, and the remaining rows were kept as new records.
2. **Basic Cleaning**: Handled null values (e.g., `Postal Code`) and removed duplicate records based on `Row ID`. The cleaned initial data was written to a Delta table.
3. **Incremental Data Simulation**: Created an incremental dataset by taking a subset of the initial records and updating their `Ship Mode` to "Same Day" (representing updates), and merged them with the new records (representing inserts).
4. **MERGE Operation**: Used Delta Lake's `MERGE` to perform upserts using `Row ID` as the key, updating existing records when matched and inserting when not matched.
5. **Validation**: Verified the final row counts, ensured there were no duplicates, and confirmed that the updates were successfully applied.
6. **Output**: Displayed portions of the final merged dataset to verify both inserts and updates.

## Folder Structure
- `data/`: Contains the `Sample - Superstore.csv` dataset.
- `notebooks/`: Contains the Jupyter notebook `delta_scd_assignment.ipynb` with the PySpark logic.
- `screenshots/`: Reserved for capturing output from each step.
- `report/`: Contains optional summary reports.

## Setup Instructions
Ensure you have `pyspark` and `delta-spark` installed:
```bash
pip install pyspark delta-spark
```
Run the notebook within `notebooks/delta_scd_assignment.ipynb`.
