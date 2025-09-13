#!/usr/bin/env bash
# Setup GitHub labels, create a Project (v2) Kanban, and seed issues.
# Requirements: gh CLI (>=2.32), authenticated; jq installed.

set -euo pipefail

REPO_SLUG="${1:-}"
if [[ -z "$REPO_SLUG" ]]; then
  echo "Usage: ./scripts/setup_github.sh <owner/repo>"
  exit 1
fi

# 1) Apply labels
echo "Applying labels..."
gh api -X GET repos/$REPO_SLUG/labels -q '.[].name' >/dev/null || true
while read -r name color desc; do
  # upsert
  gh api -X POST "repos/$REPO_SLUG/labels" \
    -f name="$name" -f color="$color" -f description="$desc" >/dev/null 2>&1 || \
  gh api -X PATCH "repos/$REPO_SLUG/labels/$(echo "$name" | sed 's/ /%20/g')" \
    -f new_name="$name" -f color="$color" -f description="$desc" >/dev/null
done <<'LABELS'
type: epic 5319e7 High-level\ epic
type: task 1d76db Atomic\ task
phase: aws ff9900 AWS\ phase
phase: gcp 34a853 GCP\ phase
area: api 0e8a16 API/Backend\ work
area: db c2e0c6 Database\ work
area: serverless fbca04 Lambda/Cloud\ Run
area: containers 0052cc Docker/ECS/EKS/GKE
area: ai 6f42c1 AI/Vertex/Bedrock
good first issue 7057ff Starter\ task
LABELS

# 2) Create a user project (Projects v2) named "Cloud Learning Kanban"
echo "Creating GitHub Project (v2)..."
PROJECT_TITLE="Cloud Learning Kanban"
PROJECT_ID=$(gh project list --owner $(echo $REPO_SLUG | cut -d'/' -f1) --format json | jq -r '.[] | select(.title=="'"$PROJECT_TITLE"'") | .id')
if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "null" ]]; then
  PROJECT_ID=$(gh project create --owner $(echo $REPO_SLUG | cut -d'/' -f1) --title "$PROJECT_TITLE" --format json | jq -r '.id')
  echo "Created project: $PROJECT_ID"
else
  echo "Project already exists: $PROJECT_ID"
fi

# 3) Seed issues for weeks and key tasks (AWS only; GCP similar pattern).
echo "Creating issues..."
create_issue() {
  local title="$1"; shift
  local body="$1"; shift
  local labels="$1"; shift
  gh issue create --repo "$REPO_SLUG" --title "$title" --body "$body" --label $labels --assignee "@me" --milestone "" >/dev/null
}

# --- AWS Epics ---
create_issue "[EPIC] AWS Woche 1–2 · Grundlagen" "Siehe docs/schedule.md" "type: epic,phase: aws"
create_issue "[EPIC] AWS Woche 3–4 · DB & API" "Siehe docs/schedule.md" "type: epic,phase: aws"
create_issue "[EPIC] AWS Woche 5–6 · Serverless" "Siehe docs/schedule.md" "type: epic,phase: aws"
create_issue "[EPIC] AWS Woche 7–8 · Container" "Siehe docs/schedule.md" "type: epic,phase: aws"
create_issue "[EPIC] AWS Woche 9–10 · Monitoring & Messaging" "Siehe docs/schedule.md" "type: epic,phase: aws"
create_issue "[EPIC] AWS Woche 11–12 · Mini-Projekt + Zertifikat" "Siehe docs/schedule.md" "type: epic,phase: aws"

# --- Sample Tasks (you can add more) ---
create_issue "[TASK] EC2 Linux VM starten + SSH" "- Security Group, Keypair, Login" "type: task,phase: aws"
create_issue "[TASK] S3 Bucket + Upload + Lifecycle Rule" "- Versioning, Lifecycle 30d→IA" "type: task,phase: aws"
create_issue "[TASK] RDS PostgreSQL anlegen + psql verbinden" "- Public/Private subnet, SG" "type: task,phase: aws,area: db"
create_issue "[TASK] FastAPI CRUD lokal + SQLAlchemy + Alembic" "- Healthcheck, .env" "type: task,phase: aws,area: api"
create_issue "[TASK] Lambda + API Gateway Hello World" "- IAM Rolle, Logs in CloudWatch" "type: task,phase: aws,area: serverless"
create_issue "[TASK] FastAPI auf Lambda (SAM)" "- Build, Deploy, Invoke" "type: task,phase: aws,area: serverless"
create_issue "[TASK] Dockerize API + Push zu ECR" "- Multi-stage build" "type: task,phase: aws,area: containers"
create_issue "[TASK] ECS Fargate Service + ALB" "- Task Def, Service, Target Group" "type: task,phase: aws,area: containers"
create_issue "[TASK] CloudWatch Alarm für 5xx" "- E-Mail Alarm" "type: task,phase: aws"
create_issue "[TASK] SQS Producer/Consumer Demo" "- Queue, Policy, Test" "type: task,phase: aws"
create_issue "[TASK] End-to-End Projekt dokumentieren" "- README, Diagramm" "type: task,phase: aws"

# 4) Add issues to the Project
echo "Adding issues to project..."
for ISSUE in $(gh issue list --repo "$REPO_SLUG" --limit 50 --json number --jq '.[].number'); do
  gh project item-add $PROJECT_ID --owner $(echo $REPO_SLUG | cut -d'/' -f1) --url "https://github.com/$REPO_SLUG/issues/$ISSUE" >/dev/null || true
done

echo "Done. Open your project board and start moving cards across columns."
