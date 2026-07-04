#!/usr/bin/env bash
#
# Halo Runner — persistent wrapper that keeps the build loop running
# until the backlog is complete, paused, or an escalation needs human attention.
#
# Usage:
#   ./halo-runner.sh                    # runs in current directory
#   ./halo-runner.sh /path/to/project   # runs in specified project
#
# CLI Integration (Devin CLI):
#   The runner auto-detects the Devin CLI (`devin`) and invokes workflows
#   non-interactively. Configure via environment variables:
#
#   HALO_CLI_MODE=auto (default)  # use CLI if found + authenticated, else IDE mode
#   HALO_CLI_MODE=always          # require CLI, fail if not available
#   HALO_CLI_MODE=never           # always use IDE mode (manual invocation)
#
#   DEVIN_PERMISSION_MODE=accept-edits (default)  # auto-approve file edits
#   DEVIN_PERMISSION_MODE=auto                   # read-only auto-approve only
#   DEVIN_PERMISSION_MODE=dangerous              # auto-approve ALL tools
#
# What it does:
#   1. Checks STATE.md for STATUS: ACTIVE
#   2. Invokes the halo-build workflow (via Devin CLI or IDE)
#   3. Waits for completion
#   4. Repeats until STATUS is not ACTIVE
#
# Kill switch:
#   - Set STATUS: PAUSED in STATE.md
#   - Or Ctrl+C to stop this script
#   - Or delete .devin/workflows/halo-build.md
#
# Safety:
#   - Respects all budget caps, cycle caps, and human gates in the workflow
#   - Stops immediately if STATUS is PAUSED, COMPLETE, or if escalations are unresolved
#   - Logs each invocation to halo-runner.log

set -euo pipefail

# --- Configuration ---

PROJECT_DIR="${1:-.}"
STATE_FILE="${PROJECT_DIR}/STATE.md"
LOG_FILE="${PROJECT_DIR}/halo-runner.log"
MAX_RUNS=50  # safety cap — stop after 50 invocations even if still ACTIVE
SLEEP_BETWEEN=5  # seconds to wait between runs

# CLI Integration configuration
HALO_CLI_MODE="${HALO_CLI_MODE:-auto}"              # auto|always|never
DEVIN_PERMISSION_MODE="${DEVIN_PERMISSION_MODE:-accept-edits}"
DEVIN_MODEL="${DEVIN_MODEL:-}"                       # optional model override

# --- Functions ---

log() {
  echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] $*" | tee -a "$LOG_FILE"
}

get_status() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "MISSING"
    return
  fi
  # Extract STATUS field from STATE.md
  grep -m1 '^STATUS:' "$STATE_FILE" | sed 's/STATUS:\s*//' | tr '[:upper:]' '[:lower:]' | tr -d ' '
}

check_escalations() {
  if [[ ! -f "$STATE_FILE" ]]; then
    return 1
  fi
  # Check if there are unresolved escalations (lines with ESC- and no "Resolved: yes")
  if grep -q '### ESC-' "$STATE_FILE" 2>/dev/null; then
    # Check if any escalation does NOT have "Resolved: yes"
    if grep -A5 '### ESC-' "$STATE_FILE" | grep -qi 'Resolved:.*no' 2>/dev/null; then
      return 0  # has unresolved escalations
    fi
  fi
  return 1  # no unresolved escalations
}

# --- Devin CLI Detection ---

DEVIN_BIN=""
DEVIN_AVAILABLE=false

detect_devin_cli() {
  if [[ "$HALO_CLI_MODE" == "never" ]]; then
    log "CLI mode: never — IDE invocation only"
    return 1
  fi

  DEVIN_BIN="$(command -v devin 2>/dev/null || true)"
  if [[ -z "$DEVIN_BIN" ]]; then
    if [[ "$HALO_CLI_MODE" == "always" ]]; then
      log "ERROR: HALO_CLI_MODE=always but 'devin' not found in PATH."
      log "Install: curl -fsSL https://storage.googleapis.com/devin-public/install.sh | bash"
      return 1
    fi
    log "CLI mode: devin not in PATH — falling back to IDE invocation"
    return 1
  fi

  # Check authentication status
  if "$DEVIN_BIN" auth status 2>&1 | grep -qi "Not logged in"; then
    if [[ "$HALO_CLI_MODE" == "always" ]]; then
      log "ERROR: HALO_CLI_MODE=always but devin is not authenticated."
      log "Run: devin auth login"
      return 1
    fi
    log "CLI mode: devin found but not authenticated — falling back to IDE invocation"
    log "  (To enable CLI mode: devin auth login)"
    return 1
  fi

  DEVIN_AVAILABLE=true
  local ver
  ver="$("$DEVIN_BIN" --version 2>/dev/null | head -1 || echo 'unknown')"
  log "CLI mode: devin available (${ver}) at ${DEVIN_BIN}"
  return 0
}

