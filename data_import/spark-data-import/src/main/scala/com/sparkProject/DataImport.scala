
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

object DataImport {

  def main(args: Array[String]): Unit = {

    val conf = new SparkConf().setAll(Map(
      "spark.scheduler.mode" -> "FIFO",
      "spark.speculation" -> "false",
      "spark.reducer.maxSizeInFlight" -> "48m",
      "spark.serializer" -> "org.apache.spark.serializer.KryoSerializer",
      "spark.kryoserializer.buffer.max" -> "1g",
      "spark.shuffle.file.buffer" -> "32k",
      "spark.mongodb.output.uri" -> "mongodb://ip-172-31-8-31.ec2.internal/test_CNG.test2"
    ))

    val spark = SparkSession
      .builder
      .config(conf)
      .appName("Data_import")
      .getOrCreate()

    import spark.implicits._

    spark.sparkContext.hadoopConfiguration.set("fs.s3a.access.key", "AKIAJJTGBQ7SKKM2B7SQ") // mettre votre ID du fichier credentials.csv
    spark.sparkContext.hadoopConfiguration.set("fs.s3a.secret.key", "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") // mettre votre secret du fichier credentials.csv
    spark.sparkContext.hadoopConfiguration.setInt("fs.s3a.connection.maximum", 500)

    val zipRDD = spark.sparkContext.binaryFiles("s3a://gdelt-sources/201701*.export.CSV.zip")

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

    textRDD.count()

    val df = textRDD.map(line => line.split("\t")).toDF.
      withColumn("GlobalEventID", col("value").getItem(0)).
      withColumn("Actor1Code", col("value").getItem(5)).
      withColumn("Actor1Name", col("value").getItem(6)).
      withColumn("Day", col("value").getItem(1)).
      withColumn("Actor2Code", col("value").getItem(15)).
      withColumn("Actor2CountryCode", col("value").getItem(17)).
      drop("value")

    MongoSpark.save(df.write.option("collection", "test3").mode("append"))

  }

}