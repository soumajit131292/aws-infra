###############################
## API Gateway (approval URL) ##
###############################
# HTTP API (v2) backing the approval webhook. The SNS approval message
# includes URLs of the shape:
#
#   https://<api>/approve?token=<task-token>&action=approve&sig=<secret>
#
# Click -> API Gateway routes to the approval_handler Lambda which calls
# stepfunctions:SendTaskSuccess|Failure to resume / abort the state machine.

resource "aws_apigatewayv2_api" "approval" {
  name          = "${var.name_prefix}-approval"
  protocol_type = "HTTP"
  description   = "Click-to-approve webhook for DR failover state machine."
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "approval" {
  api_id                 = aws_apigatewayv2_api.approval.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambdas["approval_handler"].invoke_arn
  payload_format_version = "2.0"
  integration_method     = "POST"
}

resource "aws_apigatewayv2_route" "approve" {
  api_id    = aws_apigatewayv2_api.approval.id
  route_key = "GET /approve"
  target    = "integrations/${aws_apigatewayv2_integration.approval.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.approval.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 10
  }

  tags = var.tags
}

resource "aws_lambda_permission" "approval_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdas["approval_handler"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.approval.execution_arn}/*/*"
}
