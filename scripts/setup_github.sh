#!/usr/bin/env bash
# Setup GitHub labels, create a Project (v2) Kanban, and seed issues.
# Requirements: gh CLI (>=2.32), authenticated; jq installed.

set -euo pipefail

REPO_SLUG="${1:-}"
if [[ -z "$REPO_SLUG" ]]; then
  echo "Usage: ./scripts/setup_github.sh <owner/repo>"
  exit 1
fi

echo "Applying labels..."
# Upsert-Labels mit robustem Parsing (name|hexcolor|description)
while IFS='|' read -r name hex desc; do
  echo "  - $name ($hex)"
  # create (falls neu), sonst update
  if ! gh label create "$name" --color "$hex" --description "$desc" --repo "$REPO_SLUG" >/dev/null 2>&1; then
    gh label edit "$name" --color "$hex" --description "$desc" --repo "$REPO_SLUG" >/dev/null
  fi
done <<'LABELS'
type: epic|5319e7|High-level epic
type: task|1d76db|Atomic task
phase: aws|ff9900|AWS phase
phase: gcp|34a853|GCP phase
area: api|0e8a16|API/Backend work
area: db|c2e0c6|Database work
area: serverless|fbca04|Lambda/Cloud Run
area: containers|0052cc|Docker/ECS/EKS/GKE
area: ai|6f42c1|AI/Vertex/Bedrock
good first issue|7057ff|Starter task
LABELS

# 2) Create a user project (Projects v2) named "Cloud Learning Kanban"
echo "Creating GitHub Project (v2)..."
OWNER="$(echo "$REPO_SLUG" | cut -d'/' -f1)"
PROJECT_TITLE="Cloud Learning Kanban"

# Erst versuchen wir das Project direkt zu erstellen.
set +e
CREATE_JSON="$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json 2>/dev/null)"
CREATE_RC=$?
set -e

if [ $CREATE_RC -eq 0 ] && [ -n "$CREATE_JSON" ]; then
  PROJECT_ID="$(echo "$CREATE_JSON" | jq -r '.id')"
  echo "Created project: $PROJECT_ID"
else
  echo "Project might already exist; resolving ID…"
  # Fallback: nimm das erste Project mit passendem Titel (robuster ohne komplexes jq)
  LIST_JSON="$(gh project list --owner "$OWNER" --format json 2>/dev/null || true)"
  PROJECT_ID="$(echo "$LIST_JSON" | jq -r 'map(select(.title=="'"$PROJECT_TITLE"'")) | .[0].id // empty')"
  if [ -z "$PROJECT_ID" ]; then
    echo "WARN: Konnte die Project-ID nicht ermitteln. Die Issues werden trotzdem erstellt; füge sie später manuell zu einem Project hinzu."
  else
    echo "Using existing project: $PROJECT_ID"
  fi
fi
