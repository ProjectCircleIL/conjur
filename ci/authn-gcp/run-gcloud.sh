#!/bin/bash

# Script that runs a Google SDK container executes a script that deploys
# a function to fetch an id token with `audience` claim passed in as \
# a parameter to the request querystring

echo "-- run gcloud container deploy function script"
FUNC_NAME="fetch_token_${BUILD_NUMBER}"

# TODO EXTRACT PROJECT NAME
GCP_PROJECT=refreshing-mark-284016
LOCAL_VOLUME="$(pwd)"
CONTAINER_VOLUME=/root
DEPLOY_FUNC_SCRIPT=deploy_function.sh
GOOGLE_SDK_IMAGE=gcr.io/google.com/cloudsdktool/cloud-sdk:slim
CMD="bash $CONTAINER_VOLUME/$DEPLOY_FUNC_SCRIPT"

docker run \
-e GCF_NAME="$GCP_FETCH_TOKEN_FUNCTION" \
-e GCP_PROJECT="$GCP_PROJECT" \
-e GCP_OWNER_SERVICE_KEY="$GCP_OWNER_SERVICE_KEY" \
--rm -ti -v "$LOCAL_VOLUME":"$CONTAINER_VOLUME" "$GOOGLE_SDK_IMAGE" "$CMD"
