#!/bin/bash

# Enable Cloud Filestore API
gcloud services enable file.googleapis.com

# Enable Serverless VPC Access API
gcloud services enable vpcaccess.googleapis.com

# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Enable Cloud SQL Admin API
gcloud services enable sqladmin.googleapis.com

# Enable Cloud Resource Manager API
gcloud services enable cloudresourcemanager.googleapis.com

# Enable Cloud Dataproc API
gcloud services enable dataproc.googleapis.com

# Enable Cloud Run Admin API
gcloud services enable run.googleapis.com

# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com