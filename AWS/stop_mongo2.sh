#!/bin/bash

# Get AWS instance ids
mongo_env_script=./mongo_env.sh
if ! type "$mongo_env_script" > /dev/null; then
  echo "Command $mongo_env_script not found : please run this scrip from its directory"
  exit 1
fi
source $mongo_env_script

# Stop instances
aws ec2 stop-instances --instance-ids $MONGO2_RS0_INSTANCE1_ID $MONGO2_RS0_INSTANCE2_ID $MONGO2_RS0_INSTANCE3_ID $MONGO2_RS1_INSTANCE1_ID $MONGO2_RS1_INSTANCE2_ID $MONGO2_RS1_INSTANCE3_ID $MONGO2_CONFIGRS_INSTANCE1_ID $MONGO2_CONFIGRS_INSTANCE2_ID $MONGO2_CONFIGRS_INSTANCE3_ID $MONGO2_ROUTER_INSTANCE_ID

echo "Intances stopping..."
