variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = [
    "eu-west-3a"
  ]
}

variable "authorized_ips" {
  default = [
    {
      display_name = "all"
      cidr_block   = "0.0.0.0/0"
    }
  ]
}

variable "replicas" {
  default = 90
}
