variable "model" {
  type        = string
  description = "Model Name (e.g. `job` or `worker`)"
}

variable "service" {
  type        = string
  description = "Service  (e.g. `deploy-jobs` or `deploy-schedule`)"
}

variable "sns_event_bus" {
  type        = string
  description = "Service  (e.g. `deploy-jobs` or `deploy-schedule`)"
}


variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "stream_view_type" {
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
  description = "When an item in the table is modified, what information is written to the stream defaults to `NEW_AND_OLD_IMAGES`"
}

variable "hash_key" {
  type        = string
  description = "DynamoDB table Hash Key"
}

variable "hash_key_type" {
  type        = string
  default     = "S"
  description = "Hash Key type, which must be a scalar type: `S`, `N`, or `B` for (S)tring, (N)umber or (B)inary data"
}

variable "range_key" {
  type        = string
  default     = ""
  description = "DynamoDB table Range Key"
}

variable "range_key_type" {
  type        = string
  default     = "S"
  description = "Range Key type, which must be a scalar type: `S`, `N`, or `B` for (S)tring, (N)umber or (B)inary data"
}

variable "additional_model_message_attributes" {
  type        = list(string)
  default     = []
  description = "Additional Message Attributes placed on the SNS Topic Message generated from DynamoDb stream e.g. list(`feedback_type`,`reporting_tags`). These values must be at the root of the data object and the value must match the key in the object"
}

variable "dynamodb_attributes" {
  type = list(object({
    name = string
    type = string
  }))
  default     = []
  description = "Additional DynamoDB attributes in the form of a list of mapped values"
}

variable "global_secondary_index_map" {
  type = list(object({
    hash_key           = string
    name               = string
    non_key_attributes = list(string)
    projection_type    = string
    range_key          = string
  }))
  default     = []
  description = "Additional global secondary indexes in the form of a list of mapped values"
}

variable "local_secondary_index_map" {
  type = list(object({
    name               = string
    non_key_attributes = list(string)
    projection_type    = string
    range_key          = string
  }))
  default     = []
  description = "Additional local secondary indexes in the form of a list of mapped values"
}