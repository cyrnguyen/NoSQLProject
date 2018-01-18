package com.sparkProject

import org.apache.spark.SparkConf
import org.apache.spark.sql._
import org.apache.spark.sql.functions._

import java.io.{BufferedReader, InputStreamReader}
import java.sql.Timestamp
import java.util.zip.ZipInputStream
import org.apache.spark.input.PortableDataStream
import com.mongodb.spark._
import com.mongodb.spark.config._
import org.bson.Document

object LoadMentions {

  def main(args: Array[String]): Unit = {

    var inputFileDateFormat = "*"
    if (args.length > 0)
      inputFileDateFormat = args(0)

    var schema = "year"
    if (args.length > 1)
      schema = args(1)
    val mongoOutputUri = "mongodb://ip-172-31-8-31.ec2.internal/" + schema + ".test2"

    val conf = new SparkConf().setAll(Map(
      "spark.scheduler.mode" -> "FIFO",
      "spark.speculation" -> "false",
      "spark.reducer.maxSizeInFlight" -> "48m",
      "spark.serializer" -> "org.apache.spark.serializer.KryoSerializer",
      "spark.kryoserializer.buffer.max" -> "1g",
      "spark.shuffle.file.buffer" -> "32k",
      "spark.mongodb.output.uri" -> mongoOutputUri
    ))

    val spark = SparkSession
      .builder
      .config(conf)
      .appName("Data_import")
      .getOrCreate()

    import spark.implicits._

    spark.sparkContext.hadoopConfiguration.set("fs.s3a.access.key", "AKIAJJTGBQ7SKKM2B7SQ") // mettre votre ID du fichier credentials.csv
    spark.sparkContext.hadoopConfiguration.set("fs.s3a.secret.key", "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") // mettre votre secret du fichier credentials.csv
    spark.sparkContext.hadoopConfiguration.setInt("fs.s3a.connection.maximum", 50000)

    val mediadf = spark.read.format("csv").option("header", true).
      load("s3a://gdelt-sources/media.csv").
      withColumnRenamed("mentionsourcename", "sourceName")

    val zipRDD = spark.sparkContext.binaryFiles("s3a://gdelt-sources/" + inputFileDateFormat + ".mentions.CSV.zip")
    // val zipRDD = spark.sparkContext.binaryFiles("file:///home/cyril/Data/INF728/Projet/20170108053000.mentions.CSV.zip")

    val textRDD = zipRDD.flatMap {
      case (name: String, content: PortableDataStream) =>
        val zis = new ZipInputStream(content.open)
        Stream.continually(zis.getNextEntry)
          .takeWhile(_ != null)
          .flatMap { _ =>
            val br = new BufferedReader(new InputStreamReader(zis))
            Stream.continually(br.readLine()).takeWhile(_ != null)
          }
    }

    val df = textRDD.map(line => line.split("\t")).toDF.
      withColumn("GlobalEventID", col("value").getItem(0)).
      withColumn("MentionTimeDate", col("value").getItem(2)).
      withColumn("MentionType", col("value").getItem(3).cast("Int")).
      withColumn("MentionSourceName", col("value").getItem(4)).
      withColumn("MentionIdentifier", col("value").getItem(5)).
      withColumn("MentionDocTone", col("value").getItem(13).cast("Int")).
      drop("value").
      filter(col("MentionType") === 1).
      withColumn("MentionDate", to_timestamp(substring(col("MentionTimeDate"), 0, 8), "yyyyMMdd")).
      drop("MentionTimeDate", "MentionType").
      join(mediadf, col("MentionSourceName") === mediadf("sourceName")).
      drop("MentionSourceName", "sourceName", "CountryHumanName").
      withColumnRenamed("FIPSCountryCode", "CountryCode")

    MongoSpark.save(df.write.option("collection", "mentions").mode("append"))

  }
}
