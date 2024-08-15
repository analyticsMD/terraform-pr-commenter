##################
# Shared Variables
##################
parse_args () {
  # Arg 1 is command
  COMMAND=$1
  debug "COMMAND: $COMMAND"

  # Arg 3 is the Terraform CLI exit code
  EXIT_CODE=$2
  debug "EXIT_CODE: $EXIT_CODE"

  # Arg 2 is input file. We strip ANSI colours.
  RAW_INPUT="$COMMENTER_INPUT"
  debug "COMMENTER_INPUT: $COMMENTER_INPUT"

  if [[ $COMMAND == 'plan' ]]; then
    if test -f "workspace/${COMMENTER_PLAN_FILE}"; then
      info "Found commenter plan file."
      cd workspace || (error "Failed to change to workspace dir" && exit 1)
      info "Current working directory: $(pwd)"
      info "Current files in directory: $(ls)"
      sed -i '1d' tf_plan.txt
      cat ${COMMENTER_PLAN_FILE}
      # pushd workspace > /dev/null || (error "Failed to push workspace dir" && exit 1)
      #RAW_INPUT="$( cat "${COMMENTER_PLAN_FILE}" 2>&1 )"
      RAW_INPUT=$(<"${COMMENTER_PLAN_FILE}")
      info 
      cd - || (error "Failed to return to previous dir" && exit 1)
    else
      info "Found no tfplan file. Using input argument."
    fi
  else
    info "Not terraform plan. Using input argument."
  fi

  # change diff character, a red '-', into a high unicode character \U1f605 (literally 😅)
  # if not preceded by a literal "/" as in "+/-".
  # this serves as an intermediate representation representing "diff removal line" as distinct from
  # a raw hyphen which could *also* indicate a yaml list entry.
  INPUT=$(echo "$RAW_INPUT" | perl -pe "s/(?<!\/)\e\[31m-\e\[0m/😅/g")

  # now remove all ANSI colors
  INPUT=$(echo "$INPUT" | sed -r 's/\x1b\[[0-9;]*m//g')

  # remove terraform debug lines
  INPUT=$(echo "$INPUT" | sed '/^::debug::Terraform exited with code/,$d')

  # Get the last line, which is the overview of the plan
  OVERVIEW=$(echo "$INPUT" | grep -o 'Plan:.*')

  # shellcheck disable=SC2034
  WARNING=$(echo "$INPUT" | grep "│ Warning: " -q && echo "TRUE" || echo "FALSE")

  # Read TF_WORKSPACE environment variable or use "default"
  # shellcheck disable=SC2034
  WORKSPACE=${TF_WORKSPACE:-default}
  
  # Read TF_COMPONENT environment variable or use "default"
  # shellcheck disable=SC2034
  COMPONENT=${TF_COMPONENT:-default}

  # Read EXPAND_SUMMARY_DETAILS environment variable or use "true"
  if [[ ${EXPAND_SUMMARY_DETAILS:-false} == "true" ]]; then
    DETAILS_STATE=" open"
  else
    # shellcheck disable=SC2034
    DETAILS_STATE=""
  fi

  # Read HIGHLIGHT_CHANGES environment variable or use "true"
  # shellcheck disable=SC2034
  COLOURISE=${HIGHLIGHT_CHANGES:-true}

  # Read COMMENTER_POST_PLAN_OUTPUTS environment variable or use "true"
  # shellcheck disable=SC2034
  POST_PLAN_OUTPUTS=${COMMENTER_POST_PLAN_OUTPUTS:-true}

  # shellcheck disable=SC2034
  ACCEPT_HEADER="Accept: application/vnd.github+json"
  # shellcheck disable=SC2034
  AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
  # shellcheck disable=SC2034
  CONTENT_HEADER="X-GitHub-Api-Version: 2022-11-28"

# PR_COMMENTS_URL=$(echo "$GITHUB_EVENT" | jq -r ".pull_request.comments_url")
  # PR_COMMENTS_URL=$(echo "$GITHUB_EVENT" | jq -r ".issue.comments_url")
  # PR_COMMENTS_URL+="?per_page=100"

  # Extract event type
  EVENT_TYPE=$(echo "$GITHUB_EVENT" | jq -r ".action")

  # Determine comments URL based on event type
  if [[ $EVENT_TYPE == "created" ]]; then
    PR_COMMENTS_URL=$(echo "$GITHUB_EVENT" | jq -r ".issue.comments_url")
  else
    PR_COMMENTS_URL=$(echo "$GITHUB_EVENT" | jq -r ".pull_request.comments_url")
  fi

  # Use the determined comments URL
  echo "Using comments URL: $PR_COMMENTS_URL"

  # shellcheck disable=SC2034
  PR_COMMENT_URI=$(echo "$GITHUB_EVENT" | jq -r ".repository.issue_comment_url" | sed "s|{/number}||g")
}