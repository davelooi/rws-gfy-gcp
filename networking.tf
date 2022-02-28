locals {
  subnets = {
    public = {
      name = "${data.google_project.this.name}-public"
    }
    private = {
      name = "${data.google_project.this.name}-private"
      secondary_ranges = {
        gke_services = "${data.google_project.this.name}-gke-services"
        gke_pods     = "${data.google_project.this.name}-gke-pods"
      }
    }
  }
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "4.0.0"

  project_id   = data.google_project.this.project_id
  network_name = "${data.google_project.this.name}-vpc"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name      = local.subnets.public.name
      subnet_ip        = "10.128.0.0/20"
      subnet_flow_logs = "false"
      subnet_region    = data.google_client_config.this.region
    },
    {
      subnet_name           = local.subnets.private.name
      subnet_ip             = "10.132.0.0/20"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      subnet_region         = data.google_client_config.this.region
    }
  ]
  secondary_ranges = {
    (local.subnets.public.name) = []
    (local.subnets.private.name) = [
      {
        range_name    = local.subnets.private.secondary_ranges.gke_services
        ip_cidr_range = "10.0.0.0/20"
      },
      {
        range_name    = local.subnets.private.secondary_ranges.gke_pods
        ip_cidr_range = "10.16.0.0/14"
      }
    ]
  }
  routes = []
}

resource "google_compute_router" "this" {
  name    = "${data.google_project.this.name}-nat"
  region  = data.google_client_config.this.region
  network = module.vpc.network_self_link
  bgp {
    asn = 64514
  }
}

resource "google_compute_address" "this" {
  count = 3
  name   = "${data.google_project.this.name}-nat-external-address"
  region = data.google_client_config.this.region
}

resource "google_compute_router_nat" "this" {
  name                               = "${data.google_project.this.name}-nat"
  router                             = google_compute_router.this.name
  region                             = data.google_client_config.this.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.this.*.self_link
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = module.vpc.subnets["${data.google_client_config.this.region}/${local.subnets.private.name}"].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
