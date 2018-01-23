# compute-opinions
## Description
Cette application extrait les mentions associées à des événements dont l'émetteur est le gouvernement américain, les agrège par date et par pays (pays du média ayant publié cette mention), et calcule le nombre de mentions et la moyenne du ton des mentions.

Les opinions ainsi produites sont stockées de la manière suivante :
* day : date des mentions (au format ISODate Mongo)
* country : pays (code FIPS du pays)
* Num_Mentions : nombre de mentions pour ce jour et ce pays
* AvgTone : ton moyen des mentions pour ce jour et ce pays

## Compilation
```
sbt assembly
```

## Lancement
Cette application prend les arguments suivants :

* le nom du schema où récupérer et insérer les données
* le nom de l'hôte du router Mongo


Lancement via spark-submit :
```
spark-submit --deploy-mode cluster --master yarn --class com.sparkProject.ComputeMentions /path/to/compute-opinions-assembly-1.0.jar schema_name
```


Lancement sur un cluster AWS EMR :
```
noglob aws emr add-steps --cluster-id j-XXXXXXXXXXXX --steps Type=spark,Name=ComputeOpinions,Args=--deploy-mode,cluster,--master,yarn,--class,com.sparkProject.ComputeOpinions,s3://gdelt-spark/compute-opinions-assembly-1.0.jar,schema_name,ActionOnFailure=CONTINUE
```
