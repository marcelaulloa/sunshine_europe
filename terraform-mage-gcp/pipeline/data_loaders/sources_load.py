import requests
import zipfile
import io
import pandas as pd
import os
from google.cloud import storage


bucket_name = os.environ.get('GCP_MAIN_BUCKET_NAME')
zip_url = "https://knmi-ecad-assets-prd.s3.amazonaws.com/download/ECA_blend_ss.zip"

def stream_and_unzip_to_gcs():
    # Initialize GCS Client
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    # Stream download the ZIP file
    response = requests.get(zip_url, stream=True)
    zip_stream = io.BytesIO()
    
    for chunk in response.iter_content(chunk_size=8192):
        zip_stream.write(chunk)
    
    # Go to the beginning of the stream
    zip_stream.seek(0)
    
    with zipfile.ZipFile(zip_stream, 'r') as zfile:
        for file_info in zfile.infolist():
            if not file_info.filename.startswith("sources") or not file_info.filename.endswith(".txt"):
                continue
            csv_filename = file_info.filename.replace(".txt", ".csv")

            # Read the file data from the zip file
            with zfile.open(file_info.filename) as file:
                # Read the content as text and decode if necessary
                file_data = file.read().decode('utf-8')

            # Split into lines and skip the first 21 lines
            lines = [line for line in file_data.splitlines()[23:] if len(line.strip()) > 0 and line.split(",")[8] >= "19000101" and line.split(",")[9] >= "19000101"]
            content_to_upload = "\n".join(lines).replace(" ", "")

            # Create a blob and upload the content
            blob = bucket.blob(f'sources/{csv_filename}')
            blob.upload_from_string(content_to_upload)
            print(f'Uploaded {file_info.filename} to sources/{csv_filename}')


@data_loader
def load_data_from_api(**kwargs) -> bool:
    """
    Template for loading data from API
    """

    stream_and_unzip_to_gcs()

    return True


@test
def test_output(result) -> None:
    """
    Template code for testing the output of the block.
    """
    assert result, 'The output is undefined'
