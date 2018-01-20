#!/bin/bash

# This script needs to be located where the build.sbt file is.
# It takes as optional parameter the path of the spark directory. If no path is specified
# it will look for the spark directory in $HOME.
#
# Example:  ./build_and_submit.sh Maxime.local /Users/maxime/spark-2.2.0-bin-hadoop2.7
#
# Paramters:
#  - $1 : job to execute
#  - $2 : [optional] IP of the spark master
#  - $3 : [optional] path to spark directory
set -o pipefail

echo -e "\n --- building .jar --- \n"

sbt assembly || { echo 'Build failed' ; exit 1; }

echo -e "\n --- spark-submit --- \n"

path_to_spark="/softwares/spark"
master_ip=""

if [ -n "$3" ]; then master_ip="--master spark://$3:7077"; fi
if [ -n "$2" ]; then path_to_spark=$2; fi

$path_to_spark/bin/spark-submit --conf spark.eventLog.enabled=true --conf spark.eventLog.dir="/tmp" --driver-memory 10g --class com.sparkProject.$1 $master_ip target/scala-2.11/*
