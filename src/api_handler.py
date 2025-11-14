import json
import boto3
import os
import logging
from botocore.exceptions import ClientError
import boto3.session

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# s3_client = boto3.client('s3')
s3_client = boto3.client('s3', config=boto3.session.Config(s3={'addressing_style': 'path'}))

SOURCE_BUCKET = os.environ.get('SOURCE_BUCKET_NAME')
DEST_BUCKET = os.environ.get('DESTINATION_BUCKET_NAME')
FRONTEND_DOMAIN = os.environ.get('FRONTEND_DOMAIN', '*')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    route_key = event.get('routeKey')
    
    headers = {
        "Access-Control-Allow-Origin": FRONTEND_DOMAIN, 
        "Access-Control-Allow-Methods": "GET,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type"
    }

    try:
        if route_key == "GET /files":
            response = s3_client.list_objects_v2(Bucket=DEST_BUCKET)
            files = [
                obj['Key'] for obj in response.get('Contents', []) 
                if obj['Key'].endswith('.json')
            ]
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps(files)
            }

        elif route_key == "GET /files/{fileName}/upload":
            file_name = event.get('pathParameters', {}).get('fileName')
            if not file_name:
                raise ValueError("fileName not found in path")

            presigned_url = s3_client.generate_presigned_url(
                'put_object',
                Params={'Bucket': SOURCE_BUCKET, 'Key': file_name, 'ContentType': 'text/csv'},
                ExpiresIn=300,  
            )
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'uploadUrl': presigned_url})
            }

        elif route_key == "GET /files/{fileName}/download":
            file_name = event.get('pathParameters', {}).get('fileName')
            if not file_name:
                raise ValueError("fileName not found in path")

            presigned_url = s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': DEST_BUCKET, 'Key': file_name},
                ExpiresIn=300 
            )
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'downloadUrl': presigned_url})
            }

        else:
            if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
                return {
                    'statusCode': 200,
                    'headers': headers
                }
            
            raise ValueError(f"Unsupported route: {route_key}")

    except Exception as e:
        logger.error(f"Error: {e}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }