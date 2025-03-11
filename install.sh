#!/bin/bash

# Set the default values for the project, bucket, region and the server version to be installed
GCP_REGION=us-central1
SERVER_VERSION=25.3.1
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME=actual-server-$(openssl rand -hex 4)

# Create a bucket to store the server data
gcloud storage buckets create gs://$BUCKET_NAME \
--location=$GCP_REGION \
--project=$PROJECT_ID

# Create a service account for the server running in cloud run
gcloud iam service-accounts create actual-server-sa \
--display-name="Actual Server Service Account" \
--project=$PROJECT_ID

# Some delay to let the service account be created
sleep 2

# Grant access to the bucket for the service account
gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
--member=serviceAccount:actual-server-sa@$PROJECT_ID.iam.gserviceaccount.com \
--role=roles/storage.objectAdmin

# Deploy the server to cloud run
gcloud run deploy actual-server \
--image=actualbudget/actual-server:$SERVER_VERSION \
--allow-unauthenticated \
--port=5006 \
--service-account=actual-server-sa@$PROJECT_ID.iam.gserviceaccount.com \
--max-instances=1 \
--add-volume name=gcs-1,type=cloud-storage,bucket=$BUCKET_NAME \
--add-volume-mount volume=gcs-1,mount-path=/data \
--region=$GCP_REGION \
--project=$PROJECT_ID