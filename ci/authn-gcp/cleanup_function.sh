#!/bin/bash

# Script that runs inside a Google SDK container and deploys a function
# That fetches an id token with audience claim passed in the request query string

echo "-- delete function: $GCF_FUNC_NAME in project: $GCP_PROJECT"

function delete_function() {
  validate_pre_requisites

  # Set the project for the following commands
  gcloud config set project "$GCP_PROJECT"

  # Authenticate using the service account key file
  gcloud auth activate-service-account --key-file "$GCP_OWNER_SERVICE_KEY"
  local func_exists="gcloud functions list --format='value(name)' --filter='name ~ $GCF_FUNC_NAME'"
  if [ -n "$func_exists" ]; then
    # Delete the function
    gcloud functions delete "$GCF_FUNC_NAME" --quiet
  fi
}

function validate_pre_requisites() {
  if [ -z "$GCP_PROJECT" ]; then
    echo "ERROR: function cannot be deleted, GCP project name is undefined."
    exit 1
  fi

  if [ -z "$GCF_FUNC_NAME" ]; then
    echo "ERROR: function cannot be deleted, function name is undefined."
    exit 1
  fi

  if [ ! -f "$GCP_OWNER_SERVICE_KEY" ]; then
    echo "ERROR: function cannot be deleted, service account key file not found."
    exit 1
  fi
}

delete_function