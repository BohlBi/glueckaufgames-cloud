# glueckaufgames-cloud

Hochverfügbare Website auf AWS mit Terraform – IU Cloud Programming (DLBSEPCP01_D), Aufgabe 1.

## Architektur

- **Amazon S3** (Frankfurt): privater, versionierter, verschlüsselter Bucket für die Website
- **S3-Replikation** nach Irland als Ausweichstandort
- **Amazon CloudFront**: weltweite Auslieferung, Zugriff auf die Buckets nur über Origin Access Control, automatischer Failover nach Irland, nur HTTPS, Security-Header
- **AWS Budgets**: E-Mail bei 80 % von 10 USD pro Monat
- **Amazon CloudWatch**: E-Mail bei mehr als 5 % Serverfehlern
- **GitHub Actions**: Prüfung bei jedem Pull Request, Deployment nach Merge auf `main`, Anmeldung bei AWS über OIDC ohne dauerhafte Schlüssel

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
3. **GitHub-Variablen anlegen** (Settings → Secrets and variables → Actions → Variables):

   | Name | Wert |
   |---|---|
   | `AWS_PLAN_ROLE_ARN` | Ausgabe `github_plan_role_arn` |
   | `AWS_APPLY_ROLE_ARN` | Ausgabe `github_apply_role_arn` |
   | `ALERT_EMAIL` | E-Mail-Adresse für Alarme |

4. **Branch-Schutz für `main`** einrichten (Settings → Branches): Pull Request und erfolgreiche Prüfung vor dem Merge verlangen.
5. **Pull Request öffnen und mergen.** Die Pipeline legt die Infrastruktur an, lädt die Website hoch und gibt die Adresse aus.
6. **E-Mail von AWS SNS bestätigen**, damit die CloudWatch-Alarme ankommen.

## Lokal ausführen (optional)

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
