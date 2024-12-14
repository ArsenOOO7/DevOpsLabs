terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "lambda_name" {
  default = "MyLabTestTerraform"
}

variable "api_name" {
  default = "MyLabTestApiTerraform"
}

variable "api_mapping" {
  default = "file"
}

variable "api_stage_name" {
  default = "prod"
}

variable "s3_name" {
  default = "my-lab-test-bucket-terraform"
}

variable "code_s3_name" {
  default = "my-s3-demo-course"
}

variable "code_object_key" {
  default = "function.zip"
}

variable "code_version" {}

resource "aws_iam_role" "lambda_execution_role_terraform" {
  name               = "${var.lambda_name}FunctionRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_s3_policy_terraform" {
  name   = "${var.lambda_name}FunctionS3Policy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.s3_name}",
          "arn:aws:s3:::${var.s3_name}/*"
        ]
      }
    ]
  })
  role   = aws_iam_role.lambda_execution_role_terraform.id
}

resource "aws_iam_role_policy" "lambda_cw_policy_terraform" {
  name   = "${var.lambda_name}FunctionCWPolicy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "log:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.lambda_name}Function:*"
      }
    ]
  })
  role   = aws_iam_role.lambda_execution_role_terraform.id
}

resource "aws_lambda_function" "lab_lambda_function_terraform" {
  function_name = "${var.lambda_name}Function"
  role          = aws_iam_role.lambda_execution_role_terraform.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 128
  timeout       = 3
  environment {
    variables = {
      LAB_BUCKET_NAME = var.s3_name
    }
  }

  s3_bucket         = var.code_s3_name
  s3_key            = var.code_object_key
  s3_object_version = var.code_version
}

resource "aws_cloudwatch_log_group" "lab_lambda_log_group_terraform" {
  name              = "/aws/lambda/${var.lambda_name}Function"
  retention_in_days = 14
}

resource "aws_s3_bucket" "lab_s3_bucket_terraform" {
  bucket = var.s3_name
}

resource "aws_api_gateway_rest_api" "lab_api_gateway_terraform" {
  name               = var.api_name
  binary_media_types = ["*/*"]
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "file_path_terraform" {
  parent_id   = aws_api_gateway_rest_api.lab_api_gateway_terraform.root_resource_id
  path_part   = var.api_mapping
  rest_api_id = aws_api_gateway_rest_api.lab_api_gateway_terraform.id
}

resource "aws_api_gateway_method" "post_method_terraform" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.file_path_terraform.id
  rest_api_id   = aws_api_gateway_rest_api.lab_api_gateway_terraform.id

  request_parameters = {
    "method.request.querystring.filename" = true
  }
}

resource "aws_api_gateway_integration" "post_integration" {
  http_method = aws_api_gateway_method.post_method_terraform.http_method
  resource_id = aws_api_gateway_resource.file_path_terraform.id
  rest_api_id = aws_api_gateway_rest_api.lab_api_gateway_terraform.id
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.lab_lambda_function_terraform.invoke_arn
}

resource "aws_api_gateway_method" "get_method_terraform" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.file_path_terraform.id
  rest_api_id   = aws_api_gateway_rest_api.lab_api_gateway_terraform.id

  request_parameters = {
    "method.request.querystring.filename" = true
  }
}

resource "aws_api_gateway_integration" "get_integration" {
  http_method = aws_api_gateway_method.get_method_terraform.http_method
  resource_id = aws_api_gateway_resource.file_path_terraform.id
  rest_api_id = aws_api_gateway_rest_api.lab_api_gateway_terraform.id
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.lab_lambda_function_terraform.invoke_arn
}

resource "aws_api_gateway_deployment" "lab_deployment_terraform" {
  rest_api_id = aws_api_gateway_rest_api.lab_api_gateway_terraform.id
  depends_on  = [
    aws_api_gateway_method.get_method_terraform,
    aws_api_gateway_method.post_method_terraform,
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.get_integration
  ]
}

resource "aws_api_gateway_stage" "lab_api_stage_terraform" {
  deployment_id = aws_api_gateway_deployment.lab_deployment_terraform.id
  rest_api_id   = aws_api_gateway_rest_api.lab_api_gateway_terraform.id
  stage_name    = var.api_stage_name
}

resource "aws_lambda_permission" "post_permission_terraform" {
  statement_id  = "AllowExecutionFromApiGatewayPost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lab_lambda_function_terraform.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lab_api_gateway_terraform.execution_arn}/*/POST/${var.api_mapping}"
}

resource "aws_lambda_permission" "get_permission_terraform" {
  statement_id  = "AllowExecutionFromApiGatewayGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lab_lambda_function_terraform.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lab_api_gateway_terraform.execution_arn}/*/GET/${var.api_mapping}"
}