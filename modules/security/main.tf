# modules/security/main.tf

resource "databricks_group" "engineers" {
  display_name = "data-engineers"
}

resource "databricks_group" "analysts" {
  display_name = "analysts"
}

# Cluster permissions by group
resource "databricks_permissions" "cluster" {
  cluster_id = var.cluster_id

  access_control {
    group_name       = databricks_group.engineers.display_name
    permission_level = "CAN_RESTART"   # use + restart
  }
  access_control {
    group_name       = databricks_group.analysts.display_name
    permission_level = "CAN_ATTACH_TO" # use only
  }
}

# Job permissions
resource "databricks_permissions" "job" {
  job_id = var.job_id
  access_control {
    group_name       = databricks_group.engineers.display_name
    permission_level = "CAN_MANAGE_RUN"
  }
}

# Create encrypted secret scope
resource "databricks_secret_scope" "app" {
  name = "app-secrets"
}

# Store a secret (e.g. database password)
resource "databricks_secret" "db_password" {
  key          = "rds-password"
  string_value = var.rds_password  # from TF_VAR_rds_password
  scope        = databricks_secret_scope.app.id
}
# In your notebook, access like this:
# password = dbutils.secrets.get(
#   scope="app-secrets", key="rds-password"
# )
# Value NEVER printed in output or logs ✅
