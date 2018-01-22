package com.sparkProject

import org.apache.spark.SparkConf
import org.apache.spark.sql._
import org.apache.spark.sql.functions._

import com.mongodb.spark._
import com.mongodb.spark.config._
import org.bson.Document


object ComputeOpinions {
  def main(args: Array[String]): Unit = {

    var schema = "endofyear"
    if (args.length > 0)
      schema = args(0)

    var mongoHost = "ip-172-31-8-31.ec2.internal"
    if (args.length > 1)
      mongoHost = args(1)

    val mongoInputUri = "mongodb://" + mongoHost + "/" + schema + ".events?readPreference=nearest"
    val mongoOutputUri = "mongodb://" + mongoHost + "/" + schema + ".opinions"

    val conf = new SparkConf().setAll(Map(
      "spark.scheduler.mode" -> "FIFO",
      "spark.speculation" -> "false",
      "spark.reducer.maxSizeInFlight" -> "48m",
      "spark.serializer" -> "org.apache.spark.serializer.KryoSerializer",
      "spark.kryoserializer.buffer.max" -> "1g",
      "spark.shuffle.file.buffer" -> "32k",
      "spark.mongodb.input.uri" -> mongoInputUri,
      "spark.mongodb.output.uri" -> mongoOutputUri
    ))

    val spark = SparkSession
      .builder
      .config(conf)
      .appName("ComputeOpinions")
      .getOrCreate()

    import spark.implicits._

    val events = MongoSpark.load(spark)
    val mentionsUri = "mongodb://" + mongoHost + "/" + schema + ".mentions?readPreference=nearest"
    val mentions = spark.sparkContext.
      loadFromMongoDB(ReadConfig(Map("uri" -> mentionsUri))).
      toDF()

    val mentions_events = mentions.join(events, Seq("GlobalEventID"))

    val opinions = mentions_events
      .groupBy($"MentionDate".alias("day"),$"CountryCode".alias("country"))
      .agg(count(lit(1)).alias("Num_Mentions"),avg("MentionDocTone").alias("AvgTone"))

    MongoSpark.save(opinions.write.option("collection", "opinions").mode("overwrite"))

  }
}
