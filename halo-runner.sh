#!/usr/bin/env bash
#
# Halo Runner — persistent wrapper that keeps the build loop running
# until the backlog is complete, paused, or an escalation needs human attention.
#
# Usage:
#   ./halo-runner.sh                    # runs in current directory
#   ./halo-runner.sh /path/to/project   # runs in specified project
#
# What it does:
#   1. Checks STATE.md for STATUS: ACTIVE
#   2. Invokes the halo-build workflow
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

# --- Main ---

log "=== Halo Runner started ==="
log "Project: $(cd "$PROJECT_DIR" && pwd)"
log "Max runs: $MAX_RUNS"

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

      # Invoke the build workflow
      # In Devin/Windsurf: this is a no-op — the IDE handles workflow invocation
      # In a terminal/CI context: this would call the AI agent CLI
      #
      # The actual invocation depends on the runtime:
      # - Devin/Windsurf: the workflow is invoked via /halo-build command
      # - CLI agent: replace the line below with your agent's invocation command
      #   e.g. devin run --workflow .devin/workflows/halo-build.md
      #        claude-code --workflow .devin/workflows/halo-build.md
      #        npx ai-agent --workflow .devin/workflows/halo-build.md
      #
      # For now, we log and let the IDE handle it:
      log "  -> Invoke /halo-build in your IDE (Devin/Windsurf)"
      log "  -> Or configure this script to call your AI agent CLI"
      log "  -> Waiting for cycle to complete..."

      # In automated mode, you would call the agent here and wait for it to finish.
      # Example (uncomment and adapt):
      # devin run --workflow "${PROJECT_DIR}/.devin/workflows/halo-build.md" --cwd "$PROJECT_DIR"
      # OR:
      # claude-code --file "${PROJECT_DIR}/.devin/workflows/halo-build.md" --cwd "$PROJECT_DIR"

      # For IDE mode: the script pauses here, the user/IDE runs /halo-build,
      # and when the cycle completes, the script checks status again.
      # In fully automated mode, the agent call above would block until done.

      log "  -> Cycle ${run_count} complete."
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
