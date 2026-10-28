# glueckaufgames-cloud

## Aufbau

```
bootstrap/            einmalig: State-Bucket und OIDC-Rollen
terraform/            Infrastruktur der Website
  modules/storage/    S3-Buckets und Replikation
  modules/cdn/        CloudFront, OAC, Security-Header, Bucket-Richtlinien
  modules/monitoring/ Budget und CloudWatch-Alarm
website/              Inhalte der Website
.github/workflows/    Pipeline
```

## Installation

Voraussetzungen: AWS-Konto, AWS CLI v2 (angemeldet, z. B. per `aws sso login`), Terraform ≥ 1.11, GitHub-Repository.

1. **Bootstrap ausführen** (siehe `bootstrap/README.md`):
   ```bash
   cd bootstrap
   terraform init && terraform apply
   terraform output
   ```
2. **Backend eintragen:** den Wert `state_bucket` in `terraform/versions.tf` bei `bucket` eintragen.

## Lokal ausführen 

```bash
cd terraform
export TF_VAR_alert_email="name@example.com"
terraform init
terraform plan
```

## Abbauen

```bash
cd terraform && terraform destroy
```

Der Bootstrap ist mit `prevent_destroy` geschützt und muss bei Bedarf gesondert entfernt werden.
