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
