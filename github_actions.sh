# Scripts to make working with Github Actions easier

# Function to trigger a GitHub workflow and open it
trigger_and_open_workflow() {
  local full_workflow_path=$1
  if [[ -z "$full_workflow_path" ]]; then
    echo "Error: No workflow file path provided."
    echo "Usage: trigger_and_open_workflow ./.github/workflows/example.yml"
    return 1
  fi

  local workflow_file=${full_workflow_path##*/workflows/}
  if [[ -z "$workflow_file" ]]; then
    echo "Error: Could not extract workflow file from path: $full_workflow_path"
    return 1
  fi

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to get current Git branch."
    return 1
  fi

  echo "Current branch: $current_branch"
  echo "Using workflow file: $workflow_file"

  # Run the workflow
  if ! gh workflow run "$workflow_file" --ref "$current_branch"; then
    echo "Error: Failed to trigger workflow run for $workflow_file."
    return 1
  fi

  # Attempt to find the started workflow run
  for attempt in {1..5}; do
    sleep 2
    echo "Looking for newly started run for workflow: $workflow_file"

    recent_runs=$(gh run list --workflow="$workflow_file" --limit=1 --json status,databaseId 2>/dev/null)
    if [[ $? -ne 0 || -z "$recent_runs" ]]; then
      echo "Error: Failed to retrieve workflow runs. Retry attempt $attempt of 5..."
      continue
    fi

    run_status=$(echo "$recent_runs" | jq -r '.[0].status // empty')
    run_url=$(echo "$recent_runs" | jq -r '.[0].databaseId // empty')

    if [[ -z "$run_status" || -z "$run_url" ]]; then
      echo "Error: Could not extract workflow run information. Retry attempt $attempt of 5..."
      continue
    fi

    if [[ "$run_status" != "completed" ]]; then
      echo "Workflow run started: $run_url"
      if ! gh run view "$run_url" --web; then
        echo "Error: Failed to open workflow run in browser."
      fi
      return 0
    fi

    echo "Retry attempt $attempt of 5..."
  done

  echo "Workflow run did not start after 5 attempts."
  return 1
}
