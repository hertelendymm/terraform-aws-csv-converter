import json
import boto3
import os
import csv
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    This function is triggered by an S3 event. It reads a CSV file from the
    source S3 bucket, converts it to JSON format, and uploads the resulting
    JSON file to a destination S3 bucket.
    """
    logger.info("## EVENT RECEIVED")
    logger.info(json.dumps(event))

    # Get the S3 bucket and object key from the S3 event record
    try:
        source_bucket_name = event['Records'][0]['s3']['bucket']['name']
        source_object_key = event['Records'][0]['s3']['object']['key']
    except KeyError as e:
        logger.error(f"Error extracting bucket or key from event: {e}")
        return {'statusCode': 400, 'body': json.dumps('Invalid S3 event format.')}

    # The destination bucket is passed in as an environment variable
    destination_bucket_name = os.environ.get('DESTINATION_BUCKET_NAME')
    if not destination_bucket_name:
        logger.error("Error: DESTINATION_BUCKET_NAME environment variable not set.")
        return {'statusCode': 500, 'body': json.dumps('Server-side configuration error.')}

    # The Lambda execution environment provides a temporary writable directory at /tmp
    local_file_path = f'/tmp/{os.path.basename(source_object_key)}'

    try:
        # 1. Download the CSV file from the source S3 bucket
        s3 = boto3.client('s3')
        logger.info(f"Downloading s3://{source_bucket_name}/{source_object_key} to {local_file_path}")
        s3.download_file(source_bucket_name, source_object_key, local_file_path)

        # 2. Read the CSV file and convert it to a list of dictionaries
        data = []
        with open(local_file_path, 'r', encoding='utf-8-sig') as csv_file:
            csv_reader = csv.DictReader(csv_file)
            for row in csv_reader:
                data.append(row)
        
        # 3. Convert the list of dictionaries to a JSON string
        json_data = json.dumps(data, indent=4)
        
        # 4. Upload the JSON data to the destination S3 bucket. Create a new key with a .json extension
        destination_object_key = f"{os.path.splitext(source_object_key)[0]}.json"
        
        logger.info(f"Uploading {destination_object_key} to s3://{destination_bucket_name}/")
        s3.put_object(
            Bucket=destination_bucket_name,
            Key=destination_object_key,
            Body=json_data,
            ContentType='application/json'
        )

    except Exception as e:
        logger.error(f"An error occurred: {e}")
        return {'statusCode': 500, 'body': json.dumps(f'Error processing file: {e}')}

    logger.info("## SUCCESS")
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully converted s3://{source_bucket_name}/{source_object_key} to s3://{destination_bucket_name}/{destination_object_key}')
    }

