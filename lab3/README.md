<h1>Laboratory 3</h1>

---

Create a CloudFormation template to launch an API Gateway that points to a Lambda function. The Lambda function should connect to an S3 bucket to upload and download files.

---

The template contains the following resources:
 - Lambda (+ Execution Role (with ```inline``` policies for S3 and CW logs access) + CW Logs Group)
 - API Gateway (RestApi + Methods + Stage + Deployment)
 - Resource Based Policy for Lambda to allow GET/POST requests from API Gateway
 - S3 Bucket, which stores files

Parameters:
 - LambdaName - name for the Lambda function (transforms into ```${LambdaName}Function```)
 - ApiName - name for your API Gateway
 - ApiStageName - name for your stage in API Gateway (default 'prod')
 - S3Name - name for your Bucket where the files will be stored

Additional parameters:
 - CodeS3Name - Bucket with Lambda code
 - CodeObjectName - name of the object, that contains Lambda code (```function.zip``` as default)
 - CodeVersion - Object's version (required): this value should be updated after uploading the next version of code to S3 so that CloudFormation can detect the change.

---

API endpoints:
 - ```/file``` - handles uploads/downloads.
   - POST: upload file. ```filename``` query param is **required**, because no DynamoDB were used to store.
   - GET: retrieves file. ```filename``` query param is **required**, because no DynamoDB were used to store.
