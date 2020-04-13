provider "aws" {
  profile    = "default"
  region = "${var.aws_region}"
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "greet_lambda.py"
  output_path = "greet_lambda.zip"
}


resource "aws_lambda_function" "greet_function" {
  function_name = "greet_lambda"
  role = "arn:aws:iam::813173407724:role/lambda_admins"

  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  handler = "greet_lambda.lambda_handler"
  runtime = "python3.6"

  environment {
    variables = {
      greeting = "Hello"
    }
  }
}

resource "aws_api_gateway_rest_api" "greet_function" {
  name = "greet_function"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.greet_function.id
  parent_id   = aws_api_gateway_rest_api.greet_function.root_resource_id
  path_part   = "{proxy+}"
}


resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.greet_function.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.greet_function.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.greet_function.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
	rest_api_id   = aws_api_gateway_rest_api.greet_function.id
	resource_id   = aws_api_gateway_rest_api.greet_function.root_resource_id
	http_method   = "ANY"
	authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.greet_function.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.greet_function.invoke_arn
}

resource "aws_api_gateway_deployment" "example" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.greet_function.id
   stage_name  = "test"
}


resource "aws_lambda_permission" "apigw" {
	statement_id  = "AllowAPIGatewayInvoke"
	action        = "lambda:InvokeFunction"
	function_name = aws_lambda_function.greet_function.function_name
	principal     = "apigateway.amazonaws.com"

	# The "/*/*" portion grants access from any method on any resource
	# within the API Gateway REST API.
	source_arn = "${aws_api_gateway_rest_api.greet_function.execution_arn}/*/*"
}
