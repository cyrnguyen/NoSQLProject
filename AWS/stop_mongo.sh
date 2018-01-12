#!/bin/bash

# Get AWS instance ids
mongo_env_script=./mongo_env.sh
if ! type "$mongo_env_script" > /dev/null; then
  echo "Command $mongo_env_script not found : please run this scrip from its directory"
  exit 1
fi
source $mongo_env_script

# Stop instances
aws ec2 stop-instances --instance-ids $MONGO_CONFIGRS_INSTANCE_ID $MONGO_RS0_INSTANCE_ID $MONGO_RS1_INSTANCE_ID $MONGO_ROUTER_INSTANCE_ID

echo "Intances stopping..."
