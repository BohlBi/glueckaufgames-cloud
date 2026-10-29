# -----------------------------------------------------------------------------
# Anmeldung von GitHub Actions bei AWS über OpenID Connect (OIDC)
# Keine dauerhaften Zugangsschlüssel: GitHub erhält pro Pipeline-Lauf
# kurzlebige Zugangsdaten (max. 1 Stunde).
#
# Zwei Rollen nach dem Prinzip der minimalen Rechte:
#   - plan-Rolle:  nur lesen, für jeden Pull Request
#   - apply-Rolle: darf ändern, aber nur vom Branch "main" (nach Freigabe)
# -----------------------------------------------------------------------------

locals {
  oidc_count = var.enable_github_oidc ? 1 : 0

  github_oidc_url = "token.actions.githubusercontent.com"
  name_prefix     = var.project
  project_arn_s3  = "arn:aws:s3:::${var.project}-*"

  # Seit Juli 2026 enthält das Subject bei neuen Repositorys die
  # unveränderlichen IDs von Konto und Repository. Ein umbenanntes oder neu
  # angelegtes Repository mit gleichem Namen erhält so keinen Zugriff.
  github_subject = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = local.oidc_count

  url            = "https://${local.github_oidc_url}"
  client_id_list = ["sts.amazonaws.com"]
}

# --- Vertrauensrichtlinien ----------------------------------------------------

data "aws_iam_policy_document" "trust_plan" {
  count = local.oidc_count

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Nur Pull Requests aus genau diesem Repository
    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_url}:sub"
      values   = ["${local.github_subject}:pull_request"]
    }
  }
}

data "aws_iam_policy_document" "trust_apply" {
  count = local.oidc_count

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Nur Läufe auf dem freigegebenen Branch (nach Merge)
    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_url}:sub"
      values   = ["${local.github_subject}:ref:refs/heads/${var.github_default_branch}"]
    }
  }
}

# --- Gemeinsamer Zugriff auf den Terraform-State ------------------------------

data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "ReadWriteState"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  statement {
    sid       = "StateLockFile"
    actions   = ["s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/*.tflock"]
  }
}

# --- plan-Rolle (nur lesen) ---------------------------------------------------

resource "aws_iam_role" "plan" {
  count = local.oidc_count

  name                 = "${local.name_prefix}-github-plan"
  description          = "GitHub Actions: terraform plan in Pull Requests (nur lesend)"
  assume_role_policy   = data.aws_iam_policy_document.trust_plan[0].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  count = local.oidc_count

  role       = aws_iam_role.plan[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "plan_state" {
  count = local.oidc_count

  name   = "terraform-state"
  role   = aws_iam_role.plan[0].id
  policy = data.aws_iam_policy_document.state_access.json
}

# --- apply-Rolle (ändern, nur Projekt-Ressourcen) -----------------------------

data "aws_iam_policy_document" "apply" {
  count = local.oidc_count

  statement {
    sid     = "ProjectBuckets"
    actions = ["s3:*"]
    resources = [
      local.project_arn_s3,
      "${local.project_arn_s3}/*",
    ]
  }

  # CloudFront-Ressourcen (Distribution, OAC, Header-Richtlinien) haben keine
  # frei wählbaren Namen im ARN; Einschränkung daher auf das eigene Konto.
  statement {
    sid       = "CloudFrontOwnAccount"
    actions   = ["cloudfront:*"]
    resources = ["arn:aws:cloudfront::${local.account_id}:*"]
  }

  # Nur Rollen mit Projektpräfix (z. B. die Rolle für die S3-Replikation)
  statement {
    sid = "ProjectRoles"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project}-*"]
  }

  # Die Replikationsrolle darf nur an S3 weitergegeben werden.
  statement {
    sid       = "PassReplicationRole"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["s3.amazonaws.com"]
    }
  }

  statement {
    sid       = "ProjectBudgets"
    actions   = ["budgets:*"]
    resources = ["arn:aws:budgets::${local.account_id}:budget/${var.project}-*"]
  }

  statement {
    sid       = "ProjectAlarms"
    actions   = ["cloudwatch:*"]
    resources = ["arn:aws:cloudwatch:*:${local.account_id}:alarm:${var.project}-*"]
  }

  statement {
    sid       = "ProjectTopics"
    actions   = ["sns:*"]
    resources = ["arn:aws:sns:*:${local.account_id}:${var.project}-*"]
  }
}

resource "aws_iam_role" "apply" {
  count = local.oidc_count

  name                 = "${local.name_prefix}-github-apply"
  description          = "GitHub Actions: terraform apply und Upload nach Merge auf main"
  assume_role_policy   = data.aws_iam_policy_document.trust_apply[0].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "apply_permissions" {
  count = local.oidc_count

  name   = "deploy-project-resources"
  role   = aws_iam_role.apply[0].id
  policy = data.aws_iam_policy_document.apply[0].json
}

resource "aws_iam_role_policy" "apply_state" {
  count = local.oidc_count

  name   = "terraform-state"
  role   = aws_iam_role.apply[0].id
  policy = data.aws_iam_policy_document.state_access.json
}

# Bestehende Ressourcen behalten ihre Adresse, seit sie abschaltbar sind.
moved {
  from = aws_iam_openid_connect_provider.github
  to   = aws_iam_openid_connect_provider.github[0]
}

moved {
  from = aws_iam_role.plan
  to   = aws_iam_role.plan[0]
}

moved {
  from = aws_iam_role_policy_attachment.plan_read_only
  to   = aws_iam_role_policy_attachment.plan_read_only[0]
}

moved {
  from = aws_iam_role_policy.plan_state
  to   = aws_iam_role_policy.plan_state[0]
}

moved {
  from = aws_iam_role.apply
  to   = aws_iam_role.apply[0]
}

moved {
  from = aws_iam_role_policy.apply_permissions
  to   = aws_iam_role_policy.apply_permissions[0]
}

moved {
  from = aws_iam_role_policy.apply_state
  to   = aws_iam_role_policy.apply_state[0]
}
