#!/usr/bin/env bash
set -euo pipefail

delete_all_buckets() {
  # Get list of all bucket URLs (e.g. gs://bucket-name/)
  buckets=$(gsutil ls)
  
  if [[ -z "$buckets" ]]; then
    echo "No bucket found."
    return
  fi

  for bucket in $buckets; do
    echo "Deleting the bucket: $bucket"
    
    # Delete all objects (and any subdirectories) in the bucket.
    # The pattern "${bucket}**" recursively matches all objects.
    if gsutil -m rm -r "${bucket}**"; then
      echo "All the objects in $bucket have been deleted."
    else
      echo "Errore while deleting objects in $bucket."
      continue
    fi

    # Remove the (now empty) bucket.
    if gsutil rb "$bucket"; then
      echo "Bucket $bucket successfuly deleted."
    else
      echo "Error while trying to delete bucket: $bucket."
    fi
  done
}

delete_all_buckets
