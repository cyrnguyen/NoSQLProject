
package com.sparkProject

import org.apache.spark.SparkConf
import org.apache.spark.sql._
import org.apache.spark.sql.functions._

import java.io.{BufferedReader, InputStreamReader}
import java.util.zip.ZipInputStream
import org.apache.spark.input.PortableDataStream
import com.mongodb.spark._
import com.mongodb.spark.config._
import org.bson.Document

object LoadEvents {

  def main(args: Array[String]): Unit = {

    var inputFileDateFormat = "*"
    if (args.length > 0)
      inputFileDateFormat = args(0)

    var schema = "year"
    if (args.length > 1)
      schema = args(1)

    var mongoHost = "ip-172-31-8-31.ec2.internal"
    if (args.length > 2)
      mongoHost = args(2)

    val mongoOutputUri = "mongodb://" + mongoHost + "/" + schema + ".test2"

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

    val zipRDD = spark.sparkContext.binaryFiles("s3a://gdelt-sources/" + inputFileDateFormat + ".export.CSV.zip")
    // val zipRDD = spark.sparkContext.binaryFiles("file:///home/cyril/Data/INF728/Projet/20170104181500.export.CSV.zip")

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
      withColumn("Day", to_timestamp(col("value").getItem(1), "yyyyMMdd")).
      withColumn("Actor1Code", col("value").getItem(5)).
      withColumn("Actor1Name", col("value").getItem(6)).
      withColumn("Actor1CountryCode", col("value").getItem(7)).
      withColumn("Actor1Geo_CountryCode", col("value").getItem(37)).
      withColumn("Actor2Code", col("value").getItem(15)).
      withColumn("Actor2CountryCode", col("value").getItem(17)).
      withColumn("Actor2Geo_CountryCode", col("value").getItem(45)).
      drop("value").
      filter(col("Actor1Code") === "USAGOV" || (col("Actor1Code") === "USAGOV" && col("Actor1CountryCode") === "USA"))

    MongoSpark.save(df.write.option("collection", "events").mode("append"))

  }

}