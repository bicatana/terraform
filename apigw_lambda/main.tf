# Now, we need an API to expose those functions publicly
resource "aws_api_gateway_rest_api" "rest_api" {
  name = var.rest_api_name
}

# The API requires at least one "endpoint", or "resource" in AWS terminology.
# The endpoint created here is: /rest
resource "aws_api_gateway_resource" "rest_api_res" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "rest"
}

# Example: request for GET /rest
resource "aws_api_gateway_method" "request_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.rest_api_res.id
  http_method   = var.method
  authorization = "NONE"
}

# Example: GET /rest => POST lambda
resource "aws_api_gateway_integration" "request_method_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  //resource_id = var.resource_id
  resource_id = aws_api_gateway_resource.rest_api_res.id
  http_method = aws_api_gateway_method.request_method.http_method
  type        = "AWS"
  uri         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.lambda_name}/invocations"

  # AWS lambdas can only be invoked with the POST method
  integration_http_method = "POST"
}

# lambda => GET response
resource "aws_api_gateway_method_response" "response_method" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_res.id
  http_method = aws_api_gateway_integration.request_method_integration.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Response for: GET /hello
resource "aws_api_gateway_integration_response" "response_method_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_res.id
  http_method = aws_api_gateway_method_response.response_method.http_method
  status_code = aws_api_gateway_method_response.response_method.status_code

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = var.lambda_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.rest_api.id}/*/${aws_api_gateway_method_response.response_method.http_method}${var.path}"
}

resource "aws_api_gateway_domain_name" "api2bicatananet" {
  domain_name              = "api2.bicatana.net"
  regional_certificate_arn = "arn:aws:acm:eu-west-2:000681679761:certificate/6e87a906-5529-4fa7-b055-782c2fd1840f"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "api" {
  zone_id = var.primary_zone_id
  name    = "api2.bicatana.net"
  type    = "A"
  
  alias {
    name                   = aws_api_gateway_domain_name.api2bicatananet.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api2bicatananet.regional_zone_id
    evaluate_target_health = false
  }
}

