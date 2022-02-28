resource "google_service_account" "kubernetes" {
  account_id   = "gke-sa"
  display_name = "Kubernetes default service account"
}

resource "google_project_iam_member" "kubernetes" {
  for_each = toset([
    "roles/clouddebugger.agent",
    "roles/cloudtrace.agent",
    "roles/errorreporting.writer",
    "roles/logging.viewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.admin",
    "roles/storage.objectAdmin",
  ])
  project = data.google_project.this.id
  role    = each.value
  member  = "serviceAccount:${google_service_account.kubernetes.email}"
}

resource "google_container_cluster" "this" {
  provider                  = google-beta
  name                      = "${data.google_project.this.name}-primary"
  remove_default_node_pool  = true
  initial_node_count        = 1
  network                   = module.vpc.network_name
  subnetwork                = module.vpc.subnets["${data.google_client_config.this.region}/${local.subnets.private.name}"].self_link
  location                  = data.google_client_config.this.zone
  default_max_pods_per_node = 110
  min_master_version        = "1.21"

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = concat([
        {
          cidr_block   = module.vpc.subnets["${data.google_client_config.this.region}/${local.subnets.public.name}"].ip_cidr_range
          display_name = "public-subnet"
        }
      ], var.authorized_ips)
      content {
        cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
        display_name = lookup(cidr_blocks.value, "display_name", "")
      }
    }
  }

  pod_security_policy_config {
    enabled = false
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = local.subnets.private.secondary_ranges.gke_pods
    services_secondary_range_name = local.subnets.private.secondary_ranges.gke_services
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.16/28"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    dns_cache_config {
      enabled = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "google_container_node_pool" "main" {
  name               = "${data.google_project.this.name}-main-node-pool"
  cluster            = google_container_cluster.this.name
  location           = data.google_client_config.this.zone
  initial_node_count = 1

  autoscaling {
    max_node_count = 4
    min_node_count = 1
  }

  management {
    auto_repair  = true
    auto_upgrade = false
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 1
  }

  node_config {
    preemptible     = true
    machine_type    = "custom-2-2048"
    disk_size_gb    = 20
    disk_type       = "pd-standard"
    local_ssd_count = 0
    image_type      = "COS"
    service_account = google_service_account.kubernetes.email

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = [
      "web",
    ]

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_write",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
