name := "compute-opinions"

version := "1.0"

scalaVersion := "2.11.11"

organization := "paristech"

libraryDependencies ++= Seq(
  // Spark dependencies. Marked as provided because they must not be included in the uberjar
  "org.apache.spark" %% "spark-core" % "2.2.0" % "provided",
  "org.apache.spark" %% "spark-sql" % "2.2.0" % "provided",
  "org.apache.spark" %% "spark-mllib" % "2.2.0" % "provided",

  // Third-party libraries
  "org.apache.hadoop" % "hadoop-aws" % "2.6.0" % "provided",
  "com.amazonaws" % "aws-java-sdk" % "1.7.4" % "provided",
  "org.scala-lang" % "scala-reflect" % "2.11" % "provided", // To run Spark in IntelliJ
  //"com.github.scopt" %% "scopt" % "3.4.0"        // to parse options given to the jar in the spark-submit

  // Mongo connector
  "org.mongodb.spark" %% "mongo-spark-connector" % "2.2.1"
)
/*libraryDependencies += "net.sourceforge.f2j" % "arpack_combined_all" % "0.1"
libraryDependencies += "com.github.fommil.netlib" % "netlib-native_ref-linux-x86_64" % "1.1" classifier "natives"
libraryDependencies += "com.github.fommil.netlib" % "netlib-native_system-linux-x86_64" % "1.1" classifier "natives"
*/
// https://mvnrepository.com/artifact/com.github.fommil.netlib/all
libraryDependencies += "com.github.fommil.netlib" % "all" % "1.1.2" pomOnly()

// A special option to exclude Scala itself form our assembly JAR, since Spark already bundles Scala.
assemblyOption in assembly := (assemblyOption in assembly).value.copy(includeScala = false)

// Disable parallel execution because of spark-testing-base
parallelExecution in Test := false

// Configure the build to publish the assembly JAR
artifact in (Compile, assembly) := {
  val art = (artifact in (Compile, assembly)).value
  art.copy(`classifier` = Some("assembly"))
}

addArtifact(artifact in (Compile, assembly), assembly)

/*
IntelliJ IDEA uses "scalastyle_config.xml", where as scalastyle-sbt-plugin uses "scalastyle-config.xml".
The following line forces scalastyle-sbt-plugin to use "scalastyle_config.xml"
*/
scalastyleConfig := baseDirectory.value / "scalastyle_config.xml"
