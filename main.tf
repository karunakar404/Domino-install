data "aws_eks_cluster" "domino" {
  name = "domino"
}

data "aws_eks_cluster_auth" "domino" {
  name = "domino"
}

resource "aws_eks_node_group" "data_science_nodes" {
  cluster_name    = "domino"
  node_group_name = "data-science"
  node_role_arn   = "arn:aws:iam::576245601309:role/eks-node-role"

  subnet_ids = [
    "subnet-0a31e940b55eaf1c0",
    "subnet-00d9f6942d2e9d036"
  ]

  instance_types = ["m6i.2xlarge"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  tags = {
    Name = "data-science-node-group"
  }
}

resource "helm_release" "domino" {
  name       = "domino"
  repository = "https://dominodatalab.github.io/charts/"
  chart      = "domino"
  version    = "0.1.11"

  namespace         = "domino"
  create_namespace  = true

  values = [
    file("${path.module}/domino-values.yaml")
  ]
}
