variable "project_id" {
  description = "Google Cloud project that hosts the analytics platform."
  type        = string
}

variable "region" {
  description = "Region for the landing bucket."
  type        = string
  default     = "asia-northeast1"
}

variable "bq_location" {
  description = "BigQuery dataset location."
  type        = string
  default     = "asia-northeast1"
}

variable "datasets" {
  description = "BigQuery datasets, one per dbt layer."
  type        = map(string)
  default = {
    raw          = "Raw data loaded as-is from source systems"
    staging      = "Cleaned, deduplicated, one-to-one with sources (dbt views)"
    intermediate = "Reusable joins and business logic (dbt views)"
    marts        = "Business-facing facts, dimensions and KPI tables (dbt tables)"
  }
}

variable "analyst_group" {
  description = "Google group that gets read access to the marts dataset (optional)."
  type        = string
  default     = ""
}

variable "raw_retention_days" {
  description = "Days to keep files in the landing bucket before deletion."
  type        = number
  default     = 90
}
