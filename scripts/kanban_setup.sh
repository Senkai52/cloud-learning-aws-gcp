#!/usr/bin/env bash
# Kanban Setup Script (idempotent, works with older gh versions)
# - Creates/updates labels
# - Creates (or resolves) a user Project "Cloud Learning Kanban" and gets its NUMBER
# - Seeds AWS + GCP epics/tasks as issues (no duplicates by title)
# - Adds all created/found issues to the project board
#
# Usage: ./kanban_setup.sh <owner/repo>
# Example: ./kanban_setup.sh Senkai52/cloud-learning-aws-gcp
#
# Requirements:
# - gh CLI logged in with scopes: repo, project, read:project
# - awk, grep available

set -euo pipefail

REPO_SLUG="${1:-}"
if [[ -z "$REPO_SLUG" ]]; then
  echo "Usage: $0 <owner/repo>"
  exit 1
fi

OWNER="$(echo "$REPO_SLUG" | cut -d'/' -f1)"
PROJECT_TITLE="Cloud Learning Kanban"

info(){ echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn(){ echo -e "\033[1;33m[WARN]\033[0m $*"; }
ok(){ echo -e "\033[1;32m[OK]\033[0m $*"; }

# -------- Labels (upsert) --------
info "Applying labels to $REPO_SLUG ..."
apply_label() {
  local name="$1" hex="$2" desc="$3"
  if ! gh label create "$name" --color "$hex" --description "$desc" --repo "$REPO_SLUG" >/dev/null 2>&1; then
    gh label edit "$name" --color "$hex" --description "$desc" --repo "$REPO_SLUG" >/dev/null || true
  fi
}

apply_label "type: epic" "5319e7" "High-level epic"
apply_label "type: task" "1d76db" "Atomic task"
apply_label "phase: aws" "ff9900" "AWS phase"
apply_label "phase: gcp" "34a853" "GCP phase"
apply_label "area: api" "0e8a16" "API/Backend work"
apply_label "area: db" "c2e0c6" "Database work"
apply_label "area: serverless" "fbca04" "Lambda/Cloud Run"
apply_label "area: containers" "0052cc" "Docker/ECS/EKS/GKE"
apply_label "area: ai" "6f42c1" "AI/Vertex/Bedrock"
apply_label "good first issue" "7057ff" "Starter task"
ok "Labels ready."

# -------- Project number (table parsing for old gh) --------
info "Resolving project number for \"$PROJECT_TITLE\" (owner: $OWNER) ..."
PROJECT_NUMBER="$(gh project list --owner "$OWNER" \
  | awk -v t="$PROJECT_TITLE" 'NR>1 && index($0,t){print $1}' \
  | sort -nr | head -n1)" || PROJECT_NUMBER=""

if [[ -z "${PROJECT_NUMBER}" ]]; then
  info "No existing project found. Creating \"$PROJECT_TITLE\" ..."
  gh project create --owner "$OWNER" --title "$PROJECT_TITLE" >/dev/null
  PROJECT_NUMBER="$(gh project list --owner "$OWNER" \
    | awk -v t="$PROJECT_TITLE" 'NR>1 && index($0,t){print $1}' \
    | sort -nr | head -n1)"
fi

if [[ -z "${PROJECT_NUMBER}" ]]; then
  warn "Could not resolve project number. Items will NOT be added to a board."
else
  ok "Using project number: ${PROJECT_NUMBER}"
fi

# -------- Helpers --------
urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

find_issue_url_by_title() {
  local title="$1"
  # Try search API
  local q="repo:${REPO_SLUG} type:issue in:title \"${title}\""
  local q_enc; q_enc="$(urlencode "$q")"
  gh api -X GET "search/issues?q=${q_enc}&per_page=1" --jq '.items[0].html_url // empty' 2>/dev/null || true
}

create_issue_stdout_url() {
  local title="$1"; shift
  local body="$1"; shift
  shift || true # labels passed via "$@"

  local out
  # Older gh: parse URL from stdout
  out="$(gh issue create --repo "$REPO_SLUG" --title "$title" --body "$body" "$@" 2>/dev/null || true)"
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

  # 1) existing?
  local existing; existing="$(find_issue_url_by_title "$title")"
  if [[ -n "$existing" ]]; then
    echo "$existing"; return 0
  fi

  # 2) labels
  local args=()
  IFS=',' read -ra LBL <<< "$labels_csv"
  for l in "${LBL[@]}"; do args+=(--label "$l"); done

  # 3) create
  create_issue_stdout_url "$title" "$body" "${args[@]}"
}

seed_array() {
  local -n arr=$1
  for entry in "${arr[@]}"; do
    local title="${entry%%|*}"
    local rest="${entry#*|}"
    local body="${rest%%|*}"
    local labels="${rest#*|}"

    info "Issue: $title"
    local url; url="$(create_or_get_issue "$title" "$body" "$labels")"
    if [[ -z "$url" ]]; then
      warn "Could not create/find URL for: $title"
      continue
    fi
    add_to_project "$url"
  done
}

# -------- Content (short bodies; you can enrich later with enrich_issues.sh) --------
AWS_EPICS=(
  "[EPIC] AWS Woche 1–2 · Grundlagen|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 3–4 · DB & API|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 5–6 · Serverless|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 7–8 · Container|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 9–10 · Monitoring & Messaging|Siehe docs/schedule.md|type: epic,phase: aws"
  "[EPIC] AWS Woche 11–12 · Mini-Projekt + Zertifikat|Siehe docs/schedule.md|type: epic,phase: aws"
)

AWS_TASKS=(
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

GCP_EPICS=(
  "[EPIC] GCP Woche 1–2 · Grundlagen|Siehe docs/schedule.md|type: epic,phase: gcp"
  "[EPIC] GCP Woche 3–4 · APIs & Datenbanken|Siehe docs/schedule.md|type: epic,phase: gcp"
  "[EPIC] GCP Woche 5–6 · Serverless & AI|Siehe docs/schedule.md|type: epic,phase: gcp"
  "[EPIC] GCP Woche 7–8 · Mini-Projekt & Zertifikat|Siehe docs/schedule.md|type: epic,phase: gcp"
)

GCP_TASKS=(
  "[TASK] GCP VM + Cloud Storage|- Compute Engine + Bucket|type: task,phase: gcp"
  "[TASK] Cloud SQL (PostgreSQL) verbinden|- Cloud SQL Proxy/Connector|type: task,phase: gcp,area: db"
  "[TASK] Cloud Run Deployment|- Docker Image + Service|type: task,phase: gcp,area: containers"
  "[TASK] API → Cloud SQL + Cloud Storage|- Upload + CRUD|type: task,phase: gcp,area: api"
  "[TASK] Cloud Functions Hello World|- Trigger + Logs|type: task,phase: gcp,area: serverless"
  "[TASK] Vertex AI Textgen Demo|- API Call, Prompt|type: task,phase: gcp,area: ai"
  "[TASK] End-to-End (Run+SQL+Storage)|- Docs + Kosten|type: task,phase: gcp"
)

info "Seeding AWS epics...";   seed_array AWS_EPICS
info "Seeding AWS tasks...";   seed_array AWS_TASKS
info "Seeding GCP epics...";   seed_array GCP_EPICS
info "Seeding GCP tasks...";   seed_array GCP_TASKS

ok "Done. Open your board:"
echo "gh project view ${PROJECT_NUMBER} --owner ${OWNER} --web"
