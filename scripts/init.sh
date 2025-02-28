#!/usr/bin/env bash
set -euo pipefail

# Function to create a bucket in a specified location
create_bucket() {
  local bucket_name=$1
  local location=${2:-EU}
  echo "Creating bucket '$bucket_name' in location '$location'..."
  gsutil mb -l "$location" gs://"$bucket_name"
  echo "Bucket '$bucket_name' created in '$location'."
}

# Function to upload a single file to a bucket
upload_file() {
  local bucket_name=$1
  local source_file_path=$2
  local destination_blob_name=$3
  echo "Uploading file '$source_file_path' to gs://$bucket_name/$destination_blob_name..."
  gsutil cp "$source_file_path" gs://"$bucket_name"/"$destination_blob_name"
  echo "File '$source_file_path' uploaded as '$destination_blob_name'."
}

# Create the bucket
create_bucket "bucket_copurchase" "EU"

# Upload files to the bucket
upload_file "bucket_copurchase" "../orderaffinity/src/order_products_short.csv" "order_products.csv"
upload_file "bucket_copurchase" "../orderaffinity/src/order_products_short.csv" "../orderaffinity/target/scala-2.12/orderaffinity_2.12-0.1.0.jar"

echo "Bucket creation and file uploads completed."
