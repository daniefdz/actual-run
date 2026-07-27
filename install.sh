#!/bin/bash

# Set the default values for the project, bucket, region and the server version to be installed
GCP_REGION=us-central1
SERVER_VERSION=26.3.0
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME=actual-server-$(openssl rand -hex 4)

# Create a bucket to store the server data
# Uniform bucket-level access makes IAM the only way in, by disabling per-object
# ACLs. Public access prevention makes it impossible to grant the bucket to
# allUsers, even by mistake. Neither affects the service account below.
gcloud storage buckets create gs://$BUCKET_NAME \
--location=$GCP_REGION \
--uniform-bucket-level-access \
--public-access-prevention \
--project=$PROJECT_ID

# Create a service account for the server running in cloud run
gcloud iam service-accounts create actual-server-sa \
--display-name="Actual Server Service Account" \
--project=$PROJECT_ID

# Grant access to the bucket for the service account
# A newly created service account is not usable right away. IAM can still
# reject the binding with "Service account ... does not exist", so retry rather
# than rely on a fixed delay, which cannot be tuned reliably.
echo "Granting bucket access to the service account..."
for attempt in $(seq 1 12); do
  gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
    --member=serviceAccount:actual-server-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --role=roles/storage.objectAdmin >/dev/null 2>&1 && break

  if [ "$attempt" -eq 12 ]; then
    echo "Error: could not grant bucket access after 2 minutes." >&2
    exit 1
  fi
  sleep 10
done

# Deploy the server to cloud run
# Even once the binding exists, the metadata server can still fail to mint a
# token for the new service account. That shows up as a gcsfuse mount failure
# ("cannot fetch token: ... Received 500") and the revision never starts.
# Deploying again is safe: a revision that fails to start receives no traffic.
deploy_server() {
  gcloud run deploy actual-server \
    --image=actualbudget/actual-server:$SERVER_VERSION \
    --allow-unauthenticated \
    --port=5006 \
    --service-account=actual-server-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --max-instances=1 \
    --execution-environment=gen2 \
    --add-volume name=gcs-1,type=cloud-storage,bucket=$BUCKET_NAME \
    --add-volume-mount volume=gcs-1,mount-path=/data \
    --region=$GCP_REGION \
    --project=$PROJECT_ID
}

for attempt in 1 2 3; do
  deploy_server && break

  if [ "$attempt" -eq 3 ]; then
    echo "Error: the deployment failed three times." >&2
    exit 1
  fi
  echo "Deployment failed. This is usually IAM propagation, retrying in 60s..."
  sleep 60
done
