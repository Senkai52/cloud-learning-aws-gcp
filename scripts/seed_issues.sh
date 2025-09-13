#!/usr/bin/env bash
set -euo pipefail

OWNER_REPO="${1:-}"          # z.B. Senkai52/cloud-learning-aws-gcp
PROJECT_TITLE="${2:-Cloud Learning Kanban}"

if [[ -z "$OWNER_REPO" ]]; then
  echo "Usage: ./scripts/seed_issues.sh <owner/repo> [PROJECT_TITLE]"
  exit 1
fi

OWNER="$(echo "$OWNER_REPO" | cut -d'/' -f1)"
REPO="$OWNER_REPO"

echo "Resolving project number for: $PROJECT_TITLE"
# Nimm die höchste Projektnummer (erste Spalte), deren Titel die Zeichenkette enthält
PROJECT_NUMBER="$(gh project list --owner "$OWNER" \
  | awk -v t="$PROJECT_TITLE" 'NR>1 && index($0,t){print $1}' \
  | sort -nr | head -n1)"

# Falls keins existiert: anlegen und nochmal ermitteln (ebenfalls tabellarisch)
if [[ -z "${PROJECT_NUMBER}" ]]; then
  echo "No existing project found. Creating \"$PROJECT_TITLE\"…"
  gh project create --owner "$OWNER" --title "$PROJECT_TITLE" >/dev/null
  PROJECT_NUMBER="$(gh project list --owner "$OWNER" \
    | awk -v t="$PROJECT_TITLE" 'NR>1 && index($0,t){print $1}' \
    | sort -nr | head -n1)"
fi

if [[ -z "${PROJECT_NUMBER}" ]]; then
  echo "ERROR: Could not resolve project number. Please verify 'gh project list --owner $OWNER'."
  exit 1
fi

echo "Using project number: ${PROJECT_NUMBER}"

# ---- Helpers ----

urlencode() {
  # URL-encode via jq
  jq -rn --arg s "$1" '$s|@uri'
}

find_issue_url_by_title() {
  local title="$1"
  # Suche per Search API (exakter Titel in:title). Achtung: Rate-Limits selten relevant hier.
  local q="repo:${OWNER_REPO} type:issue in:title \"${title}\""
  local q_enc; q_enc="$(urlencode "$q")"
  gh api -X GET "search/issues?q=${q_enc}&per_page=1" --jq '.items[0].html_url // empty' 2>/dev/null || true
}

create_issue_stdout_url() {
  local title="$1"; shift
  local body="$1"; shift
  shift || true  # labels_csv (nicht benötigt hier)

  # Ältere gh-Version: keine --json → URL aus stdout herausgreifen
  local out
  out="$(gh issue create --repo "$REPO" --title "$title" --body "$body" "$@" 2>/dev/null || true)"
  echo "$out" | grep -Eo 'https://github.com/[^ ]+/issues/[0-9]+' | head -n1
}

add_to_project() {
  local issue_url="$1"
  if [[ -n "${issue_url}" && -n "${PROJECT_NUMBER}" ]]; then
    gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$issue_url" >/dev/null 2>&1 || true
  fi
}

create_or_get_issue() {
  local title="$1"; shift
  local body="$1"; shift
  local labels_csv="$1"; shift

  # 1) Existiert bereits?
  local existing; existing="$(find_issue_url_by_title "$title")"
  if [[ -n "$existing" ]]; then
    echo "$existing"
    return 0
  fi

  # 2) Labels vorbereiten
  local args=()
  IFS=',' read -ra LBL <<< "$labels_csv"
  for l in "${LBL[@]}"; do args+=(--label "$l"); done

  # 3) Neu anlegen
  create_issue_stdout_url "$title" "$body" "${args[@]}"
}

seed_array() {
  local -n arr=$1
  for entry in "${arr[@]}"; do
    local title="${entry%%|*}"
    local rest="${entry#*|}"
    local body="${rest%%|*}"
    local labels="${rest#*|}"

    echo " - $title"
    local url; url="$(create_or_get_issue "$title" "$body" "$labels")"
    if [[ -z "$url" ]]; then
      echo "   WARN: Konnte URL nicht ermitteln/erstellen für: $title"
      continue
    fi
    add_to_project "$url"
  done
}

