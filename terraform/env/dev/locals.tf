locals {
    prefix = "${var.region_code[var.region]}-${var.project_name}"

    required_tags = {
        terraform = true
        project = var.project_name
    }
}