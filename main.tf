data "aws_availability_zones"  "available" {}
data "aws_iam_policy_document" "slaves" {

  statement {

    sid = "AllowLaunchingEC2Instances"

    actions = [
      "ec2:DescribeSpotInstanceRequests",
      "ec2:CancelSpotInstanceRequests",
      "ec2:GetConsoleOutput",
      "ec2:RequestSpotInstances",
      "ec2:RunInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeInstances",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeRegions",
      "ec2:DescribeImages",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "iam:PassRole",
    ]

    resources = ["*"]
    effect    = "Allow"
  }
}

#
# provider based configuration
#
# -- { --
#

provider "aws" {

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

#
# -- } --
#

# Elastic Beanstalk Application
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#

module "elastic_beanstalk_application" {

  source      = "git::https://github.com/cloudposse/terraform-aws-elastic-beanstalk-application.git?ref=tags/0.1.6"

  stage       = terraform.workspace
  name        = "${terraform.workspace}-jenkins-sa"
  namespace   = "acio"

  description = var.description
  delimiter   = var.delimiter
  attributes  = [compact(concat(var.attributes, list("eb-app")))]
  tags        = var.tags
}

#
# -- } --
#

# Elastic Beanstalk Environment##
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
module "elastic_beanstalk_environment" {

  source                       = "git::https://github.com/cloudposse/terraform-aws-elastic-beanstalk-environment.git?ref=tags/0.13.0"

  stage                        = terraform.workspace
  name                         = "${terraform.workspace}-jenkins-sa"
  namespace                    = "acio"

  zone_id                      = var.zone_id
  app                          = module.elastic_beanstalk_application.app_name
  instance_type                = var.master_instance_type
  keypair                      = var.ssh_key_pair

  autoscale_min                = 1
  autoscale_max                = 1
  updating_min_in_service      = 0
  updating_max_batch           = 1

  healthcheck_url              = var.healthcheck_url
  loadbalancer_type            = var.loadbalancer_type
  loadbalancer_certificate_arn = var.loadbalancer_certificate_arn

  vpc_id                       = var.vpc_id
  public_subnets               = var.public_subnets
  private_subnets              = var.private_subnets
  security_groups              = var.security_groups

  solution_stack_name          = var.solution_stack_name
  env_default_key              = var.env_default_key
  env_default_value            = var.env_default_value

  # Provide EFS DNS name to EB in the `EFS_HOST` ENV var. EC2 instance will mount to the EFS filesystem and use it to store Jenkins state
  # Add slaves Security Group `JENKINS_SLAVE_SECURITY_GROUPS` (comma-separated if more than one). Will be used by Jenkins to init the EC2 plugin to launch slaves inside the Security Group
  env_vars                     = merge(
    map(
      "EFS_HOST", var.use_efs_ip_address ? module.efs.mount_target_ips[0] : module.efs.dns_name,
      "USE_EFS_IP", var.use_efs_ip_address,
      "JENKINS_SLAVE_SECURITY_GROUPS", aws_security_group.slaves.id
    ), var.env_vars
  )

  delimiter                    = var.delimiter
  attributes                   = [compact(concat(var.attributes, list("eb-env")))]
  tags                         = var.tags
}

#
# -- } --
#

# Elastic Container Registry Docker Repository
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
module "ecr" {

  source     = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=tags/0.7.0"

  stage      = terraform.workspace
  name       = "${terraform.workspace}-jenkins-sa"
  namespace  = "acio"

  delimiter  = var.delimiter
  attributes = [compact(concat(var.attributes, list("ecr")))]
  tags       = var.tags
}

#
# -- } --
#

# EFS to store Jenkins state (settings, jobs, etc.)
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
module "efs" {

  source             = "git::https://github.com/cloudposse/terraform-aws-efs.git?ref=tags/0.10.0"

  stage              = terraform.workspace
  name               = "${terraform.workspace}-jenkins-sa"
  namespace          = "acio"

  vpc_id             = var.vpc_id
  subnets            = var.private_subnets
  availability_zones = var.availability_zones
  zone_id            = var.zone_id

  # EC2 instances (from `elastic_beanstalk_environment`) and DataPipeline instances (from `efs_backup`) are allowed to connect to the EFS
  security_groups    = [module.elastic_beanstalk_environment.security_group_id, module.efs_backup.security_group_id]

  delimiter          = var.delimiter
  attributes         = [compact(concat(var.attributes, list("efs")))]
  tags               = var.tags
  region             = var.aws_region
}

#
# -- } --
#

# EFS backup to S3
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
module "efs_backup" {

  source                             = "git::https://github.com/cloudposse/terraform-aws-efs-backup.git?ref=tags/0.9.0"

  stage                              = terraform.workspace
  name                               = "${terraform.workspace}-jenkins-sa"
  namespace                          = "acio"

  region                             = var.aws_region
  vpc_id                             = var.vpc_id
  efs_mount_target_id                = module.efs.mount_target_ids[0]
  use_ip_address                     = var.use_efs_ip_address
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  ssh_key_pair                       = var.ssh_key_pair
  modify_security_group              = false
  datapipeline_config                = var.datapipeline_config
  delimiter                          = var.delimiter
  attributes                         = [compact(concat(var.attributes, list("efs-backup")))]
  tags                               = var.tags
}

#
# -- } --
#

# CodePipeline/CodeBuild to build Jenkins Docker image, store it to a ECR repo, and deploy it to Elastic Beanstalk running Docker stack
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
module "cicd" {

  source              = "git::https://github.com/cloudposse/terraform-aws-cicd.git?ref=tags/0.7.0"

  stage               = terraform.workspace
  name                = "${terraform.workspace}-jenkins-sa"
  namespace           = "acio"

  enabled             = true
  privileged_mode     = true
  poll_source_changes = true

  app                 = module.elastic_beanstalk_application.app_name
  env                 = module.elastic_beanstalk_environment.name
  github_oauth_token  = var.sys_github_jenkins_oauth_token
  repo_owner          = var.sys_github_jenkins_organization
  repo_name           = var.sys_github_jenkins_repo_name
  branch              = var.sys_github_jenkins_branch
  build_image         = var.build_image
  build_compute_type  = var.build_compute_type

  aws_region          = var.aws_region
  aws_account_id      = var.aws_account_id
  image_repo_name     = module.ecr.repository_name
  image_tag           = var.image_tag

  delimiter           = var.delimiter
  attributes          = [compact(concat(var.attributes, list("cicd")))]
  tags                = var.tags
}

#
# -- } --
#

# Security Group for EC2 slaves
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
resource "aws_security_group" "slaves" {

  name              = "${terraform.workspace}-jenkins-sa"
  description       = "Security Group for Jenkins EC2 slaves"
  vpc_id            = var.vpc_id

  # allow the provided Security Groups to connect to Jenkins slave instances
  ingress {

    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = [var.security_groups]
  }

  # allow Jenkins master instance to communicate with Jenkins slave instances on SSH port 22
  ingress {

    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.elastic_beanstalk_environment.security_group_id]
  }

  egress {

    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags              = var.tags
}

#
# -- } --
#

# Policy for the EB EC2 instance profile to allow launching Jenkins slaves
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
resource "aws_iam_policy" "slaves" {

  path        = "/"
  name        = "${terraform.workspace}-jenkins-sa"
  description = "Policy for EC2 instance profile to allow launching Jenkins slaves"
  policy      = data.aws_iam_policy_document.slaves.json
}

#
# -- } --
#

# Attach Policy to the EC2 instance profile to allow Jenkins master to launch and control slave EC2 instances
#
# dedicated jenkins-role init/var/constant block
#
# -- { --
#
resource "aws_iam_role_policy_attachment" "slaves" {

  role       = module.elastic_beanstalk_environment.ec2_instance_profile_role_name
  policy_arn = aws_iam_policy.slaves.arn
}

#
# -- } --
#
