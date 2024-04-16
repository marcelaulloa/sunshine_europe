variable "app_name" {
  type        = string
  description = "Application Name"
  default     = "mage-test"
}

variable "container_cpu" {
  description = "Container cpu"
  default     = "2000m"
}

variable "container_memory" {
  description = "Container memory"
  default     = "2G"
}

variable "project_id" {
  type        = string
  description = "The name of the project"
  default     = "sunshine-europe-project"
}

variable "location" {
  description = "Project Location"
  default     = "EU"
}

variable "region" {
  type        = string
  description = "The default compute region"
  default     = "europe-central2"
}

variable "zone" {
  type        = string
  description = "The default compute zone"
  default     = "europe-central2-a"
}

variable "repository" {
  type        = string
  description = "The name of the Artifact Registry repository to be created"
  default     = "mage-data-prep"
}

variable "database_user" {
  type        = string
  description = "The username of the Postgres database."
  default     = "mageuser"
}

variable "docker_image" {
  type        = string
  description = "The docker image to deploy to Cloud Run."
  default     = "mageai/mageai:latest"
}

variable "domain" {
  description = "Domain name to run the load balancer on. Used if `ssl` is `true`."
  type        = string
  default     = ""
}

variable "ssl" {
  description = "Run load balancer on HTTPS and provision managed certificate with provided `domain`."
  type        = bool
  default     = false
}

variable "bq_dataset_name" {
  description = "My Big Query Dataset Name"
  default     = "sunshine_eu_dataset"
}