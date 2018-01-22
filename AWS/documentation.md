# Récupération des fichiers sources
```
aws s3 sync s3://telecom.gdelt s3://gdelt-sources
```

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
      { _id: 0, host: "ip-172-31-12-94.ec2.internal:27017" }
   ]
} )
```

#### Avec réplication
```
mongo xxx:27017
rs.initiate( {
   _id: "configRs",
   configsvr: true,
   members: [
      { _id: 0, host: "ip-172-31-34-137.ec2.internal:27017" },
      { _id: 1, host: "ip-172-31-38-129.ec2.internal:27017" },
      { _id: 2, host: "ip-172-31-43-31.ec2.internal:27017" }
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

#### Avec réplication
```
mongo xxx:27017
rs.initiate( {
   _id : "rs0",
   members: [
      { _id : 0, host : "ip-172-31-35-85.ec2.internal:27017" },
      { _id : 1, host : "ip-172-31-40-70.ec2.internal:27017" },
      { _id : 2, host : "ip-172-31-42-213.ec2.internal:27017" }
    ]
})
```

```
mongo xxx:27017
rs.initiate( {
   _id : "rs1",
   members: [
      { _id : 0, host : "ip-172-31-37-210.ec2.internal:27017" },
      { _id : 1, host : "ip-172-31-42-40.ec2.internal:27017" },
      { _id : 2, host : "ip-172-31-44-187.ec2.internal:27017" }
    ]
})
```

```
mongo xxx:27017
rs.initiate( {
   _id : "rs2",
   members: [
      { _id : 0, host : "ip-172-31-36-7.ec2.internal:27017" },
      { _id : 1, host : "ip-172-31-45-88.ec2.internal:27017" },
      { _id : 2, host : "ip-172-31-46-201.ec2.internal:27017" }
    ]
})
```

## Déclaration des shards dans mongos
```
mongo yyy:27017
sh.addShard( "rs0/ip-172-31-35-85.ec2.internal:27017,ip-172-31-40-70.ec2.internal:27017,ip-172-31-42-213.ec2.internal:27017")
sh.addShard( "rs1/ip-172-31-37-210.ec2.internal:27017,ip-172-31-42-40.ec2.internal:27017,ip-172-31-44-187.ec2.internal:27017")
sh.addShard( "rs2/ip-172-31-36-7.ec2.internal:27017,ip-172-31-45-88.ec2.internal:27017,ip-172-31-46-201.ec2.internal:27017")
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
sh.enableSharding( "year" )
```

Créer des index et sharder les collections
```
use year;
db.events.createIndex({GlobalEventID:"hashed"});
sh.shardCollection("year.events",{GlobalEventID:"hashed"});
db.mentions.createIndex({MentionDate:"hashed"});
db.mentions.createIndex({MentionDate:1});
sh.shardCollection("year.mentions",{MentionDate:"hashed"});
db.opinions.createIndex({day:"hashed"});
db.opinions.createIndex({day:1});
sh.shardCollection("year.opinions",{day:"hashed"});
```


# Chargement des données d'événements et de mentions dans Mongo
Les sources du projet Spark utilisé sont [ici](https://github.com/cnguyentelecom/NoSQLProject/tree/master/data_import/spark-data-import)
## Test en local
 Lancement d'un spark shell permettant de se connecter à S3 et à Mongo
```
spark-shell --packages org.mongodb.spark:mongo-spark-connector_2.11:2.2.0,org.apache.hadoop:hadoop-aws:2.7.5 --conf "spark.mongodb.input.uri=mongodb://ec2-34-200-240-206.compute-1.amazonaws.com/test_CNG.test1?readPreference=primaryPreferred" --conf "spark.mongodb.output.uri=mongodb://ec2-34-200-240-206.compute-1.amazonaws.com/test_CNG.test1"
```


## Utilisation de AWS EMR
### Création d'un EMR
Cette ligne de commande lance un Cluster avec les caractéristiques suivantes :

* Applications
    * Spark
    * Hadoop
    * Ganglia (pour la supervision)
* Infrastructure
    * 1 maître sur une instance m1.large
    * 2 esclave sur une instance m1.large

```
aws emr create-cluster --applications Name=Ganglia Name=Spark Name=Hadoop --ec2-attributes '{"KeyName":"gdeltKeyPair","InstanceProfile":"EMR_EC2_DefaultRole","SubnetId":"subnet-4087c224","EmrManagedSlaveSecurityGroup":"sg-dc1817a9","EmrManagedMasterSecurityGroup":"sg-1e2d226b"}' --service-role EMR_DefaultRole --enable-debugging --release-label emr-5.11.0 --log-uri 's3n://aws-logs-373738665477-us-east-1/elasticmapreduce/' --name 'Mon cluster2' --instance-groups '[{"InstanceCount":1,"InstanceGroupType":"MASTER","InstanceType":"m1.large","Name":"Master Instance Group"},{"InstanceCount":2,"InstanceGroupType":"CORE","InstanceType":"m1.large","Name":"Core Instance Group"}]' --configurations '[{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"},"Configurations":[]}]' --region us-east-1
```

Cette ligne de commande lance un Cluster avec les caractéristiques suivantes :

* Applications
    * Spark
    * Hadoop
    * Ganglia (pour la supervision)
* Infrastructure
    * 1 maître sur une instance m1.large
    * 4 esclave sur une instance m1.large

```
aws emr create-cluster --applications Name=Ganglia Name=Spark Name=Hadoop --ec2-attributes '{"KeyName":"gdeltKeyPair","InstanceProfile":"EMR_EC2_DefaultRole","SubnetId":"subnet-9842f1c5","EmrManagedSlaveSecurityGroup":"sg-dc1817a9","EmrManagedMasterSecurityGroup":"sg-1e2d226b"}' --service-role EMR_DefaultRole --enable-debugging --release-label emr-5.11.0 --log-uri 's3n://aws-logs-373738665477-us-east-1/elasticmapreduce/' --name 'Mon cluster3' --instance-groups '[{"InstanceCount":1,"InstanceGroupType":"MASTER","InstanceType":"m1.large","Name":"Master Instance Group"},{"InstanceCount":4,"InstanceGroupType":"CORE","InstanceType":"m1.large","Name":"Core Instance Group"}]' --configurations '[{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"},"Configurations":[]}]' --region us-east-1
```

Mise à jour du nombre max de fichiers ouverts sur chaque serveur :
```
cat /proc/sys/fs/file-max
sudo sysctl -w fs.file-max=1000000
cat /proc/sys/fs/file-max
```
Finalement, cette solution n'a pas été mise en oeuvre, au profit d'un lotissement du chargement des données

### Upload d'un jar (contenant un job Spark) sur AWS
```
aws s3 cp monjar.jar s3://mon_bucket/monjar.jar
```

### Lancement des jobs
Lancement du chargement des évents
```
noglob aws emr add-steps --cluster-id j-O0YI5DXB2YBX --steps Type=spark,Name=LoadEvents,Args=--deploy-mode,cluster,--master,yarn,--class,com.sparkProject.LoadEvents,s3://gdelt-spark/spark-data-import-assembly-1.6.jar,2017*,year,ip-172-31-41-137.ec2.internal,ActionOnFailure=CONTINUE
```

Lancement du chargement des mentions
```
noglob aws emr add-steps --cluster-id j-O0YI5DXB2YBX --steps Type=spark,Name=LoadMentions,Args=--deploy-mode,cluster,--master,yarn,--class,com.sparkProject.LoadMentions,s3://gdelt-spark/spark-data-import-assembly-1.6.jar,2017*,year,ip-172-31-41-137.ec2.internal,ActionOnFailure=CONTINUE
```

Lancement de la création de la table opinions
```
noglob aws emr add-steps --cluster-id j-3EYKAI9LQ6E84 --steps Type=spark,Name=ComputeOpinions,Args=--deploy-mode,cluster,--master,yarn,--class,com.sparkProject.ComputeOpinions,s3://gdelt-spark/compute-opinions-assembly-1.1.jar,year,ip-172-31-41-137.ec2.internal,ActionOnFailure=CONTINUE
```

# Cassandra on AWS (pas mis en oeuvre au final)
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
