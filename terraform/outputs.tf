output "landing_bucket" {
  description = "GCS bucket for source extracts."
  value       = google_storage_bucket.landing.name
}

output "datasets" {
  description = "BigQuery datasets created for each dbt layer."
  value       = { for k, d in google_bigquery_dataset.layer : k => d.id }
}

output "dbt_service_account" {
  description = "Service account email that dbt runs as."
  value       = google_service_account.dbt.email
}
