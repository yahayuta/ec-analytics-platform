locals {
  labels = {
    app        = "ec-analytics-platform"
    managed_by = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Landing zone: source extracts (CSV / JSON) are dropped here before loading.
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "landing" {
  name                        = "${var.project_id}-ec-landing"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.labels

  lifecycle_rule {
    condition {
      age = var.raw_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

# ---------------------------------------------------------------------------
# BigQuery datasets: one per dbt layer.
# ---------------------------------------------------------------------------
resource "google_bigquery_dataset" "layer" {
  for_each = var.datasets

  dataset_id  = each.key
  description = each.value
  location    = var.bq_location
  labels      = merge(local.labels, { layer = each.key })
}

# ---------------------------------------------------------------------------
# Service account used by dbt (CI/CD or a scheduler) to build models.
# Least privilege: run jobs in the project, edit only the platform datasets.
# ---------------------------------------------------------------------------
resource "google_service_account" "dbt" {
  account_id   = "dbt-runner"
  display_name = "dbt runner for ec-analytics-platform"
}

resource "google_project_iam_member" "dbt_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_editor" {
  for_each = google_bigquery_dataset.layer

  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_storage_bucket_iam_member" "dbt_landing_reader" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dbt.email}"
}

# Analysts and BI tools read only the business-facing layer.
resource "google_bigquery_dataset_iam_member" "analyst_marts_viewer" {
  count = var.analyst_group == "" ? 0 : 1

  dataset_id = google_bigquery_dataset.layer["marts"].dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:${var.analyst_group}"
}
