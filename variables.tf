#
# prepared variable stacks for our "secrets" based on *.tfvars
#
variable "aws_access_key" {
  description = "AWS ACCESS_KEY"
}

variable "aws_secret_key" {
  description = "AWS SECRET_KEY"
}

variable "aws_region" {
  description = "AWS region to launch infrastructure"
  default     = "eu-west-1"
}

variable "aws_account_id" {
  type        = "string"
  description = "AWS Account ID. Used as CodeBuild ENV variable $AWS_ACCOUNT_ID when building Docker images. For more info: http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html"
}

#
# system variables
#

variable "sys_namespace" {
  type        = "string"
  default     = "acio"
  description = "Namespace, which could be your organization name, e.g. 'acio' or 'allcloud'"
}

variable "sys_name" {
  type        = "string"
  description = "Solution name, e.g. 'app' or 'jenkins'"
  default     = "app"
}

variable "sys_build" {
  type        = "string"
  description = "build definition, e.g. 'alpha', 'preview' or 'stable'"
  default     = "preview"
}

variable "sys_github_jenkins_oauth_token" {
  type        = "string"
  description = "our github auth token to access private allcloud-jenkins dockerfile sources"
}

variable "sys_github_jenkins_organization" {
  type        = "string"
  default     = "paterik"
  description = "GitHub organization, e.g. 'allcloud'. By default, this module will deploy 'https://github.com/paterik/terraform-jenkins-docker' repository"
}

variable "sys_github_jenkins_repo_name" {
  type        = "string"
  default     = "terraform-jenkins-docker"
  description = "GitHub repository name, e.g. 'terraform-jenkins-docker'. By default, this module will deploy 'https://github.com/paterik/terraform-jenkins-docker' repository"
}

variable "sys_github_jenkins_branch" {
  type        = "string"
  default     = "master"
  description = "GitHub repository branch, e.g. 'master'. By default, this module will deploy 'https://github.com/paterik/terraform-jenkins-docker' master branch"
}

#
# application stack variables
#

variable "stage" {
  type        = "string"
  description = "Stage, e.g. 'prod', 'staging', 'dev', 'test' or 'preview'"
}

variable "vpc_cidr" {

  description = "CIDR for VPC, subNet-CIDRs will be calculated based on that"

  default = {
    prod    = "10.220.0.0/16"
    preview = "10.210.0.0/16"
    dev     = "10.200.0.0/16"
  }
}

variable "description" {
  type        = "string"
  default     = "Jenkins server as Docker container running on Elastic Benastalk"
  description = "Will be used as Elastic Beanstalk application description"
}

# http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html#concepts.platforms.docker
variable "solution_stack_name" {
  type        = "string"
  default     = "64bit Amazon Linux 2018.03 v2.12.14 running Docker 18.06.1-ce"
  description = "Elastic Beanstalk stack, e.g. Docker, Go, Node, Java, IIS. For more info: http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html"
}

variable "master_instance_type" {

  description = "EC2 instance type for Jenkins master, e.g. 't2.medium'"

  default = {
    prod    = "t2.xlarge"
    preview = "t2.large"
    dev     = "t2.medium"
  }
}

variable "vpc_id" {
  type        = "string"
  description = "ID of the VPC in which to provision the AWS resources"
}

variable "availability_zones" {
  type        = "list"
  description = "List of Availability Zones for EFS"
}

variable "healthcheck_url" {
  type        = "string"
  default     = "/login"
  description = "Application Health Check URL. Elastic Beanstalk will call this URL to check the health of the application running on EC2 instances"
}

variable "loadbalancer_type" {
  type        = "string"
  default     = "application"
  description = "Load Balancer type, e.g. 'application' or 'classic'"
}

variable "loadbalancer_certificate_arn" {
  type        = "string"
  description = "Load Balancer SSL certificate ARN. The certificate must be present in AWS Certificate Manager"
}

variable "public_subnets" {
  type        = "list"
  description = "List of public subnets to place Elastic Load Balancer"
}

variable "private_subnets" {
  type        = "list"
  description = "List of private subnets to place EC2 instances and EFS"
}

variable "zone_id" {
  type        = "string"
  description = "Route53 parent zone ID. The module will create sub-domain DNS records in the parent zone for the EB environment and EFS"
}

variable "security_groups" {
  type        = "list"
  default     = []
  description = "List of security groups to be allowed to connect to the EC2 instances"
}

variable "ssh_key_pair" {
  type        = "string"
  default     = ""
  description = "Name of SSH key that will be deployed on Elastic Beanstalk and DataPipeline instance. The key should be present in AWS"
}

# http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html#build-env-ref-available
variable "build_image" {
  type        = "string"
  default     = "aws/codebuild/standard:2.0"
  description = "CodeBuild build image, e.g. 'aws/codebuild/docker:1.12.1'. For more info: http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html#build-env-ref-available"
}

# http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html#build-env-ref-compute-types
variable "build_compute_type" {
  type        = "string"
  default     = "BUILD_GENERAL1_SMALL"
  description = "CodeBuild compute type, e.g. 'BUILD_GENERAL1_SMALL'. For more info: http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html#build-env-ref-compute-types"
}

variable "image_tag" {
  type        = "string"
  description = "Docker image tag in the ECR repository, e.g. 'latest'. Used as CodeBuild ENV variable $IMAGE_TAG when building Docker images. For more info: http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html"
  default     = "latest"
}

variable "env_default_key" {
  type        = "string"
  default     = "DEFAULT_ENV_%d"
  description = "Default ENV variable key for Elastic Beanstalk `aws:elasticbeanstalk:application:environment` setting"
}

variable "env_default_value" {
  type        = "string"
  default     = "UNSET"
  description = "Default ENV variable value for Elastic Beanstalk `aws:elasticbeanstalk:application:environment` setting"
}

variable "env_vars" {
  type        = "map"
  default     = {}
  description = "Map of custom ENV variables to be provided to the Jenkins application running on Elastic Beanstalk, e.g. env_vars = { JENKINS_USER = 'admin' JENKINS_PASS = 'xxxxxx' }"
}

variable "noncurrent_version_expiration_days" {
  type        = "string"
  default     = "35"
  description = "Backup S3 bucket noncurrent version expiration days"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "datapipeline_config" {
  type        = "map"
  description = "DataPipeline configuration options"

  default = {
    instance_type = "t2.small"
    email         = "parick.paechnatz@allcloud.io"
    period        = "24 hours"
    timeout       = "60 Minutes"
  }
}

variable "use_efs_ip_address" {
  default = "false"
}
