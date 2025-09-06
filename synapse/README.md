# Synapse / ADF Artifacts (Design-Only)

This folder holds **design artifacts** for Azure Data Factory (ADF) / Synapse pipelines.
They are **not deployed by Terraform**. Instead, they are JSON definitions that show
how raw → staging data movement would be modeled.

## Structure

- `linkedServices/`
  - **LS_Blob_MI.json**  
    Linked Service to Blob Storage using the Data Factory's Managed Identity.

- `datasets/`
  - **DS_Blob_Raw.json**  
    Dataset pointing to the `raw` container.  
  - **DS_Blob_Staging.json**  
    Dataset pointing to the `staging` container.

- `pipelines/`
  - **PL_Copy_Raw_to_Staging.json**  
    Pipeline with one Copy activity: moves data from `DS_Blob_Raw` → `DS_Blob_Staging`.

- `triggers/` *(optional, later)*  
  - **TR_Manual_Disabled.json**  
    Manual trigger referencing the pipeline, disabled by default.

## Flow (simplified)


## Notes

- All artifacts are **design-only**: they can be published into the ADF factory later
  using a script or ADF Git integration.
- Terraform only provisions the **ADF factory shell** and underlying infra (storage, VNet, PE, DNS, RBAC).