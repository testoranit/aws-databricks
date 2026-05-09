# modules/jobs/main.tf
resource "databricks_job" "etl_pipeline" {
  name = "${var.env}-daily-etl"

  schedule {
    quartz_cron_expression = "0 0 2 * * ?"  # 2 AM daily IST
    timezone_id            = "Asia/Kolkata"
    pause_status           = "UNPAUSED"
  }

  # Task 1: Ingest raw data
  task {
    task_key = "ingest"
    notebook_task {
      notebook_path = "/Shared/etl/01_ingest"
      base_parameters = {
        env    = var.env
        bucket = var.dbfs_bucket_name
      }
    }
    new_cluster {
      spark_version           = data.databricks_spark_version.lts.id
      node_type_id            = "i3.xlarge"
      num_workers             = 2
      autotermination_minutes = 10
      aws_attributes {
        instance_profile_arn = var.instance_profile_arn
        availability         = "SPOT_WITH_FALLBACK"
      }
    }
  }

  # Task 2: Transform — runs AFTER ingest succeeds
  task {
    task_key = "transform"
    depends_on { task_key = "ingest" }
    notebook_task {
      notebook_path = "/Shared/etl/02_transform"
    }
    new_cluster {
      spark_version = data.databricks_spark_version.lts.id
      node_type_id  = "i3.xlarge"
      num_workers   = 2
      aws_attributes {
        instance_profile_arn = var.instance_profile_arn
        availability         = "SPOT_WITH_FALLBACK"
      }
    }
  }

  email_notifications {
    on_failure = [var.alert_email]
    no_alert_for_skipped_runs = true
  }
}

