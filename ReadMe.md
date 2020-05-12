# terraform-aws-dynamodb infrastructure model
This module is intended to enforce service standards across the Dirt Simple projects by defining in code platform architecture. This module simplifies and standardize the deployment of `DynamoDb` database and the creation of `Revision Records` from the it's event stream.

![terraform-aws-dynamodb infrastructure model](docs/terraform-aws-dynamodb-infrustructure?raw=true "terraform-aws-dynamodb infrastructure")


## Usage


**IMPORTANT:** The `master` branch is used in `source` just as an example. In your code, do not pin to `master` because there may be breaking changes between releases.
Instead pin to the release tag (e.g. `?ref=tags/x.y.z`) of one of our [latest releases](https://github.com/dirt-simple/terraform-aws-dynamodb/releases).


```hcl
module "dynamodb_table" {
  source                       = "git::https://github.com/dirt-simple/terraform-aws-dynamodbb.git?ref=master"
  service                      = "deploy-jobs"
  model                        = "position"
  stage                        = "dev"
  hash_key                     = "HashKey"
  range_key                    = "RangeKey"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `policy` or `role`) | list(string) | `<list>` | no |
| dynamodb_attributes | Additional DynamoDB attributes in the form of a list of mapped values | object | `<list>` | no |
| global_secondary_index_map | Additional global secondary indexes in the form of a list of mapped values | object | `<list>` | no |
| hash_key | DynamoDB table Hash Key | string | - | yes |
| hash_key_type | Hash Key type, which must be a scalar type: `S`, `N`, or `B` for (S)tring, (N)umber or (B)inary data | string | `S` | no |
| local_secondary_index_map | Additional local secondary indexes in the form of a list of mapped values | object | `<list>` | no |
| name | Name  (e.g. `app` or `cluster`) | string | - | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | string | `` | no |
| range_key | DynamoDB table Range Key | string | `` | no |
| range_key_type | Range Key type, which must be a scalar type: `S`, `N`, or `B` for (S)tring, (N)umber or (B)inary data | string | `S` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`, `infra`) | string | `` | no |
| stream_view_type | When an item in the table is modified, what information is written to the stream | string | `` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | map(string) | `<map>` | no |

## Outputs

These defined outputs that can be used within the same service and terraform release.

| Name | Description |
|------|-------------|
| table_name | name of the model Dynamodb Table created |
| table_arn | arn of the model Dynamodb Table created |
| table_id | id of the model Dynamodb Table created |

## Output SSM Parameters

Dirt Simple leverages `ssm` to store parameters which can then be referenced by other service and modules.

| Name | Description |
|------|-------------|
| /${var.service}/${var.stage}/${var.model}-table | ARN for the underlying Dynamodb Table |