# Invoke a workflow via the Devin CLI in non-interactive (-p) mode.
# Usage: invoke_workflow_cli "${PROJECT_DIR}/.devin/workflows/halo-build.md"
invoke_workflow_cli() {
  local workflow_file="$1"
  local prompt

  # Build the prompt that instructs the agent to follow the workflow file.
  # The workflow files are markdown playbooks — the agent reads and executes them.
  prompt="Follow the workflow instructions in this file precisely: ${workflow_file}
Working directory: ${PROJECT_DIR}
Read STATE.md, HALO.md, and halo-budget.md before starting. Respect all gates, budget caps, denylist paths, and human gates. Pick the next pending story, implement with TDD, run tests, invoke the verifier, deploy the checkpoint, update STATE.md, and report the result."

  local cmd_args=(
    --permission-mode "$DEVIN_PERMISSION_MODE"
    -p "$prompt"
  )

  # Optional model override
  if [[ -n "$DEVIN_MODEL" ]]; then
    cmd_args=(--model "$DEVIN_MODEL" "${cmd_args[@]}")
  fi

  log "  -> CLI: ${DEVIN_BIN} --permission-mode ${DEVIN_PERMISSION_MODE} -p \"<workflow: ${workflow_file##*/}>\""

  # Run from the project directory so the agent has correct workspace context
  (
    cd "$PROJECT_DIR"
    "$DEVIN_BIN" "${cmd_args[@]}" 2>&1 | tee -a "$LOG_FILE"
  )

  return "${PIPESTATUS[0]}"
}

# Invoke a workflow in IDE mode (manual — the human or IDE runs /halo-build)
invoke_workflow_ide() {
  log "  -> IDE mode: Invoke /halo-build in your IDE (Devin/Windsurf)"
  log "  -> Or configure this script to call your AI agent CLI (HALO_CLI_MODE=auto)"
  log "  -> Waiting for cycle to complete..."
  # In IDE mode, the script pauses; the user/IDE runs /halo-build,
  # and when the cycle completes, the script checks status again.
}

# --- Main ---

log "=== Halo Runner started ==="
log "Project: $(cd "$PROJECT_DIR" && pwd)"
log "Max runs: $MAX_RUNS"
log "CLI mode: $HALO_CLI_MODE  (permission: $DEVIN_PERMISSION_MODE${DEVIN_MODEL:+, model: $DEVIN_MODEL})"

# Detect CLI availability once at startup
detect_devin_cli || true

run_count=0

while true; do
  run_count=$((run_count + 1))

  if [[ $run_count -gt $MAX_RUNS ]]; then
    log "SAFETY CAP: Reached max runs ($MAX_RUNS). Stopping."
    log "If the backlog is not complete, investigate and restart manually."
    break
  fi

  status=$(get_status)

  case "$status" in
    active)
      # Check for unresolved escalations before running
      if check_escalations; then
        log "PAUSING: Unresolved escalations detected in STATE.md."
        log "Human action required. Review the Escalations section in STATE.md."
        break
      fi

      log "Run #${run_count}: STATUS is ACTIVE — invoking /halo-build"

      # Check that the workflow file exists
      if [[ ! -f "${PROJECT_DIR}/.devin/workflows/halo-build.md" ]]; then
        log "ERROR: .devin/workflows/halo-build.md not found."
        log "The workflow file may have been deleted (kill switch). Stopping."
        break
      fi

      # Dispatch to CLI or IDE depending on availability + mode
      if [[ "$DEVIN_AVAILABLE" == "true" ]]; then
        # CLI mode — invoke non-interactively and block until done
        if invoke_workflow_cli "${PROJECT_DIR}/.devin/workflows/halo-build.md"; then
          log "  -> Cycle ${run_count} complete (CLI exit: 0)."
        else
          cli_exit=$?
          log "  -> Cycle ${run_count} CLI exit: ${cli_exit}. Checking STATE.md for status changes..."
          # Non-zero exit doesn't mean abort — the workflow may have paused/escalated intentionally.
          # Re-read STATE.md on the next loop iteration to decide.
        fi
      else
        # IDE mode — manual invocation, wait for human/IDE to run /halo-build
        invoke_workflow_ide
      fi

      log "  -> Sleeping ${SLEEP_BETWEEN}s before next check..."
      sleep "$SLEEP_BETWEEN"
      ;;

    paused)
      log "STOPPING: STATUS is PAUSED in STATE.md."
      log "To resume: set STATUS: ACTIVE in STATE.md and restart this script."
      break
      ;;

    complete)
      log "BACKLOG COMPLETE: All stories have been deployed."
      log "Review STATE.md deployment history and promote checkpoints to production."
      break
      ;;

    missing)
      log "ERROR: STATE.md not found at ${STATE_FILE}"
      log "Run /halo-init first to initialize Halo for this project."
      break
      ;;

    *)
      log "UNKNOWN STATUS: '${status}'. Stopping for safety."
      log "Check STATE.md and set STATUS: ACTIVE to resume."
      break
      ;;
  esac
done

log "=== Halo Runner stopped after ${run_count} runs ==="
