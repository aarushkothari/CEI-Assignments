# Project Summary: Azure Data Pipeline Implementation

This document provides a brief executive summary of the end-to-end data pipeline built using Azure Storage and Azure Data Factory.

---

## 1. Pipeline Architecture & Flow

The pipeline orchestrates secure, validated data movement between Azure Blob Storage containers:

```
[Azure Storage: source/Sample - Superstore.csv]
                   │
                   ▼ (Get Metadata)
          [validate_source]  ── (Success?) ──► [Copy_data] (Copy Data)
                                                   │
                                                   ▼
                                         [Azure Storage: dest/processed_data.csv]
```

- **Source Container**: `source` (file: `Sample - Superstore.csv`, size: 2.28 MB)
- **Orchestrator**: Azure Data Factory (`ceiadfpipeline`)
- **Validation Activity**: `validate_source` (Get Metadata checking presence, size, and column count)
- **Data Movement Activity**: `Copy_data` (Copy Data writing file to sink container)
- **Destination Container**: `dest` (file: `processed_data.csv`)

---

## 2. Pipeline Execution Metrics

The execution was verified via a triggered manual run:

- **Run ID**: `8f4b009e-711e-450f-a42d-20982c7f55b9`
- **Execution Status**: `Succeeded`
- **Total Duration**: `11 seconds` (excluding queue times)
- **Integration Runtime**: `AutoResolveIntegrationRuntime (Central India)`

### Activity Breakdown

| Activity Name | Type | Status | Duration | Metrics |
| :--- | :--- | :--- | :--- | :--- |
| **validate_source** | Get Metadata | `Succeeded` | 1 second | Verified file exists, size = 2287806 bytes, columns = 21 |
| **Copy_data** | Copy Data | `Succeeded` | 10 seconds | Copied 1 file, size = 2.28 MB, throughput = 1143.903 KB/s, DIUs = 4 |

---

## 3. Key Security & Compliance Implementation

1. **System-Assigned Managed Identity**: Passwordless authentication was configured between Azure Data Factory and the Storage Account. ADF authenticates directly using its Azure AD identity.
2. **Least-Privilege Access Control (RBAC)**: Assigned the ADF managed identity to the **Storage Blob Data Contributor** role on the storage account (`ceidatapipeline`), ensuring no connection strings or access keys are hardcoded in the Linked Service.
3. **Azure Policy Alignment**: Resolved region compliance restrictions (`RequestDisallowedByAzure`) by deploying resources within allowed regional boundaries (Central India).
