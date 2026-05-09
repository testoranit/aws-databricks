# environments/dev/terraform.tfvars
# These are NON-SECRET values only
# Secrets go in GitHub Secrets as TF_VAR_*

env         = "dev"
region      = "ap-south-1"
aws_account = "021655150740"

# Your existing Databricks-created resources
workspace_url    = "https://dbc-7177239c-a413.cloud.databricks.com/?autoLogin=true&account_id=c224882b-52d7-46b3-8411-9d6b0db39b5e&o=7474645936607434"
dbfs_bucket_name = "databricks-rijaji8cryazpfxzgm67tw-cloud-storage-bucket"
vpc_id           = "vpc-069585e1be7809912"
security_group   = "sg-0ebff30c7f36ed17b"

# Cluster config
cluster_node_type       = "i3.xlarge"
autotermination_minutes = 20
min_workers             = 1
max_workers             = 2
alert_email             = "kapsblab99@gmail.com"
