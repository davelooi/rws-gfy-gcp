data "google_project" "this" {}

data "google_client_config" "this" {}

data "google_organization" "this" {
  organization = data.google_project.this.org_id
}

resource "google_project_service" "this" {
  for_each = toset([
    "iam",
    "compute",
    "containerregistry",
    "logging",
    "container",
    "secretmanager"
  ])
  project = data.google_project.this.id
  service = "${each.value}.googleapis.com"

}