echo "Seeding AWS + GCP issues…"

# -------- AWS EPICS --------
declare -a AWS_EPICS=(
  "[EPIC] AWS Woche 1–2 · Grundlagen|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 3–4 · DB & API|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 5–6 · Serverless|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 7–8 · Container|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 9–10 · Monitoring & Messaging|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 11–12 · Mini-Projekt + Zertifikat|Siehe docs/schedule.md|type: epic,phase: aws"
)

# -------- AWS TASKS --------
declare -a AWS_TASKS=(
  "[TASK] EC2 Linux VM starten + SSH|- Security Group, Keypair, Login|type: task,phase: aws,area: api"
  "[TASK] S3 Bucket + Upload + Lifecycle|- Versioning, Lifecycle 30d→IA|type: task,phase: aws"
  "[TASK] RDS PostgreSQL anlegen + psql verbinden|- Public/Private subnet, SG|type: task,phase: aws,area: db"
  "[TASK] FastAPI CRUD lokal + SQLAlchemy + Alembic|- Healthcheck, .env|type: task,phase: aws,area: api"
  "[TASK] Lambda + API Gateway Hello World|- IAM Rolle, Logs in CloudWatch|type: task,phase: aws,area: serverless"
  "[TASK] FastAPI auf Lambda (SAM)|- Build, Deploy, Invoke|type: task,phase: aws,area: serverless"
  "[TASK] Dockerize API + Push zu ECR|- Multi-stage build|type: task,phase: aws,area: containers"
  "[TASK] ECS Fargate Service + ALB|- Task Def, Service, Target Group|type: task,phase: aws,area: containers"
  "[TASK] CloudWatch Alarm für 5xx|- E-Mail Alarm|type: task,phase: aws"
  "[TASK] SQS Producer/Consumer Demo|- Queue, Policy, Test|type: task,phase: aws"
  "[TASK] End-to-End Projekt dokumentieren|- README, Diagramm|type: task,phase: aws"
)

# -------- GCP EPICS --------
declare -a GCP_EPICS=(
  "[EPIC] GCP Woche 1–2 · Grundlagen|Siehe docs/schedule.md|type: epic,phase: gcp"
  "[EPIC] GCP Woche 3–4 · APIs & Datenbanken|Siehe docs/schedule.md|type: epic,phase: gcp"
  "[EPIC] GCP Woche 5–6 · Serverless & AI|Siehe docs/schedule.md|type: epic,phase: gcp"
  "[EPIC] GCP Woche 7–8 · Mini-Projekt & Zertifikat|Siehe docs/schedule.md|type: epic,phase: gcp"
)

# -------- GCP TASKS --------
declare -a GCP_TASKS=(
  "[TASK] GCP VM + Cloud Storage|- Compute Engine + Bucket|type: task,phase: gcp"
  "[TASK] Cloud SQL (PostgreSQL) verbinden|- Cloud SQL Proxy/Connector|type: task,phase: gcp,area: db"
  "[TASK] Cloud Run Deployment|- Docker Image + Service|type: task,phase: gcp,area: containers"
  "[TASK] API → Cloud SQL + Cloud Storage|- Upload + CRUD|type: task,phase: gcp,area: api"
  "[TASK] Cloud Functions Hello World|- Trigger + Logs|type: task,phase: gcp,area: serverless"
  "[TASK] Vertex AI Textgen Demo|- API Call, Prompt|type: task,phase: gcp,area: ai"
  "[TASK] End-to-End (Run+SQL+Storage)|- Docs + Kosten|type: task,phase: gcp"
)

seed_array AWS_EPICS
seed_array AWS_TASKS
seed_array GCP_EPICS
seed_array GCP_TASKS

echo "✅ Done. Open your board:"
echo "gh project view ${PROJECT_NUMBER} --owner ${OWNER} --web"
