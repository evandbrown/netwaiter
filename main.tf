variable "project" {
  type = "string"
}

variable "region" {
  type = "string"
  default = "us-central1"
}

variable "bin_url" {
  type = "string"
  default = "https://storage.googleapis.com/evandbrown17/netwaiter"
}

provider "google" {
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_instance" "default" {
  name               = "lb-timeout-repro"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  tags = ["web-8080"]

  disk {
    image = "debian-cloud/debian-8"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<EOF
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh
wget ${var.bin_url} && chmod +x netwaiter && ./netwaiter &
EOF

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "default" {
  name               = "lb-timeout-repro"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]
  }

  target_tags    = ["web-8080"]
  source_ranges  = ["0.0.0.0/0"]
}

resource "google_compute_instance_group" "webservers" {
  name               = "lb-timeout-repro"
  description = "Terraform test instance group"

  instances = [
    "${google_compute_instance.default.self_link}",
  ]

  named_port {
    name = "http"
    port = "8080"
  }

  zone = "us-central1-a"
}

resource "google_compute_global_forwarding_rule" "default" {
  name               = "lb-timeout-repro"
  target     = "${google_compute_target_http_proxy.default.self_link}"
  port_range = "8080"
}

resource "google_compute_target_http_proxy" "default" {
  name               = "lb-timeout-repro"
  description = "a description"
  url_map     = "${google_compute_url_map.default.self_link}"
}

resource "google_compute_url_map" "default" {
  name               = "lb-timeout-repro"
  description     = "a description"
  default_service = "${google_compute_backend_service.default.self_link}"
}

resource "google_compute_backend_service" "default" {
  name               = "lb-timeout-repro"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 2

  health_checks = ["${google_compute_http_health_check.default.self_link}"]

  backend {
    group = "${google_compute_instance_group.webservers.self_link}"
  }
}

resource "google_compute_http_health_check" "default" {
  name               = "lb-timeout-repro"
  request_path       = "/healthz"
  port               = 8080
  check_interval_sec = 60
  timeout_sec        = 10
}

output "ip" {
  value = "${google_compute_global_forwarding_rule.default.ip_address}"
}

output "health" {
  value = "http://${google_compute_global_forwarding_rule.default.ip_address}:8080/healthz"
}

output "try_it" {
  value = "curl \"http://${google_compute_global_forwarding_rule.default.ip_address}:8080/sleep?duration=3s&request_id=$RANDOM\""
}
