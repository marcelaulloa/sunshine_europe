# main.tf

terraform {
  required_version = ">= 0.14"

  required_providers {
    # Cloud Run support was added on 3.3.0
    google = ">= 3.3"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# #############################################
# #               Enable API's                #
# #############################################
# Enable IAM API
resource "google_project_service" "iam" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

# Enable Artifact Registry API
resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Run API
resource "google_project_service" "cloudrun" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Resource Manager API
resource "google_project_service" "resourcemanager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Enable VCP Access API
resource "google_project_service" "vpcaccess" {
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud SQL Admin API
resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "mage_service_account" {
  account_id   = "mage-service-account"
  display_name = "Mage Service Account"
}

resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_project_iam_member" "artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_project_iam_member" "cloud_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_project_iam_member" "cloud_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_project_iam_member" "service_account_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_project_iam_member" "dataproc_editor" {
  project = var.project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_project_iam_member" "dataproc_worker" {
  project = var.project_id
  role    = "roles/dataproc.worker"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_project_iam_member" "dataproc_admin" {
  project = var.project_id
  role    = "roles/dataproc.admin"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_project_iam_member" "dataproc_gcs_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_project_iam_member" "dataproc_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_project_iam_member" "dataproc_compute_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_project_iam_member" "dataproc_dataset_full_access" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.mage_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_storage_bucket_iam_member" "bucket_admin_dataproc" {
  bucket = google_storage_bucket.mage_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_storage_bucket_iam_member" "temp_bucket_admin_dataproc" {
  bucket = google_storage_bucket.temp_mage_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = google_secret_manager_secret.sql_connection_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.mage_service_account.email}"
}

resource "google_service_account" "dataproc_service_account" {
  account_id   = "dataproc-service-account"
  display_name = "Dataproc Service Account"
}

resource "google_dataproc_cluster" "spark_cluster" {
  name   = "spark-cluster"
  region = var.region

  cluster_config {
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-2"
      disk_config {
        boot_disk_size_gb = 500  # Size of the disk in GB for master node
      }
    }

    worker_config {
      num_instances = 2
      machine_type  = "n1-standard-2"
      disk_config {
        boot_disk_size_gb = 500  # Size of the disk in GB for master node
      }
    }

    gce_cluster_config {
      service_account = google_service_account.dataproc_service_account.email
    }
  }

  depends_on = [ google_project_iam_member.dataproc_worker ]
}

resource "google_storage_bucket" "mage_bucket" {
  name          = "${var.project_id}-mage-bucket"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true
}

resource "google_storage_bucket" "temp_mage_bucket" {
  name          = "${var.project_id}-temp-mage-bucket"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true
}

resource "google_storage_bucket_object" "spark_job_files" {
  name   = "spark_job_files.py"
  bucket = google_storage_bucket.mage_bucket.name
  source = "./spark_job_files.py"
}

resource "google_storage_bucket_object" "spark_job_sources" {
  name   = "spark_job_sources.py"
  bucket = google_storage_bucket.mage_bucket.name
  source = "./spark_job_sources.py"
}

resource "google_storage_bucket_object" "spark_join_bigquery" {
  name   = "spark_join_bigquery.py"
  bucket = google_storage_bucket.mage_bucket.name
  source = "./spark_join_bigquery.py"
}

resource "google_bigquery_dataset" "sunshine_eu_dataset" {
  dataset_id = var.bq_dataset_name
  location = var.location
}

resource "google_bigquery_dataset_iam_member" "dataset_full_access" {
  dataset_id = google_bigquery_dataset.sunshine_eu_dataset.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

# Create the Cloud Run service
resource "google_cloud_run_service" "run_service" {
  name     = var.app_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.mage_service_account.email
      containers {
        image = var.docker_image
        ports {
          container_port = 6789
        }
        resources {
          limits = {
            cpu    = var.container_cpu
            memory = var.container_memory
          }
        }
        env {
          name  = "FILESTORE_IP_ADDRESS"
          value = google_filestore_instance.instance.networks[0].ip_addresses[0]
        }
        env {
          name  = "FILE_SHARE_NAME"
          value = "share1"
        }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "GCP_MAIN_BUCKET_NAME"
          value = google_storage_bucket.mage_bucket.name
        }
        env {
          name  = "GCP_TEMP_BUCKET_NAME"
          value = google_storage_bucket.temp_mage_bucket.name
        }
        env {
          name  = "GCP_REGION"
          value = var.region
        }
        env {
          name  = "GCP_SERVICE_NAME"
          value = var.app_name
        }
        env {
          name  = "MAGE_DATABASE_CONNECTION_URL"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.sql_connection_url.secret_id
              key  = "latest"
            }
          }
        }
        env {
          name  = "ULIMIT_NO_FILE"
          value = 16384
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"         = "1"
        "run.googleapis.com/cloudsql-instances"    = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/cpu-throttling"        = false
        "run.googleapis.com/execution-environment" = "gen2"
        "run.googleapis.com/vpc-access-connector"  = google_vpc_access_connector.connector.id
        "run.googleapis.com/vpc-access-egress"     = "private-ranges-only"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  metadata {
    annotations = {
      "run.googleapis.com/launch-stage" = "BETA"
      "run.googleapis.com/ingress"      = "all"
    }
  }

  autogenerate_revision_name = true

  # Waits for the Cloud Run API to be enabled
  depends_on = [google_project_service.cloudrun, google_sql_database.database]
}

# Allow unauthenticated users to invoke the service
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.run_service.name
  location = google_cloud_run_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Display the service IP
output "service_ip" {
  value = module.lb-http.external_ip
}

output "mage_url" {
  value = google_cloud_run_service.run_service.status[0].url
}
