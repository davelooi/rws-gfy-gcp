resource "google_compute_firewall" "allow_icmp" {
  name    = "all-allow-icmp"
  network = module.vpc.network_name

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = module.vpc.network_name
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.0.0.0/8", "172.16.0.0/12"]
}

resource "google_compute_firewall" "allow_load_balancers" {
  name    = "allow-load-balancers"
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags = ["web"]
}
