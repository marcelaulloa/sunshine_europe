# Where the sun shines in Europe?

## Objective - Problem description
Data engineering project to analyze data from several meteorological stations in Europe to see how much sunshine each country gets per year.

## Data Source Explained
The dataset choosen was the Daily Sunshine duration from the [European Climate Assessment & Dataset project](https://www.ecad.eu/). How to find the dataset:
Daily Data > Download predefined subsets (ASCII) > Daily sunshine duration SS

The data comes in a zip folder containing several .txt files. The majority of the files contain the same column structure: 
- STAID: Station identifier
- SOUID: Source identifier
- DATE : Date YYYYMMDD
- SS   : Sunshine in 0.1 Hours
- Q_SS : quality code for SS (0='valid'; 1='suspect'; 9='missing')

In the same zip file there is also a reference file called "sources.txt". This file contains the following columns:
- STAID  : Station identifier
- SOUID  : Source identifier
- SOUNAME: Source name
- CN     : Country code (ISO3116 country codes)
- LAT    : Latitude in degrees:minutes:seconds (+: North, -: South)
- LON    : Longitude in degrees:minutes:seconds (+: East, -: West)
- HGTH   : Station elevation in meters
- ELEI   : Element identifier (see website at Daily Data > Data dictionary > Elements)
- START  : Begin date YYYYMMDD
- STOP   : End date YYYYMMDD
- PARID  : Participant identifier
- PARNAME: Participant name

For the sake of simplicity I'm only using the Station Id and the Country Code form the sources.txt.

## Project Pipeline Explained
1. Terraform will create all resources necessary for the project, which are:
    - 1 bucket on Google Cloud Storage to save our data.
    - 1 dataset on BigQuery.
    - 1 spark Cluster.
    - Another bucket to be used by Spark jobs.
    - All resources to be use by Mage to run in the cloud. 
    Finally it will also upload the pyspark files into Google Cloud Storage, in the same bucket we just created.
2. On mage we have the data pipeline that consists of:
**Data Ingestion**
- A data loader that downloads the zip file and extract the data files to the bucket. (load_zip_files.py)
- A data loader that separates the sources.txt file and also save it in the bucket.(sources_load.py)
**Data Transformation via Spark**
- A data transformer that submits a spark job with data transformations for all files with the same structure. (spark_transform.py)
- A data transformer that submits a spark job with data transformations for the sources file. (spark_job_sources.py)
- A final data transformer that submits a spark job that joins the dataset to the sources table a saves it in BigQuery. (spark_job_sources.py)

- Each of the above transformers will submit a python script to run in the cluster to run transformation using PySpark.

## Technologies
Cloud : GCP
IaC : Terraform for making Bucket in GCS, running Mage on the cloud and creating dataset on BigQuery
Workflow orchestration : Mage
Data Warehouse : BigQuery

## Dashboard
The dashboard tries to answer some basic questions regarding the average sunshine duration by country. 
[Dashboard link.](https://lookerstudio.google.com/reporting/7c37008d-cda1-4ec0-a15d-e1a2b62d78ad/page/CPywD)

![Dashboard](../image/dashboard.png)

## Steps to replicate project

1. Create a project in Google Cloud

2. Edit `variables.tf` to set the `project_id` variable with your own project id. The bucket name will be a variation of your project id + `-mage-bucket`.

3. Edit `region` and `zone` if you want to run outside `europe-central2`

4. If not yet installed, [install Google Cloud CLI](https://cloud.google.com/sdk/docs/install).

5. Log into your gcloud account from the cli and choose the new project to work with:

```
$ gcloud init
$ gcloud auth application-default login
```

6. Run `enable_apis.sh` to make sure the necessary Google Cloud APIs are enabled for this project

```
$ ./enable_apis.sh
```
It might take some time until you start seeing several lines in the terminal indicatin "finish successfully".

Alternative:
If your computer doesn't have a bash shell (like on Windows), you can go to the Google Cloud console, go to `APIs & Services` and manually make sure the following APIs are enabled:
    - Cloud Filestore API
    - Serverless VPC Access API
    - Compute Engine API
    - Cloud SQL Admin API
    - Cloud Resource Manager API
    - Cloud Dataproc API
    - Cloud Run Admin API

7. If not yet installed, [install Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

8. Initialize terraform

```
$ terraform init
```
```
$ terraform plan
```

9. Deploy

```
$ terraform apply
```

A sample output could look like this:

```
Apply complete! Resources: 7 added, 1 changed, 0 destroyed.
Outputs:
mage_url = "https://some-project-fv5conazwa-lm.a.run.app"
service_ip = "34.107.187.208"
```
**In case of the following policy quota error:**
```
│ Error: Error waiting for Creating SecurityPolicy "mage-test-security-policy": Quota 'SECURITY_POLICY_RULES' exceeded.  Limit: 0.0 globally.
│       metric name = compute.googleapis.com/security_policy_rules
│       limit name = SECURITY-POLICY-RULES-per-project
│       dimensions = map[global:global]
│ 
│ 
│   with google_compute_security_policy.policy,
│   on load_balancer.tf line 7, in resource "google_compute_security_policy" "policy":
│    7: resource "google_compute_security_policy" "policy" {
```
You can still open Mage and all your resources should have been created. 
    a. Go to you Google Cloud Console and go to "Cloud Run". 
    b. Find the mage-test service and click on it.
    c. Find the link to your mage instance, it should look something like this:
        URL: https://mage-test-jdeghisoas-lm.a.run.app 
    d. Continue on the next steps.

10. Set up the pipeline

You can now point at the URL specified by `mage_url` in the terraform output.

Once there, click on the `New Pipeline` button and then "Import pipeline zip". 
Upload the `pipeline.zip` file from this repository.

11. Run the pipeline

Go to the `Pipelines` option on the left menu and click on the `process_zip` one.

Click on the `Run once` button and then `Run now`.

Click on the created run (it'll have a random name) 

Click on the running run and follow the execution. The full pipeline should take around 10 minutes to run.

12. What you should see in your project after running the Pipeline:

On Google Storage 
Bucket: project id + `-mage-bucket`
- A folder called raw with all .txt files
- A folder called spark with processed data
- A folder called spark_sources with the sources files processed.
Bicket: project id + `-temp-mage-bucket`
- Should be empty it was only temeporaly used by the spark cluster to save the data to bigquery.

On BigQuery:
- A dataset called: `sunshine_eu_dataset`
- A table inside the dataset called `report`

12. Dashboard

You have two options: 
1. Copy my dashboard and update the dataset doing the following:
- &emsp;Go to [my dashboard](https://lookerstudio.google.com/reporting/7c37008d-cda1-4ec0-a15d-e1a2b62d78ad/page/CPywD) and click on "Make a Copy".
- &emsp;n your copy click on the top menu called "Resource", choose "Manage added data sources"
- &emsp;Under actions click edit.
- &emsp;If it's your first dashboard with bigquery it will ask you to authorize to connect to your BigQuery projects.
- &emsp;Click on "my projects" option and find your recently created project, dataset and the table "report"
- &emsp;Click reconnect.
- &emsp;Apply.
- &emsp;Done!

2. Create your dashboard from scratch doing the following:
- &emsp;Manually create a new report on [Looker Studio](https://lookerstudio.google.com/).
- &emsp;On the first screen after creating a new report the system will ask you to add data to your report.
- &emsp;Choose Google BigQuery find your project, your dataset and the table report.
- &emsp;Add a field calculating the average of Sun_hrs.
- &emsp;Add a field for calculating seasons with the following formula: `if((month(DATE)<3)AND(day(DATE)<=20),"Winter",if((month(DATE)<6)AND(day(DATE)<=21),"Spring",if((month(DATE)<3)AND(day(DATE)<=23),"Autumn","Summer")))`
- Create:
- &emsp;1 Map with Country Code on dimensions and Avg of Sun hrs on the metrics
- &emsp;1 Bar grah with record count on the metrics and country code as dimensions
- &emsp;1 Bar graph with average sun hrs on metrics and country code as dimensions an drill-down dimensions for color coding.
- &emsp;1 Pivot Table with Heatmap with Seasons on column dimension and country code on row dimension and average sun hrs on metrics.
    
13. Cleaning up

You need to manually delete thee `sunshine_eu_dataset`, which you can find in the GCP console by clicking in the `BigQuery` section and expanding your project's name. 

Then you can destroy the other resources created in the project by doing:

```
$ terraform destroy
```

It's possible that deleting the database might fail. You need to wait a few minutes and try `terraform destroy` again if that's the case.