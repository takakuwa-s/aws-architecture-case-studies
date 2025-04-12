locals {
  dynamodb_tables = {
    posts : {
      name             = "case5_posts"
      hash_key         = "post_id"
      range_key        = null
      stream_enabled   = true
      stream_view_type = "NEW_AND_OLD_IMAGES"
      attributes = [
        {
          name = "post_id"
          type = "S"
        }
      ]
    },
    feeds : {
      name             = "case5_feeds"
      hash_key         = "user_id"
      range_key        = "timestamp"
      stream_enabled   = true
      stream_view_type = "NEW_AND_OLD_IMAGES"
      attributes = [
        {
          name = "user_id"
          type = "S"
        },
        {
          name = "timestamp"
          type = "S"
        }
      ]
    },
    users : {
      name             = "case5_users"
      hash_key         = "user_id"
      range_key        = null
      stream_enabled   = false
      stream_view_type = null
      attributes = [
        {
          name = "user_id"
          type = "S"
        }
      ],
      items = [
        {
          user_id = {
            S = "1"
          }
          name = {
            S = "Mike"
          }
          follower = {
            L = [

              {
                S = "3"
              }
            ]
          }
          followee = {
            L = [
              {
                S = "2"
              }
            ]
          }
        },
        {
          user_id = {
            S = "2"
          }
          name = {
            S = "George"
          }
          follower = {
            L = [
              {
                S = "1"
              },
              {
                S = "3"
              }
            ]
          }
        },
        {
          user_id = {
            S = "3"
          }
          name = {
            S = "John"
          }
          followee = {
            L = [
              {
                S = "1"
              },
              {
                S = "2"
              }
            ]
          }
          follower = {
            L = [
              {
                S = "1"
              }
            ]
          }
        }
      ]
    },
  }
  dynamodb_items = flatten([
    for table in local.dynamodb_tables : [
      for item in try(table.items, []) : {
        table_name = table.name
        hash_key   = table.hash_key
        range_key  = table.range_key
        item       = item
      }
    ]
  ])
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "dynamodb_tables" {
  for_each = local.dynamodb_tables

  name         = each.value.name
  billing_mode = "PAY_PER_REQUEST"
  # billing_mode   = "PROVISIONED"
  # read_capacity  = 5
  # write_capacity = 5
  hash_key  = each.value.hash_key
  range_key = lookup(each.value, "range_key", null)

  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "ttl_timestamp"
    enabled        = true
  }

  stream_enabled   = each.value.stream_enabled
  stream_view_type = each.value.stream_view_type
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item
resource "aws_dynamodb_table_item" "table_items" {
  count = length(local.dynamodb_items)

  table_name = local.dynamodb_items[count.index].table_name
  hash_key   = local.dynamodb_items[count.index].hash_key
  range_key  = local.dynamodb_items[count.index].range_key
  item       = jsonencode(local.dynamodb_items[count.index].item)

  depends_on = [
    aws_dynamodb_table.dynamodb_tables,
  ]
}