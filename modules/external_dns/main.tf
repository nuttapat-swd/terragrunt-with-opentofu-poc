locals {
  common_tags       = merge(var.tags, { ManagedBy = "opentofu" })
  oidc_provider_url = trimprefix(var.oidc_provider_url, "https://")
}

# ── IAM Policy ────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "external_dns" {
  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name        = "${var.cluster_name}-external-dns"
  description = "IAM policy for external-dns"
  policy      = data.aws_iam_policy_document.external_dns.json

  tags = local.common_tags
}

# ── IRSA Role ─────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "external_dns_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_trust.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

# ── Helm Release ──────────────────────────────────────────────────────────────

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  timeout          = 300

  values = [
    yamlencode({
      provider = {
        name = "aws"
      }
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
        }
      }
      domainFilters = var.domain_filters
      policy        = var.policy
      txtOwnerId    = coalesce(var.txt_owner_id, var.cluster_name)
      extraArgs     = var.aws_zone_type != "" ? { "aws-zone-type" = var.aws_zone_type } : {}
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.external_dns]
}
