
# Co-purchase Analysis with Scala and Apache Spark

## Project Description

This project implements a co-purchase analysis using Scala and Apache Spark. The goal is to compute the number of orders in which two products appear together, providing valuable insights for recommendation systems. The analysis is performed on a dataset representing orders from a grocery delivery app.

## Dataset

The provided dataset is in CSV format and contains records in the following form:

```
order_id, product_id
```

### Example Dataset:
```
1,12
1,14
2,8
2,12
2,14
3,8
3,12
3,14
3,16
```

### Output of the Analysis:
The output is a CSV file containing rows in the format:
```
product_x, product_y, order_count
```

For example:
```
8,12,2
8,14,2
12,14,3
```

## Implementation

The data processing is implemented using the **map-reduce** approach and executed in a distributed environment using Apache Spark on Google Cloud DataProc.

### Key Features:
- Reading the dataset from Google Cloud Storage.
- Distributed data processing to calculate co-occurrence.
- Saving results back to Google Cloud Storage.

## Requirements

- **Scala** (2.12.20)
- **Apache Spark** (3.5.4)
- **Google Cloud SDK** (with `gcloud` configured)
- **Google Cloud Platform** (GCP)

## Execution Instructions

1. **Prepare the Environment**
   - Configure Google Cloud SDK with the command:
     ```bash
     gcloud auth login
     gcloud config set project [PROJECT_ID]
     ```
   - Create a bucket on Google Cloud Storage for the dataset and output:
     ```bash
     gsutil mb -l [REGION] gs://[BUCKET_NAME]/
     ```

2. **Upload the Dataset**
   - Upload the CSV file to the bucket:
     ```bash
     gsutil cp dataset.csv gs://[BUCKET_NAME]/
     ```

3. **Create a DataProc Cluster**
   - Start a cluster with the following command:
     ```bash
     gcloud dataproc clusters create [CLUSTER_NAME]        --region=[REGION] --num-workers=[N_WORKERS]        --master-boot-disk-size=240GB --worker-boot-disk-size=240GB
     ```

4. **Build the Project**
   - Generate a JAR file for the project:
     ```bash
     sbt package
     ```

5. **Run the Job on DataProc**
   - Upload the JAR file to the bucket:
     ```bash
     gsutil cp target/scala-2.12/scala_2.12-0.1.0-SNAPSHOT.jar gs://[BUCKET_NAME]/
     ```
   - Submit the job:
     ```bash
     gcloud dataproc jobs submit spark --cluster=[CLUSTER_NAME]        --region=[REGION] --jar=gs://[BUCKET_NAME]/scala_2.12-0.1.0-SNAPSHOT.jar         -- [BUCKET_INPUT_PATH] [BUCKET_OUTPUT_PATH]
     ```

6. **Retrieve the Results**
   - Download the output from the bucket:
     ```bash
     gsutil cp gs://[BUCKET_NAME]/output/part-* ./output/
     ```

