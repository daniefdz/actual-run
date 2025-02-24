# Deploying Actual Budget on Google Cloud Run  

Actual Budget can be hosted as a serverless service on Google Cloud Platform (GCP), with budget data stored in a GCP Cloud Storage bucket. Cloud Run provides a secure URL with an SSL certificate for accessing the service.  

⚠️ **Note:** This deployment falls within GCP's free-tier offering, but you are responsible for any incurred charges.  

## Prerequisites  

Before proceeding, ensure you have:  

- A **GCP account** with **billing enabled**.  
- **Cloud Shell** access (recommended) or the **Google Cloud SDK** installed locally.  

---

## 🚀 Quick Installation  

Run the following command in **Cloud Shell** to install Actual Budget:  

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/daniefdz/actual-run/HEAD/install.sh)"
```  

If successful, the script will output the **Service URL** for accessing Actual Budget.  

---

## 📌 Manual Installation Steps  

### 1️⃣ Open Google Cloud Shell  

- Visit the [GCP Console](https://console.cloud.google.com/).  
- Click the **Cloud Shell** icon in the top-right corner.  
- Alternatively, go to [`https://shell.cloud.google.com/`](https://shell.cloud.google.com/).  
- Ensure the correct **GCP Project ID** is selected.  

### 2️⃣ Set Environment Variables  

Modify the following values as needed:  

```sh
GCP_REGION=us-central1
SERVER_VERSION=25.2.1
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME=actual-server-$(openssl rand -hex 4)
```
You can check the latest release version in the [Actual repo](https://github.com/actualbudget/actual/releases)

### 3️⃣ Create a Cloud Storage Bucket  

```sh
gcloud storage buckets create gs://$BUCKET_NAME \
--location=$GCP_REGION \
--project=$PROJECT_ID
```

### 4️⃣ Create a Service Account  

```sh
gcloud iam service-accounts create actual-server-sa \
--display-name="Actual Server Service Account" \
--project=$PROJECT_ID
```

### 5️⃣ Grant Storage Permissions  

```sh
gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
--member=serviceAccount:actual-server-sa@$PROJECT_ID.iam.gserviceaccount.com \
--role=roles/storage.objectAdmin
```

### 6️⃣ Deploy the Cloud Run Service  

This command deploys the Actual Budget service, making it publicly accessible while mounting the storage bucket:  

```sh
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
```

### ✅ Retrieve Your Service URL  

The final command will display the **Actual Budget instance URL**.  

To view deployment details, visit the [Cloud Run Console](https://console.cloud.google.com/run).  
