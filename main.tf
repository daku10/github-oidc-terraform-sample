terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
  }
  required_version = ">= 1.0.10"
}

provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

locals {
  github = {
    org  = "daku10"
    repo = "github-oidc-sample"
  }
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["a031c46782e6e6c662c2c87c76da9aa62ccabd8e"]
  client_id_list  = ["https://github.com/${local.github.org}", "sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_actions_policy_document" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github.org}/${local.github.repo}:*"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  assume_role_policy = data.aws_iam_policy_document.github_actions_policy_document.json
  name               = "github_actions_role"
}

data "aws_iam_policy_document" "sample_policy_document" {
  statement {
    actions = [
      "ec2:Describe*",
      "ec2:Get*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sample_policy" {
  name   = "sample_policy"
  policy = data.aws_iam_policy_document.sample_policy_document.json
}

resource "aws_iam_role_policy_attachment" "my_test_role_pol_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.sample_policy.arn
}
