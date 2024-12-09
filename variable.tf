variable "vpc_id" {
  type    = string
  default = "vpc-01234567890123456"
}

variable "subnet_id" {
  type    = string
  default = "subnet-01234567890123456"
}

variable "security_group_id" {
  type    = string
  default = "sg-01234567890123456"
}

variable "lb_name" {
  type    = string
  default = "load-balancer-name"
}

variable "iam_role_name" {
  type    = string
  default = "iam-role-name"
}
