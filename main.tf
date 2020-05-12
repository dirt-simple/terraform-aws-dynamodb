
locals {
  attributes = concat(
    [
      {
        name = var.range_key
        type = var.range_key_type
      },
      {
        name = var.hash_key
        type = var.hash_key_type
      }
    ],
    var.dynamodb_attributes
  )

  # Use the `slice` pattern (instead of `conditional`) to remove the first map from the list if no `range_key` is provided
  from_index = length(var.range_key) > 0 ? 0 : 1

  attributes_final = slice(local.attributes, local.from_index, length(local.attributes))
  service = replace(var.service, "/[_]/", "-")
  stage = replace(var.stage, "/[_]/", "-")
  model = replace(var.model, "/[_]/", "-")
  qualified_name = "${local.service}-${local.stage}-${local.model}"
}

resource "null_resource" "global_secondary_index_names" {
  count = length(var.global_secondary_index_map)

  # Convert the multi-item `global_secondary_index_map` into a simple `map` with just one item `name` since `triggers` does not support `lists` in `maps` (which are used in `non_key_attributes`)
  # See `examples/complete`
  # https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html#non_key_attributes-1
  triggers = {
    "name" = var.global_secondary_index_map[count.index]["name"]
  }
}

resource "null_resource" "local_secondary_index_names" {
  count = length(var.local_secondary_index_map)

  triggers = {
    "name" = var.local_secondary_index_map[count.index]["name"]
  }
}

resource "aws_dynamodb_table" "service_model_table" {
  name             = local.qualified_name
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = var.hash_key
  range_key        = var.range_key
  stream_enabled   = true
  stream_view_type = var.stream_view_type

  dynamic "attribute" {
    for_each = local.attributes_final
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_index_map
    content {
      hash_key           = global_secondary_index.value.hash_key
      name               = global_secondary_index.value.name
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
      projection_type    = global_secondary_index.value.projection_type
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      read_capacity      = lookup(global_secondary_index.value, "read_capacity", null)
      write_capacity     = lookup(global_secondary_index.value, "write_capacity", null)
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_index_map
    content {
      name               = local_secondary_index.value.name
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
      projection_type    = local_secondary_index.value.projection_type
      range_key          = local_secondary_index.value.range_key
    }
  }
}

resource "aws_lambda_event_source_mapping" "aws_lambda_event_source_mapping" {
  event_source_arn  = aws_dynamodb_table.service_model_table.stream_arn
  function_name     = aws_lambda_function.revision_record_publisher.arn
  starting_position = "TRIM_HORIZON"
}

resource "aws_lambda_function" "revision_record_publisher" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "${local.qualified_name}-revision-record-publisher"
  source_code_hash = data.archive_file.revision_record_lambda.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "nodejs8.10"
  handler          = "index.handler"
  timeout          = 120

  environment {
    variables = {
      REVISION_RECORD_TOPIC_ARN = data.aws_sns_topic.event_bus.arn
      MODEL_NAME                = var.model
      MODEL_SCHEMA_VERSION      = "1.0"
      MODEL_IDENTIFIER_FIELD    = var.hash_key
      ADDITIONAL_MODEL_IDENTIFIER_FIELD = join(":", var.additional_model_message_attributes)
    }
  }
}

data "archive_file" "revision_record_lambda" {
  type = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.qualified_name}-revision-record-publisher"
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
}

resource "aws_iam_role_policy" "activity_stream_policy" {
  role = aws_iam_role.iam_for_lambda.id
  name = "${local.qualified_name}-dynamodb-activity-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadDynamodbStream",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeStream",
        "dynamodb:GetShardIterator",
        "dynamodb:GetRecords",
        "dynamodb:ListShards"
      ],
      "Resource": [
        "${aws_dynamodb_table.service_model_table.arn}/*"
      ]
    },
    {
      "Sid": "WriteToRevisionTopic",
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "${data.aws_sns_topic.event_bus.arn}"
      ]
    },
    {
      "Sid": "WriteToCloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }    
  ]
}
EOF
}

data "aws_sns_topic" "event_bus" {
  name = var.sns_event_bus
}

