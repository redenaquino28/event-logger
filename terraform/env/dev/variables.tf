variable "project_name" {
    description = "Name of the project to be provisioned"
    type = string
}

variable "region" {
    description = "AWS region where project will be provisioned"
    type = string
    default = "ap-southeast-1"
}

variable "region_code" {
    description = "Region short code of AWS region"
    type = map(string)
    default = {
      "ap-southeast-1" = "sin"
    }
}