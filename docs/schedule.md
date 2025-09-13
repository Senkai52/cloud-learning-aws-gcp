# Weekly Checklist (Kanban-ready)

> Haken setzen, bei Bedarf Issues verfeinern. Jede Woche ist ein **Epic** mit untergeordneten Tasks.

## Phase 1 — AWS (12 Wochen)

### Woche 1–2: Grundlagen
- [ ] AWS Account & Free Tier prüfen
- [ ] IAM: Nutzer + minimale Rollen
- [ ] EC2: Linux VM starten, SSH, Security Groups üben
- [ ] S3: Bucket + Upload + Lifecycle
- [ ] Doc-Review: Global Services, Regions vs AZs

### Woche 3–4: DB & API-Basis
- [ ] RDS (PostgreSQL) anlegen + psql-Verbindung
- [ ] (Optional) DynamoDB: CRUD-Übung
- [ ] FastAPI/Flask lokal + SQLAlchemy + Alembic
- [ ] API: Healthcheck + CRUD + .env Handling

### Woche 5–6: Serverless APIs
- [ ] Lambda „Hello World“ + IAM-Rolle
- [ ] API Gateway + Lambda Integration
- [ ] FastAPI als Lambda (z. B. AWS SAM / Lambda Powertools)
- [ ] Vergleich: Kaltstart, Logging, Kosten

### Woche 7–8: Container
- [ ] Dockerize FastAPI (multi-stage build)
- [ ] Push zu ECR
- [ ] Deploy zu ECS Fargate (Service + Task + ALB)
- [ ] (Optional) EKS Grundlagen

### Woche 9–10: Monitoring, Messaging, Security
- [ ] CloudWatch Logs, Metrics, Alarms
- [ ] SQS + SNS Mini-Flow (Producer/Consumer)
- [ ] IAM Policies härten (least privilege)
- [ ] Kostenüberwachung (AWS Cost Explorer)

### Woche 11–12: Mini-Projekt + Zertifikat
- [ ] End-to-End: API + RDS + S3 (Lambda **oder** ECS)
- [ ] README Dokumentation + Architecture Diagram
- [ ] Zertifikatsvorbereitung: AWS DVA-C02 Notizen
- [ ] LinkedIn Post mit Demo-Link

---

## Phase 2 — GCP (8 Wochen)

### Woche 1–2: Grundlagen
- [ ] GCP Account + Free Tier
- [ ] IAM: Rollen/Policies
- [ ] Compute Engine VM + Firewall Regeln
- [ ] Cloud Storage Bucket + Objektversionierung

### Woche 3–4: APIs & Datenbanken
- [ ] Cloud SQL (PostgreSQL) + Verbindung über Cloud SQL Proxy
- [ ] Cloud Run Deployment (Docker Image von GitHub Packages/GCR)
- [ ] API → Cloud SQL + Cloud Storage Upload

### Woche 5–6: Serverless & AI
- [ ] Cloud Functions „Hello World“
- [ ] Cloud Logging + Alerts
- [ ] Vertex AI: Text-Generation API integrieren

### Woche 7–8: Mini-Projekt & Zertifikat
- [ ] End-to-End: Cloud Run + Cloud SQL + Cloud Storage
- [ ] Kurze Kostenanalyse & Hardening
- [ ] (Optional) ACE Zertifikatvorbereitung
- [ ] LinkedIn Post mit Vergleich AWS vs GCP

