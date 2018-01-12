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
    echo "key $AWS_KEY_PATH not found. Please fix aws_env.sh"
fi

# Start instances
echo "Starting instances"
aws ec2 start-instances --instance-ids $MONGO_RS0_INSTANCE_ID $MONGO_RS1_INSTANCE_ID $MONGO_CONFIGRS_INSTANCE_ID $MONGO_ROUTER_INSTANCE_ID
echo "Instances starting..."

# Wait for the instances to be running
aws ec2 wait instance-running --instance-ids $MONGO_RS0_INSTANCE_ID $MONGO_RS1_INSTANCE_ID $MONGO_CONFIGRS_INSTANCE_ID $MONGO_ROUTER_INSTANCE_ID

# Wait for the instances to be ready to accecpt ssh connections
sleep 30

echo "Instances running"

# Get instances hostname
MONGO_RS0_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO_RS0_INSTANCE_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO_RS1_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO_RS1_INSTANCE_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO_CONFIGRS_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO_CONFIGRS_INSTANCE_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO_ROUTER_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO_ROUTER_INSTANCE_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')


# start MONGO servers
echo "Starting mongo servers..."
ssh -i $AWS_KEY_PATH ubuntu@$MONGO_CONFIGRS_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet configRs --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --configsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO_RS0_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs0 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO_RS1_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs1 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO_ROUTER_DNS_NAME -o StrictHostKeyChecking=no "mongos --fork --logpath /mnt/mongo_data/mongo.log --configdb configRs/$MONGO_CONFIGRS_PRIVATE_DNS:27017 --port 27017 --bind_ip_all"
echo "Mongo servers started"
