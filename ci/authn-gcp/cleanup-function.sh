#!/bin/bash

# Script that runs inside a Google SDK container and deploys a function
# That fetches an id token with audience claim passed in the request query string

echo "-- deploy function: $GCF_FUNC_NAME in project: $PROJECT"
WORK_DIR=$HOME
GCF_SOURCE_DIR="$WORK_DIR/function"
GCF_SOURCE_FILE="$GCF_SOURCE_DIR/main.py"

function delete_function() {
  validate_pre_requisites

  # Set the project for the following commands
  gcloud config set project "$GCP_PROJECT"

  # Authenticate using the service account key file
  gcloud auth activate-service-account --key-file "$GCP_OWNER_SERVICE_KEY"

  # Deploy the function
  gcloud functions delete "$GCF_NAME" --quiet
}

function validate_pre_requisites() {
  if [ -z "$GCP_PROJECT" ]; then
    echo "ERROR: function cannot be deployed, GCP project name is undefined."
    exit 1
  fi

  if [ -z "$GCF_NAME" ]; then
    echo "ERROR: function cannot be deployed, function name is undefined."
    exit 1
  fi


  if [ ! -f "$GCP_OWNER_SERVICE_KEY" ]; then
    echo "ERROR: function cannot be deployed, service account key file not found."
    exit 1
  fi
}

delete_function