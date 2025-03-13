#!/usr/bin/env bash
set -euo pipefail

# Variables
CLUSTER_NAME="cluster-copurchase"
REGION="europe-west1"
JAR_PATH="gs://bucket_copurchase/orderaffinity_2.12-0.1.0.jar"

# ----------------------------- RUN WITH A SINGLE NODE -----------------------------

# Create a single-node cluster
echo "Creating single-node cluster: ${CLUSTER_NAME}..."
gcloud dataproc clusters create "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --zone "europe-west1-b" \
  --single-node \
  --master-boot-disk-size "340" \
  --master-machine-type "n2-standard-4"

# Submit the Spark job on the single-node cluster
echo "Submitting Spark job on cluster: ${CLUSTER_NAME}..."
gcloud dataproc jobs submit spark \
  --cluster "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --jar "${JAR_PATH}" \
  --properties=spark.driver.memory=6g,spark.executor.memory=4g,spark.executor.instances=1,spark.executor.cores=2

# ----------------------------- RUN WITH TWO WORKER NODES -----------------------------

# Delete the previous cluster
echo "Deleting cluster: ${CLUSTER_NAME}..."
gcloud dataproc clusters delete "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --quiet

# Define the number of workers and new cluster name
NUM_WORKERS=2
NEW_CLUSTER_NAME="${CLUSTER_NAME}-${NUM_WORKERS}"

# Create a new cluster with 2 worker nodes
echo "Creating new cluster: ${NEW_CLUSTER_NAME} with ${NUM_WORKERS} worker nodes..."
gcloud dataproc clusters create "${NEW_CLUSTER_NAME}" \
  --region "${REGION}" \
  --zone "europe-west1-b" \
  --num-workers "${NUM_WORKERS}" \
  --master-boot-disk-size "100" \
  --worker-boot-disk-size "100" \
  --master-machine-type "n2-standard-4" \
  --worker-machine-type "n2-standard-2"

# Submit the Spark job on the cluster with 2 workers
echo "Submitting Spark job on cluster: ${NEW_CLUSTER_NAME}..."
gcloud dataproc jobs submit spark \
  --cluster "${NEW_CLUSTER_NAME}" \
  --region "${REGION}" \
  --jar "${JAR_PATH}" \
  --properties=spark.driver.memory=4g,spark.executor.memory=4g,spark.executor.instances=2,spark.executor.cores=2
  


# ----------------------------- RUN WITH THREE WORKER NODES -----------------------------

# Update the existing cluster to increase the number of workers to 3
NEW_NUM_WORKERS=3
echo "Updating cluster ${NEW_CLUSTER_NAME}: increasing workers to ${NEW_NUM_WORKERS}..."
gcloud dataproc clusters update "${NEW_CLUSTER_NAME}" \
  --region "${REGION}" \
  --num-workers "${NEW_NUM_WORKERS}"

# Submit the Spark job on the updated cluster
echo "Submitting Spark job on updated cluster: ${NEW_CLUSTER_NAME}..."
gcloud dataproc jobs submit spark \
  --cluster "${NEW_CLUSTER_NAME}" \
  --region "${REGION}" \
  --jar "${JAR_PATH}" \
  --properties=spark.driver.memory=4g,spark.executor.memory=4g,spark.executor.instances=3,spark.executor.cores=2
