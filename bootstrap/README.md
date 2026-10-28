# Bootstrap

Legt einmalig die Grundlage an, die die Pipeline selbst braucht:

| Ressource | Zweck |
|---|---|
| S3-Bucket `glueckaufgames-tfstate-<Konto-ID>` | Terraform-State: privat, versioniert, verschlüsselt, nur per TLS, Locking über `use_lockfile` |
| OIDC-Provider für GitHub | GitHub Actions meldet sich ohne dauerhafte Schlüssel bei AWS an |
| Rolle `glueckaufgames-github-plan` | nur lesend, nur für Pull Requests aus diesem Repo |
| Rolle `glueckaufgames-github-apply` | darf Projekt-Ressourcen ändern, nur vom Branch `main` |

Der State dieses Ordners bleibt lokal (`terraform.tfstate`), weil der State-Bucket hier erst entsteht. Die Datei ist per `.gitignore` vom Repo ausgeschlossen.

## Ausführen

Voraussetzung: AWS CLI ist mit dem Profil `glueckauf` angemeldet (`aws sso login`).

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
terraform output
```

Die drei Ausgabewerte werden für die nächsten Schritte gebraucht (Backend-Konfiguration und GitHub-Variablen).
