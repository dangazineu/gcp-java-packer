# gcp-java-packer
Cloud Build project using Packer.io to build a VM with Temurin JDK

## Before you start
All these steps were executed on a brand new project without any previous setup:

### Cloud Build Setup
_Copied from [Cloud Build documentation](https://cloud.google.com/build/docs/building/build-vm-images-with-packer)_
```shell

export PROJECT_ID={YOUR_PROJECT_ID}

# Enable the following APIs:
gcloud services enable sourcerepo.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable servicemanagement.googleapis.com
gcloud services enable storage-api.googleapis.com

# not in the documentation, but is required in order for the packer service account to work
gcloud services enable iamcredentials.googleapis.com

# not in the documentation, but required for cloud build
gcloud services enable cloudbuild.googleapis.com

CLOUD_BUILD_ACCOUNT=$(gcloud projects get-iam-policy $PROJECT_ID --filter="(bindings.role:roles/cloudbuild.builds.builder)"  --flatten="bindings[].members" --format="value(bindings.members[])")

# Add the Compute Engine Instance Admin role to the service account:
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member $CLOUD_BUILD_ACCOUNT \
  --role roles/compute.instanceAdmin
```

### Packer Setup
I couldn't find a way around this manual step yet. In order to use Packer to 
build a __VM Image__, we need a packer __Container Image__ in gcr.io.

```shell
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/packer
gcloud builds submit .

# This builds and publishes a container image that can execute Packer commands. 
# You can delete the checked out repo now.
cd ../..
rm -rf cloud-builders-community/
```

### Packer Service Account Setup
This is probably not required, but recommended. Copied from the [packer builder documentation](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/packer/examples/gce)
```shell


# Create Service Account for Packer

gcloud iam service-accounts create packer --description "Packer image builder"

# Grant roles to Packer's Service Account

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/compute.instanceAdmin.v1" \
  --member="serviceAccount:packer@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/iam.serviceAccountUser" \
  --member="serviceAccount:packer@${PROJECT_ID}.iam.gserviceaccount.com"

# Allow CloudBuild to impersonate Packer service account

gcloud iam service-accounts add-iam-policy-binding \
  packer@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.serviceAccountTokenCreator" \
  --member=${CLOUD_BUILD_ACCOUNT}
```
## Building the image
Run the following command at the root of the project (assumes $PROJECT_ID env var exists)
```shell
gcloud builds submit --config=cloudbuild.yaml .
```