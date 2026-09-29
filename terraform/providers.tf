//providers are 3rd party providers which are used to interact with cloud providers, SaaS providers, and other APIs.
//you can think of it as a plugin or extension



terraform {
    required_version = "~> 1.16.0" //~> mean equal to or greater than (NOte can go upto 1.99 not 2.something)
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }

        random = {
            source = "hashicorp/random"
            version = "~> 3.7"
        }
    }
}

provider "aws" {
    region = var.aws_region
}