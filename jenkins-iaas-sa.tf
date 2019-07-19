#
# @module/info: stand-alone jenkins instance for "infrastructure as a service" terraform ci/cd
#
# @author: Patrick Paechnatz <patrick.paechnatz@allcloud.io>
# @version: 0.1.1 <alpha>
# @createdAt: 2019/07/19
# @updatedAt: 2019/07/19
#

#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#

data     "aws_availability_zones" "available" {}

variable "infra_version"             { default = "1-0-0"     }
variable "aws_region_override"       { default = "false"     }
variable "aws_region_override_value" { default = "eu-west-2" }
variable "max_availability_zones"    { default = "2"         }

#
# -- } --
#

#
# dedicated jenkins-role related resource management
#
# -- { --
#

module "label_workspace" {

  source              = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.14.1"

  name                = "jenkins-sa"
  namespace           = "acio"

  tags                = {
    environment       = terraform.workspace
    businessUnit      = "CSA"
    department        = "DEVOPS/internal"
    type              = "cicd-jenkins"
    role              = "cicd-iaas"
    access            = "internal"
    version           = var.infra_version
  }
}

module "vpc" {

  source              = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.7.0"

  stage               = terraform.workspace
  name                = "${module.label_workspace.name}-vpc"
  namespace           = "${module.label_workspace.namespace}-${var.infra_version}"

  # @info: fetch CIDR based on current workspace
  cidr_block          = var.vpc_cidr[terraform.workspace]

  # @info: extend default tags by `resource=vpc`
  tags                = merge(map("resource", "vpc"), module.label_workspace.tags)
}

module "subnets" {

  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=tags/0.16.0"

  availability_zones  = [ slice(data.aws_availability_zones.available.names, 0, var.max_availability_zones) ]

  stage               = terraform.workspace
  name                = "${module.label_workspace.name}-subnet"
  namespace           = "${module.label_workspace.namespace}-${var.infra_version}"

  nat_gateway_enabled = "true"

  region              = var.aws_region_override ? var.aws_region_override_value : var.aws_region
  vpc_id              = module.vpc.vpc_id
  igw_id              = module.vpc.igw_id
  cidr_block          = module.vpc.vpc_cidr_block

  # @info: extend default tags by `resource=subnet`
  tags                = merge(map("resource", "subnet"), module.label_workspace.tags)
}

#
# -- } --
#
