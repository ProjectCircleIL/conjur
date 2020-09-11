#!/bin/bash

# Script that runs inside a Google SDK container and deploys a function
# That fetches an id token with audience claim passed in the request query string

echo "-- deploy function: $GCF_FUNC_NAME in project: $GCP_PROJECT"
WORK_DIR=$HOME
GCF_SOURCE_DIR="$WORK_DIR/function"
GCF_SOURCE_FILE="$GCF_SOURCE_DIR/main.py"

function deploy_function() {
  validate_pre_requisites

  # Replace the function name with a unique function name in the source code file
  sed -i "s/func_name/$GCF_FUNC_NAME/" "$GCF_SOURCE_FILE"

  cat "$GCF_SOURCE_FILE"

  # Set the project for the following commands
  gcloud config set project "$GCP_PROJECT"

  # Authenticate using the service account key file
  gcloud auth activate-service-account --key-file "$GCP_OWNER_SERVICE_KEY"

  # Change dir to function source file
  cd "$GCF_SOURCE_DIR" || exit 1

  # Deploy the function
  gcloud functions deploy "$GCF_FUNC_NAME" \
  --runtime python37 \
  --trigger-http
}

function validate_pre_requisites() {
  if [ -z "$GCP_PROJECT" ]; then
    echo "ERROR: function cannot be deployed, GCP project name is undefined."
    exit 1
  fi

  if [ -z "$GCF_FUNC_NAME" ]; then
    echo "ERROR: function cannot be deployed, function name is undefined."
    exit 1
  fi

  if [ ! -d "$GCF_SOURCE_DIR" ]; then
    echo "ERROR: function cannot be deployed, function directory not found, expected '$GCF_SOURCE_FILE'."
    exit 1
  fi

  if [ ! -f "$GCF_SOURCE_FILE" ]; then
    echo "ERROR: function cannot be deployed, function file not found, expected '$GCF_SOURCE_FILE'."
    exit 1
  fi

  if [ ! -f "$GCP_OWNER_SERVICE_KEY" ]; then
    echo "ERROR: function cannot be deployed, service account key file not found."
    exit 1
  fi
}

deploy_function