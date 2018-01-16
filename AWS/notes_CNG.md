# Récupération des fichiers sources
```
aws s3 sync s3://telecom.gdelt s3://gdelt-sources
```

# Cassandra on AWS
## Ressources
* [White paper AWS](https://d0.awsstatic.com/whitepapers/Cassandra_on_AWS.pdf)
* [Article de blog qui décrit une install automatisée d'un cluster Cassandra dans AWS](https://techblog.bozho.net/setting-cassandra-cluster-aws/)

## Réseau
Possibilité de configurer une ENI (Elastic Network Interface) qui définit une IP fixe notamment pour le(s) noeud maître qui sera déclaré comme seed node dans toutes les conf Cassandra de tous les noeuds.

## Stockage
2 posiibilités :

* EBS (Elastic Block Store) : Consiste à monter des volumes qui sont créés à part
* Intance Store : Utiliser des instances AWS qui ont leur propre stockage

Je pense qu'on peut partir sur l'utilisation d'EBS car cela permet d'éteindre les instances et de garder les volumes avec les données.

# Mongo on AWS
## Procédure de création de la VM
Créer une instance t2.micro avec un disque de 8Go pour le système et un disque de 100Go pour les données

AMI : ami-aa2ea6d0)

Création de la partition
```
sudo fdisk /dev/xvdb
n (new partition)
p (primary)
1
enter
enter
w (write changes)
```

Formater la partition (le format XFS est conseillé par Mongo)
```
sudo mkfs.xfs /dev/xvdb1
```

Monter la partition automatiquement
```
sudo mkdir /mnt/mongo_data
sudo mkdir /mnt/mongo_data/mongo
sudo vim /etc/fstab
```

Dans le ficher, ajouter la ligne :
```
/dev/xvdb1 /mnt/mongo_data xfs defaults,nofail 0 2
```

Monter la partition
```
sudo mount -a
```

Changer le propriétaire du dossier
```
sudo chown -R ubuntu: /mnt/mongo_data
```

## Installation Mongo
Installation de paquets préalables
```
sudo apt-get update
sudo apt-get -y install sysfsutils
sudo vim /etc/sysfs.conf
```

Ajouter les lignes
```
kernel/mm/transparent_hugepage/enabled = never
kernel/mm/transparent_hugepage/defrag = never
```

Ajout des dépôts et installation
```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list
sudo apt-get update
sudo apt-get -y install -y mongodb-org
```

***RQ***
Le serveur Mongos n'a besoin d'un disque de stockage que pour les logs, on peut lui fournir un EBS plus petit.

## Création d'un AMI
Une fois qu'un machine est crée, on peut créer une AMI à partir de cette machine depuis la console EC2 :

* Eteindre la machine (stop)
* Depuis l'onglet Instances
    * Sélectionner l'instance
    * Menu Action -> Image -> Créer l'image
    * Donner un nom et créer l'image

Lancer l'image : depuis l'onglet AMI, sélectionner l'AMI à lancer et cliquer sur Lancer puis suivre le guide (il est possible de lancer plusieurs instances de la même image, ce qui crée autant de fois les EBS et crée plusieurs intances).

## Configuration du cluster

### Configuration du serveur de configuration
créer un répertoire ```/mnt/mongo_data/mongo-config``` sur le serveur de config

```
mongo xxx:27017
rs.initiate( {
   _id: "configRs",
   configsvr: true,
   members: [
      { _id: 0, host: "ip-172-31-12-94.ec2.internal:27019" }
   ]
} )
```

### Création des shards
```
mongo xxx:27017
rs.initiate( {
   _id : "rs0",
   members: [ { _id : 0, host : "ip-172-31-14-153.ec2.internal:27017" }
    ]
})
```

```
mongo yyy:27017
rs.initiate( {
   _id : "rs1",
   members: [ { _id : 0, host : "ip-172-31-7-24.ec2.internal:27017" }
    ]
})
```

## Déclaration des shards dans mongos
```
mongo yyy:27017
sh.addShard( "rs0/ip-172-31-14-153.ec2.internal:27017")
sh.addShard( "rs1/ip-172-31-7-24.ec2.internal:27017")
```

## Lancement des serveurs
* Créer un script aws_env.sh
    * Lui donner les droits d'exécution ```chmod 744 aws_env.sh ```
    * ajouter le header ```#!/bin/bash```
    * ajouter la ligne ```export AWS_KEY_PATH=/chemin/vers/clé/AWS```. Ex : ```export AWS_KEY_PATH=/home/toto/Documents/AWS/gdeltKeyPair.pem```

Lancer le script start_mongo.sh

## Arrêt des serveurs
Lancer le script stop_mongo.sh

## Créer une collection shardée
Activer le sharding sur le schéma :
```
sh.enableSharding( "test_CNG" )
```

Créer un index et sharder la collection
```
use test_CNG;
db.test1.createIndex({GlobalEventID:"hashed"});
sh.shardCollection("test_CNG.test1",{GlobalEventID:"hashed"});
```

# Connection Spark-MongoDB
https://stackoverflow.com/questions/38872049/spark-dataframe-to-mongodb-document-insertion-issue

https://github.com/manuparra/starting-bigdata-aws#connecting-to-mongodb-from-spark

Example enron emails

https://github.com/mongodb/mongo-hadoop/wiki/Enron-Emails-Example

Doc Mongo d'écriture de Dataframe dans MOngo depuis Spark : https://docs.mongodb.com/spark-connector/current/scala/datasets-and-sql/

DOc mongo de conf : https://docs.mongodb.com/spark-connector/current/scala-api/



# S3
s3://gdelt-sources/

# spark
```
spark-shell --packages org.mongodb.spark:mongo-spark-connector_2.11:2.2.0 --conf "spark.mongodb.input.uri=mongodb://ec2-52-73-183-155.compute-1.amazonaws.com/test_CNG.test1?readPreference=primaryPreferred" --conf "spark.mongodb.output.uri=mongodb://ec2-52-73-183-155.compute-1.amazonaws.com/test_CNG.test1"
```
```
spark-submit --deploy-mode cluster --master yarn --num-executors 3 --executor-cores 2 --executor-memory 2g --class com.sparkProject.DataImport /tmp/spark-data-import-assembly-1.0.jar
```


```
aws emr add-steps --cluster-id j-34G5YT4JRYK5O --steps Type=spark,Name=SparkWordCountApp,Args=[--deploy-mode,cluster,--master,yarn,--conf,spark.yarn.submit.waitAppCompletion=false,--num-executors,3,--executor-cores,3,--executor-memory,2g,--class,com.sparkProject.DataImport,/tmp/spark-data-import-assembly-1.0.jar],ActionOnFailure=CONTINUE
```

# EMR
## Création et lancement d'une copie dans HDFS
```
aws emr create-cluster --applications Name=Ganglia Name=Spark --ec2-attributes '{"KeyName":"gdeltKeyPair","InstanceProfile":"EMR_EC2_DefaultRole","SubnetId":"subnet-4087c224","EmrManagedSlaveSecurityGroup":"sg-dc1817a9","EmrManagedMasterSecurityGroup":"sg-1e2d226b"}' --service-role EMR_DefaultRole --enable-debugging --release-label emr-5.11.0 --log-uri 's3n://aws-logs-373738665477-us-east-1/elasticmapreduce/' --name 'Mon cluster2' --instance-groups '[{"InstanceCount":1,"InstanceGroupType":"MASTER","InstanceType":"m1.large","Name":"Master Instance Group"},{"InstanceCount":2,"InstanceGroupType":"CORE","InstanceType":"m1.large","Name":"Core Instance Group"}]' --configurations '[{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"},"Configurations":[]}]' --region us-east-1 --steps Type=CUSTOM_JAR,Name="S3DistCp step",ActionOnFailure=CONTINUE,"Jar":"command-runner.jar",Args=["s3-dist-cp","--s3Endpoint=s3.amazonaws.com","--src=s3://gdelt-sources/","--dest=hdfs:///events","--srcPattern=20170125[0-9]*.export.CSV.zip"]
```

```
aws emr create-cluster --name "Spark cluster with Ganglia" --release-label emr-5.11.0 \
--applications Name=Spark Name=Ganglia --ec2-attributes KeyName=myKey --instance-type m3.xlarge --instance-count 3 --use-default-roles
```
