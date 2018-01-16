#!/bin/bash

# Get AWS instance ids
mongo_env_script=./mongo_env.sh
if ! type "$mongo_env_script" > /dev/null; then
  echo "Command $mongo_env_script not found : please run this scrip from its directory"
  exit 1
fi
source $mongo_env_script

# get AWS_KEY_PATH
set_env_script=./aws_env.sh
if ! type "$set_env_script" > /dev/null; then
  echo "Command $set_env_script not found : launch this script from its directory or add $set_env_script in your current path containing export AWS_KEY_PATH=the_path_to_your_aws_key(gdeltKeyPair.pem)"
  exit 1
fi
source $set_env_script
if [ ! -f $AWS_KEY_PATH ]; then
    echo "$AWS_KEY_PATH not found. Please fix aws_env.sh"
fi
if [ ! -f $MONGO_PATH/mongo ]; then
    echo "$MONGO_PATH/mongo not found. Please fix aws_env.sh"
fi

# Get instances hostname
MONGO_ROUTER_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO_ROUTER_INSTANCE_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')

$MONGO_PATH/mongo $MONGO_ROUTER_DNS_NAME:27017
