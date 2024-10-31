import json
import boto3 as aws
import base64
import os

s3 = aws.client('s3')
s3_bucket = os.getenv('LAB_BUCKET_NAME')

def retrieve_object(event):
    filename = event['queryStringParameters']['filename']
    print(f"Filename = {filename}")
    try:
        s3_object = s3.get_object(Bucket=s3_bucket, Key=filename)
        content_type = s3_object['ResponseMetadata']['HTTPHeaders']['content-type']
        body = s3_object['Body']
        print('Got object', content_type)
        return {
            'isBase64Encoded': True,
            'body': base64.b64encode(body.read()),
            'headers': {
                'Content-Type': content_type,
                'Content-Disposition': f"attachment; filename=\"{filename}\""
            },
            'statusCode': 200
        }
    except:
        return {
            'statusCode': 404,
            'body': json.dumps({'message': f"Object {filename} not found"})
        }


def put_object(event):
    filename = event['queryStringParameters']['filename']
    try:
        file = event['body']
        file_decoded = base64.b64decode(file)
        
        s3.put_object(Bucket=s3_bucket, Key=filename, Body=file_decoded)
        
        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'Created.'})
        }
    except:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Cannot create object.'})
        }


def lambda_handler(event, context):
    if event['httpMethod'] == 'GET':
        return retrieve_object(event)
    
    if event['httpMethod'] == 'POST':
        return put_object(event)
        
    return {
        'statusCode': 404,
        'body': json.dumps({'message': 'Not valid method!'})
    }

