from google.cloud import dataproc_v1
from google.cloud.dataproc_v1 import JobControllerClient
import time
import os

if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


project_id = os.environ.get('GCP_PROJECT_ID')
region = os.environ.get('GCP_REGION')
cluster_name = 'spark-cluster'
bucket_name = os.environ.get('GCP_MAIN_BUCKET_NAME')
pyspark_file_uri = f'gs://{bucket_name}/spark_job_sources.py'

def get_job_status(project_id, region, job_id):
    # Create a client
    client = dataproc_v1.JobControllerClient(client_options={
        'api_endpoint': f'{region}-dataproc.googleapis.com:443'
    })

    # Initialize request argument(s)
    request = dataproc_v1.GetJobRequest(
        project_id=project_id,
        region=region,
        job_id=job_id,
    )

    while True:
        job = client.get_job(request=request)
        print(f"Job status: {job.status}")
        # Check job status
        if job.status.state in [dataproc_v1.types.JobStatus.State.ERROR,
                                dataproc_v1.types.JobStatus.State.CANCELLED,
                                dataproc_v1.types.JobStatus.State.DONE]:
            return job.status.state
        # Sleep for a bit before checking again
        time.sleep(10)

def submit_pyspark_job():
    
     # Instantiate the client with the endpoint for your region
    client = JobControllerClient(client_options={
        'api_endpoint': f'{region}-dataproc.googleapis.com:443'
    })

    # Prepare the job configuration
    job = {
        'placement': {
            'cluster_name': cluster_name
        },
        'pyspark_job': {
            'main_python_file_uri': pyspark_file_uri,
            'args': [bucket_name]
        }
    }

    # Submit the job
    result = client.submit_job(project_id=project_id, region=region, job=job)
    job_id = result.reference.job_id
    print(f"Submitted job ID {job_id}")

    # Monitor job status
    job_status = get_job_status(project_id, region, job_id)
    print(f"Job completed with status: {job_status}")
    return job_status


@transformer
def transform(data, *args, **kwargs):
    job_status = submit_pyspark_job()

    return True


@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output, 'The output is undefined'
