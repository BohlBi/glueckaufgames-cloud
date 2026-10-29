# glueckaufgames-cloud

## Aufbau

```
bootstrap/            State-Bucket und OIDC-Rollen
terraform/            Infrastruktur der Website
  modules/storage/    S3-Buckets und Replikation
  modules/cdn/        CloudFront, OAC, Security-Header, Bucket-Richtlinien
  modules/monitoring/ Budget und CloudWatch-Alarm
website/              Inhalte der Website
.github/workflows/    Pipeline
```

## Installation

Voraussetzungen: AWS-Konto, AWS CLI v2 (angemeldet, z. B. per `aws sso login`), Terraform ≥ 1.11

1. **Repository klonen**
   ```bash
   git clone https://github.com/BohlBi/glueckaufgames-cloud.git
   cd glueckaufgames-cloud
   ```

2. **Bootstrap ausführen** (legt den State-Bucket an)
   ```bash
   cd bootstrap
   terraform init
   terraform apply -var="enable_github_oidc=false"
   cd ..
   ```
   `enable_github_oidc=false` lässt die GitHub-Anbindung weg, sie wird nur für die Pipeline gebraucht.

3. **Infrastruktur und Website bereitstellen**
   ```bash
   cd terraform
   terraform init -backend-config="bucket=$(terraform -chdir=../bootstrap output -raw state_bucket)"
   terraform apply -var="alert_email=name@example.com"
   ```
   CloudFront braucht beim ersten Mal 5–15 Minuten.

4. **Website aufrufen**
   ```bash
   terraform output website_url
   ```

5. **E-Mail von AWS SNS bestätigen** („Confirm subscription“), damit die Alarme ankommen.

## Abbauen

```bash
cd terraform && terraform destroy -var="alert_email=name@example.com"
```

Der Bootstrap ist mit `prevent_destroy` geschützt und muss bei Bedarf gesondert entfernt werden.

## Hinweis zum Einsatz von KI

Bei Konzeption, Terraform-Code und Dokumentation wurde der KI-Assistent Claude (Anthropic) unterstützend eingesetzt. Alle Inhalte wurden eigenständig geprüft, getestet und verantwortet.
