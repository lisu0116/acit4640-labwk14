variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "ssh_key_name" {
  type    = string
  default = "4640-wk14"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
