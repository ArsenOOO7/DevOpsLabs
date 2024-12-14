<h1>Laboratory 4</h1>

---

Create a **Terraform** template to launch an API Gateway that points to a Lambda function. The Lambda function should connect to an S3 bucket to upload and download files.

---

The template contains the following resources:
 - Lambda (+ Execution Role (with ```inline``` policies for S3 and CW logs access) + CW Logs Group)
 - API Gateway (RestApi + Methods + Stage + Deployment)
 - Resource Based Policy for Lambda to allow GET/POST requests from API Gateway
 - S3 Bucket, which stores files

Parameters:
 - lambda_name - name for the Lambda function (transforms into ```${LambdaName}Function```)
 - api_name - name for your API Gateway
 - api_stage_name - name for your stage in API Gateway (default 'prod')
 - code_s3_name - name for your Bucket where the files will be stored
 - api_mapping - path for you api (```/file```)

Additional parameters:
 - code_s3_name - Bucket with Lambda code
 - code_object_name - name of the object, that contains Lambda code (```function.zip``` as default)
 - code_version - Object's version (required): this value should be updated after uploading the next version of code to S3 so that CloudFormation can detect the change.

---

[API URL](https://6xv880kkh1.execute-api.eu-central-1.amazonaws.com/prod/file?filename=google.png)

API endpoints:
 - ```/file``` - handles uploads/downloads.
   - POST: upload file. ```filename``` query param is **required**, because no DynamoDB were used to store (works with **binary**).
![зображення](https://github.com/user-attachments/assets/94c11883-3cb8-498b-97ed-8c3e85836cac)


   - GET: retrieves file. ```filename``` query param is **required**, because no DynamoDB were used to store.
