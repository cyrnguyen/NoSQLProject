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

object LoadOpinions {

  def main(args: Array[String]): Unit = {

    var schema = "ec2-34-237-124-41"
    if (args.length > 0)
      schema = args(0)
    val mongoInputUri = "mongodb://"+schema+".compute-1.amazonaws.com/endofyear.events?readPreference=primaryPreferred"
    val mongoOutputUri = "mongodb://"+schema+".compute-1.amazonaws.com/endofyear.opinions"

    val conf = new SparkConf().setAll(Map(
      "spark.scheduler.mode" -> "FIFO",
      "spark.speculation" -> "false",
      "spark.reducer.maxSizeInFlight" -> "48m",
      "spark.serializer" -> "org.apache.spark.serializer.KryoSerializer",
      "spark.kryoserializer.buffer.max" -> "1g",
      "spark.shuffle.file.buffer" -> "32k",
      "spark.mongodb.input.uri" -> mongoInputUri
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

    val events = MongoSpark.load(spark)
    val mentions = spark.sparkContext
      .loadFromMongoDB(ReadConfig(Map("uri"->"mongodb://"+schema+".compute-1.amazonaws.com/endofyear.mentions?readPreference=primaryPreferred")))
      .toDF()

    val mentions_events = mentions.join(events, Seq("GlobalEventID"))

    val opinions = mentions_events
      .groupBy($"MentionDate".alias("day"),$"CountryCode".alias("country"))
      .agg(count(lit(1)).alias("Num_Mentions"),avg("MentionDocTone").alias("AvgTone"))

    MongoSpark.save(opinions.write.option("endofyear", "opinions").mode("append"))

  }

}
