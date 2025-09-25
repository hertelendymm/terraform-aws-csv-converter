"""
This AWS Lambda function is triggered by an S3 event
It reads a CSV file from the source S3 bucket, converts it to JSON format, and uploads the resulting JSON file to a destination S3 bucket
"""

import json
import boto3
import os
import csv
import logging
from typing import List, Dict

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    logger.info("## EVENT RECEIVED")
    logger.info(json.dumps(event))

    try:
        source_bucket_name = event['Records'][0]['s3']['bucket']['name']
        source_object_key = event['Records'][0]['s3']['object']['key']
    except KeyError as e:
        logger.error(f"Error extracting bucket or key from event: {e}")
        return {'statusCode': 400, 'body': json.dumps('Invalid S3 event format.')}

    destination_bucket_name = os.environ.get('DESTINATION_BUCKET_NAME')
    if not destination_bucket_name:
        logger.error("Error: DESTINATION_BUCKET_NAME environment variable not set.")
        return {'statusCode': 500, 'body': json.dumps('Server-side configuration error.')}

    local_file_path = f'/tmp/{os.path.basename(source_object_key)}'

    try:
        s3 = boto3.client('s3')
        logger.info(f"Downloading s3://{source_bucket_name}/{source_object_key} to {local_file_path}")
        s3.download_file(source_bucket_name, source_object_key, local_file_path)

        list_of_rows: List[Dict[str, str]] = []
        with open(local_file_path, 'r', encoding='utf-8-sig') as csv_file:
            csv_reader = csv.DictReader(csv_file)
            for row in csv_reader:
                list_of_rows.append(row)
        
        
        destination_object_key = f"{os.path.splitext(source_object_key)[0]}.json"
        
        logger.info(f"Uploading {destination_object_key} to s3://{destination_bucket_name}/")
        s3.put_object(
            Bucket=destination_bucket_name,
            Key=destination_object_key,
            Body=json.dumps(list_of_rows, indent=4),
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

