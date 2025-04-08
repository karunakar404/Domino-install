terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.domino.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.domino.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.domino.token
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
