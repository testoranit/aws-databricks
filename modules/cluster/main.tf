# Create IAM role for cluster EC2 nodes
resource "aws_iam_role" "cluster" {
  name = "${var.env}-databricks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cluster_s3" {
  name = "cluster-s3-access"
  role = aws_iam_role.cluster.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject", "s3:PutObject",
        "s3:DeleteObject", "s3:ListBucket"
      ]
      Resource = [
        data.aws_s3_bucket.dbfs.arn,
        "${data.aws_s3_bucket.dbfs.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "cluster" {
  name = "${var.env}-databricks-cluster-profile"
  role = aws_iam_role.cluster.name
}

# Register instance profile with Databricks workspace
resource "databricks_instance_profile" "cluster" {
  instance_profile_arn = aws_iam_instance_profile.cluster.arn
  is_meta_instance_profile = false
}

# modules/cluster/main.tf

# Auto-discover latest Long Term Support Spark version
# Never hardcode Spark version — it gets outdated
data "databricks_spark_version" "lts" {
  long_term_support = true
}

# Shared cluster — engineers attach notebooks here
resource "databricks_cluster" "shared" {
  cluster_name            = "${var.env}-shared-interactive"
  spark_version           = data.databricks_spark_version.lts.id
  node_type_id            = var.cluster_node_type
  autotermination_minutes = var.autotermination_minutes
  data_security_mode      = "SINGLE_USER"

  # Autoscale — starts with 1 worker, grows under load
  autoscale {
    min_workers = var.min_workers
    max_workers = var.max_workers
  }

aws_attributes {
    instance_profile_arn   = var.instance_profile_arn
    availability           = "SPOT_WITH_FALLBACK"
    # SPOT = up to 70% cheaper than on-demand
    # FALLBACK = uses on-demand if no spot available
    first_on_demand        = 1
    spot_bid_price_percent = 100
    zone_id                = "auto"
  }

  spark_conf = {
    "spark.databricks.io.cache.enabled"      = "true"
    "spark.databricks.delta.preview.enabled" = "true"
  }

 # Pre-install common libraries on cluster start
  library { pypi { package = "pandas==2.1.0" } }
  library { pypi { package = "boto3" } }

  custom_tags = {
    Environment = var.env
    Team        = "data-engineering"
  }
}

resource "databricks_cluster_policy" "dev_policy" {
  name = "${var.env}-cost-control-policy"

  definition = jsonencode({
    "autotermination_minutes" : {
      "type"  : "fixed",
      "value" : 20,         // forced — user cannot change
      "hidden": false
    },
    "autoscale.max_workers" : {
      "type"     : "range",
      "maxValue" : 4         // max 4 workers allowed
    },
    "aws_attributes.availability" : {
      "type"  : "fixed",
      "value" : "SPOT_WITH_FALLBACK"  // always use spot
    },
    "node_type_id" : {
      "type"     : "allowlist",
      "values"  : ["i3.xlarge", "i3.2xlarge"]
    }
  })
}
