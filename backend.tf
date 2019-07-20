#
# terraform backend configuration
#
terraform {

    backend "s3" {
        bucket = "terra-state-bucket-jenkins-core-v2"
        key = "tfstate"
        region = "eu-west-1"
    }
}
