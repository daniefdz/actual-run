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
SERVER_VERSION=25.10.0
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

## 🔁 Update Actual Budget

A new version of Actual Budget is released monthly, typically during the first week of each month. However, the *actual-server* service that you deployed in this guide doesn't update to new versions automatically. To use a new version of Actual Budget, you must manually deploy a new image in Cloud Run.

⚠️ **Note:** This update process assumes that you successfully deployed the service using the instructions in this guide. If you used another method or deviated from the instructions (e.g. renamed components or added different access controls) the process to update your service might differ.

### ➡️ Update using Cloud Shell

To update Actual Budget using Cloud Shell, do the following:

1. Open [Cloud Shell](https://shell.cloud.google.com/).
2. Run the following command:
```
gcloud run deploy <AB_SERVICE> --image <IMAGE_URL>
```
  - Replace <AB_SERVICE> with the name of your Actual Budget service. If you followed the instructions in this guide, the service name should be *actual-server*.
  - Replace <IMAGE_URL> with the relative URL for the Actual Budget version you want to deploy (for example, actualbudget/actual-server:25.10.0). You can see the latest versions [here](https://github.com/actualbudget/actual/releases).

✅ The update process might take a minute. If deployed successfully, a success message is displayed and the URL for the deployed service is returned.

### ➡️ Update using the Google Cloud console

To update Actual Budget using the Google Cloud console, do the following:

1. Open [Cloud Run](https://console.cloud.google.com/run) in the Google Cloud console.
2. If needed, use the project selector at the top of the page to select the project that contains your Actual Budget service.
3. Under **Services**, click *actual-server*.
4. On the **Service details** page, click **Edit and deploy a new revision**.
5. Under **Containers**, make the following changes:
  - The **Container image url** field shows the relative URL for the deployed image. It is appended with the current version number (e.g. actualbudget/actual-server:25.3.1). In this example, the version number is 25.3.1. Change the version number to the latest version of Actual Budget or whichever version you want to deploy. (e.g. actualbudget/actual-server:25.10.0). You can see the latest versions [here](https://github.com/actualbudget/actual/releases).
  - By default, new revisions automatically receive 100% of the traffic. However, if needed, select the checkbox next to **Serve this revision immediately**.
6. You can leave all other options unchanged.
7. Click **Deploy**.

✅ The update process might take a minute. When completed, you should see a new revision under **Revisions** on the **Service details** page. It should contain the automatically assigned revision name and current date, and indicate that 100% of traffic is going to it.
