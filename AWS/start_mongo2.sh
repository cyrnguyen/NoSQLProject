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
aws ec2 start-instances --instance-ids $MONGO2_RS0_INSTANCE1_ID $MONGO2_RS0_INSTANCE2_ID $MONGO2_RS0_INSTANCE3_ID $MONGO2_RS1_INSTANCE1_ID $MONGO2_RS1_INSTANCE2_ID $MONGO2_RS1_INSTANCE3_ID $MONGO2_CONFIGRS_INSTANCE1_ID $MONGO2_CONFIGRS_INSTANCE2_ID $MONGO2_CONFIGRS_INSTANCE3_ID $MONGO2_ROUTER_INSTANCE_ID \
# $MONGO2_RS2_INSTANCE1_ID $MONGO2_RS2_INSTANCE2_ID $MONGO2_RS2_INSTANCE3_ID
echo "Instances starting..."

# Wait for the instances to be running
aws ec2 wait instance-running --instance-ids $MONGO2_RS0_INSTANCE1_ID $MONGO2_RS0_INSTANCE2_ID $MONGO2_RS0_INSTANCE3_ID $MONGO2_RS1_INSTANCE1_ID $MONGO2_RS1_INSTANCE2_ID $MONGO2_RS1_INSTANCE3_ID $MONGO2_CONFIGRS_INSTANCE1_ID $MONGO2_CONFIGRS_INSTANCE2_ID $MONGO2_CONFIGRS_INSTANCE3_ID $MONGO2_ROUTER_INSTANCE_ID \
# $MONGO2_RS2_INSTANCE1_ID $MONGO2_RS2_INSTANCE2_ID $MONGO2_RS2_INSTANCE3_ID

# Wait for the instances to be ready to accecpt ssh connections
sleep 10

echo "Instances running"

# Get instances hostname
MONGO2_RS0_1_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS0_INSTANCE1_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_RS0_2_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS0_INSTANCE2_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_RS0_3_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS0_INSTANCE3_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_RS1_1_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS1_INSTANCE1_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_RS1_2_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS1_INSTANCE2_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_RS1_3_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS1_INSTANCE3_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
# MONGO2_RS2_1_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS2_INSTANCE1_ID --output json |\
# jq -r '.Reservations[].Instances[].PublicDnsName')
# MONGO2_RS2_2_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS2_INSTANCE2_ID --output json |\
# jq -r '.Reservations[].Instances[].PublicDnsName')
# MONGO2_RS2_3_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_RS2_INSTANCE3_ID --output json |\
# jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_CONFIGRS_1_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_CONFIGRS_INSTANCE1_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_CONFIGRS_2_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_CONFIGRS_INSTANCE2_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_CONFIGRS_3_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_CONFIGRS_INSTANCE3_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')
MONGO2_ROUTER_DNS_NAME=$(aws ec2 describe-instances --instance-ids $MONGO2_ROUTER_INSTANCE_ID --output json |\
jq -r '.Reservations[].Instances[].PublicDnsName')


# start MONGO servers
echo "Starting mongo servers..."
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_CONFIGRS_1_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet configRs --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --configsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_CONFIGRS_2_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet configRs --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --configsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_CONFIGRS_3_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet configRs --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --configsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS0_1_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs0 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS0_2_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs0 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS0_3_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs0 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS1_1_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs1 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS1_2_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs1 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS1_3_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs1 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
# ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS2_1_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs2 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
# ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS2_2_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs2 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
# ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_RS2_3_DNS_NAME -o StrictHostKeyChecking=no "mongod --replSet rs2 --fork --logpath /mnt/mongo_data/mongo.log --dbpath /mnt/mongo_data/mongo --shardsvr --port 27017 --bind_ip_all"
ssh -i $AWS_KEY_PATH ubuntu@$MONGO2_ROUTER_DNS_NAME -o StrictHostKeyChecking=no "mongos --fork --logpath /mnt/mongo_data/mongo.log --configdb configRs/$MONGO2_CONFIGRS_1_PRIVATE_DNS:27017,$MONGO2_CONFIGRS_2_PRIVATE_DNS:27017,$MONGO2_CONFIGRS_3_PRIVATE_DNS:27017 --port 27017 --bind_ip_all"
echo "Mongo servers started"
