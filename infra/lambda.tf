data "archive_file" "code2cloud-lambda-function" {
  type        = "zip"
  source_file = "./assets/lambda.py"
  output_path = "./assets/lambda.zip"
}
resource "aws_iam_role" "code2cloud-lambda-role" {
  name               = "code2cloud-lambda-role-${var.code2cloudid}-service-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name      = "code2cloud-lambda-role-${var.code2cloudid}"
    Stack     = "${var.stack-name}"
    Scenario  = "${var.scenario-name}"
    yor_trace = "fd2a79fc-3b8a-42c5-a4b8-62e4b8d429c5"
  }
}
resource "aws_lambda_function" "code2cloud-lambda-function" {
  filename         = "./assets/lambda.zip"
  function_name    = "code2cloud-lambda-${var.code2cloudid}"
  role             = "${aws_iam_role.code2cloud-lambda-role.arn}"
  handler          = "lambda.handler"
  source_code_hash = "${data.archive_file.code2cloud-lambda-function.output_base64sha256}"
  runtime          = "python3.9"
  # fixed secret 
  environment {
    variables = {
      EC2_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
      EC2_SECRET_KEY_ID = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    }
  }
  #     environment {
  #     variables = {
  #       access_key = "AKIAIOSFODNN7EXAMPLE"
  #       secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  #     }
  #   }
  tags = {
    Name      = "code2cloud-lambda-${var.code2cloudid}"
    Stack     = "${var.stack-name}"
    Scenario  = "${var.scenario-name}"
    yor_trace = "03ce6c38-9cc5-4916-b41c-6ca32178c201"
  }
}