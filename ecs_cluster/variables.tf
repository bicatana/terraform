variable "access_key" {}
variable "secret_key" {}
variable "region" {
    default= "eu-west-2"
}

variable "ecs-cluster-name" {}

variable "capacity" {
  default = "2"
  }