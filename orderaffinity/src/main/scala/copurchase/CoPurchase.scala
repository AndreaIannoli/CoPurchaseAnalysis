package copurchase

import org.apache.spark.{HashPartitioner, SparkConf, SparkContext}

object CoPurchase {
  def main(args: Array[String]): Unit = {
    // Usage:
    //   spark-submit --class copurchase.RddCoPurchaseAnalysis your-jar.jar <inputPath> <outputPath>
    //
    // args(0) = input path (CSV)
    // args(1) = output path (folder for CSV output)

    // val inputPath  = args(0)
    // val outputPath = args(1)

    // Configure Spark: set parallelism, use Kryo serializer, etc.
    val conf = new SparkConf()
      .setAppName("CoPurchase")
      .set("spark.default.parallelism", "400")
      // Use Kryo serializer (slightly more efficient than Java serialization)
      .set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
      // Optionally register classes with Kryo if needed
      // .registerKryoClasses(Array(classOf[(Int, Int)], classOf[(Int, Iterable[Int])]))

    val sc = new SparkContext(conf)

    val number_of_executors = sc.getConf.get("spark.executor.instances").toInt;
    val number_of_cores = java.lang.Runtime.getRuntime.availableProcessors();
    val bucket_name = "bucket_copurchase"
    val inputPath = "gs://" + bucket_name + "/order_products.csv"
    val outputPath = "gs://" + bucket_name + "/output" + number_of_executors.toString();

    // Measure start time
    val startTime = System.currentTimeMillis()

    // Read input CSV as RDD of strings
    val lines = sc.textFile(inputPath)

    // Parse each line => (order_id, product_id)
    //    If your CSV has a header, filter it out here.
    val orderProductPairs = lines.map { line =>
      val Array(orderIdStr, productIdStr) = line.split(",")
      (orderIdStr.toInt, productIdStr.toInt)
    }

    // Group by order_id => (order_id, Iterable(product_id))
    val groupedByOrder = orderProductPairs.groupByKey()
    // e.g., (1, [12,14]), (2, [8,12,14]), etc.

    //  For each order, generate unique product pairs. (p1 < p2) enforced by if-else.
    //  This avoids sorting each order's product list.
    val pairRDD = groupedByOrder.flatMap { case (_, products) =>
      // Convert to a set to remove duplicates, then to a list
      val productList = products.toList
      val pairs = for {
        i <- productList.indices
        j <- (i + 1) until productList.size
      } yield {
        val x = productList(i)
        val y = productList(j)
        // Ensure (p1, p2) always has p1 < p2 (numeric order)
        val (p1, p2) = if (x < y) (x, y) else (y, x)
        ((p1, p2), 1)
      }
      pairs
    }
    // Optionally, re-partition before the reduce step
    // val partitionedPairs = pairRDD.partitionBy(new HashPartitioner(number_of_executors * number_of_cores.toInt * 2));
    val partitionedPairs = pairRDD.partitionBy(new HashPartitioner(number_of_cores * number_of_executors * 3));

    // Sum up how many orders each pair appears in
    val coOccurrenceCounts = partitionedPairs.reduceByKey(_ + _)

    // Convert each pair-count to CSV line => "p1,p2,count"
    val outputLines = coOccurrenceCounts.map { case ((p1, p2), count) =>
      s"$p1,$p2,$count"
    }

    // Write results to the specified output path (CSV)
    outputLines.saveAsTextFile(outputPath)

    // Measure end time in seconds
    val endTime = System.currentTimeMillis()
    val elapsedSeconds = (endTime - startTime) / 1000.0
    println(s"Elapsed time: $elapsedSeconds s")

    sc.stop()
  }
}
