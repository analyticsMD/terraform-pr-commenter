validate_inputs () {

  if [[ -z "$GITHUB_TOKEN" ]]; then
    error "GITHUB_TOKEN environment variable missing."
    exit 1
  fi

  if [[ -z $2 ]]; then
      error "There must be an exit code from a previous step."
      exit 1
  fi

  if [[ ! "$1" =~ ^(fmt|init|plan|validate|tflint|apply)$ ]]; then
    error "Unsupported command \"$1\". Valid commands are \"fmt\", \"init\", \"plan\", \"validate\", \"tflint\", \"apply\"."
    exit 1
  fi
}
