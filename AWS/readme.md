# Mongo
## Lancement des serveurs
* Créer un script aws_env.sh
    * Lui donner les droits d'exécution ```chmod 744 aws_env.sh ```
    * ajouter le header ```#!/bin/bash```
    * ajouter la ligne ```export AWS_KEY_PATH=/chemin/vers/clé/AWS```. Ex : ```export AWS_KEY_PATH=/home/toto/Documents/AWS/gdeltKeyPair.pem```

Lancer le script ```start_mongo.sh``` depuis ce répertoire.
Lancer le script ```start_mongo2.sh``` pour lancer le cluster plus puissant.

## Arrêt des serveurs
Lancer le script ```stop_mongo.sh``` depuis ce répertoire.
Lancer le script ```stop_mongo2.sh``` pour éteindre le cluster plus puissance.
