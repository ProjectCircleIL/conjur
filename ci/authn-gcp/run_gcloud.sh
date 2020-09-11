#!/bin/bash -ex

# Script that runs a Google SDK container executes a script that deploys
# a function to fetch an id token with `audience` claim passed in as \
# a parameter to the request querystring

GCLOUD_SCRIPT=$1

if [ -z "$GCLOUD_SCRIPT" ]; then
  echo "-- Missing script file name argument"
  exit 1
fi

echo "-- Run script: '$GCLOUD_SCRIPT' on gcloud container"
GCP_OWNER_SERVICE_KEY_FILE="sa-key-file.json"

echo "-- Write service key to: '$GCP_OWNER_SERVICE_KEY_FILE'"
echo "$GCP_OWNER_SERVICE_KEY" > "$GCP_OWNER_SERVICE_KEY_FILE"

LOCAL_VOLUME="$(pwd)"
CONTAINER_VOLUME="/root"
GOOGLE_SDK_IMAGE=gcr.io/google.com/cloudsdktool/cloud-sdk:slim
CMD=".$CONTAINER_VOLUME/$GCLOUD_SCRIPT"

docker run \
-e GCF_FUNC_NAME="$GCP_FETCH_TOKEN_FUNCTION" \
-e GCP_PROJECT="$GCP_PROJECT" \
-e GCP_OWNER_SERVICE_KEY="$CONTAINER_VOLUME/$GCP_OWNER_SERVICE_KEY_FILE" \
-v /var/run/docker.sock:/var/run/docker.sock \
--rm -i -v "$LOCAL_VOLUME":"$CONTAINER_VOLUME" "$GOOGLE_SDK_IMAGE" "$CMD"

echo "-- Delete service key file: '$GCP_OWNER_SERVICE_KEY_FILE'"
rm -f echo "$GCP_OWNER_SERVICE_KEY_FILE" || echo "ERROR failed to delete service account file: $GCP_OWNER_SERVICE_KEY_FILE"
