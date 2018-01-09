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

Formater la partition
```
sudo mke2fs -t ext4 /dev/xvdb1
```

Monter la partition automatiquement
```
sudo mkdir /mnt/mongo_data
sudo vim /etc/fstab
```

Dans le ficher, ajouter la ligne :
```
/dev/xvdb1 /mnt/mongo_data ext4 defaults,nofail 0 2
```

## Installation de Mongo
Ajout des dépôts
```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list
sudo apt-get update
sudo apt-get install -y mongodb-org
```
