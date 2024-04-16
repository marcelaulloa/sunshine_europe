# db.tf | Database Configuration

resource "google_sql_database_instance" "instance" {
    name                = "${var.app_name}-db-instance"
    region              = var.region
    database_version    = "POSTGRES_14"
    deletion_protection = false
    settings {
        tier            = "db-f1-micro"
        database_flags {
            name  = "max_connections"
            value = "50"
        }
    }
}

resource "google_sql_database" "database" {
    name                = "${var.app_name}-db"
    instance            = google_sql_database_instance.instance.name
    depends_on = [ google_sql_user.database-user ]
}

provider "random" {
  # Configuration options, if any
}

resource "random_password" "sql_password" {
  length  = 16
  special = true
}

locals {
  connection_string = "postgresql://${var.database_user}:${random_password.sql_password.result}@/${var.app_name}-db?host=/cloudsql/${google_sql_database_instance.instance.connection_name}"
}

resource "google_secret_manager_secret" "sql_connection_url" {
  secret_id = "sql-connection-url"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "sql_connection_url_version" {
  secret      = google_secret_manager_secret.sql_connection_url.id
  secret_data = local.connection_string
}

resource "google_sql_user" "database-user" {
    name        = var.database_user
    instance    = google_sql_database_instance.instance.name
    password    = random_password.sql_password.result
    deletion_policy = "ABANDON"
}
