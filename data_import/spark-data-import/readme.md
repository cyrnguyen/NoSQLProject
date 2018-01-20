# spark-data-import
## Description
Cette application extrait des données GDELT depuis des fichiers zip dans s3 (events et mentions), les filtres et les insère dans des collections MongoDB, dans les collections "events" et "mentions".

### Chargement des données d'événement
Pour répondre aux besoins de notre projet, lors du chargement des données d'événement, seules les données respectant les conditions suivantes sont insérées en base :
* **Actor1Code** = "USAGOV"
* ou **Actor1Code** = "GOV" & **Actor1CountryCode** = "USA"

Les colonnes en base après insertion sont :
* **GlobalEventID**
* **Day** : le jour de l'événement
* **Actor1Code**
* **Actor1Name**
* **Actor1CountryCode**
* **Actor1Geo_CountryCode**
* **Actor2Code**
* **Actor2CountryCode**
* **Actor2Geo_CountryCode**

### Chargement des données de mention
Pour répondre aux besoins de notre projet, toutes les mentions de type WEB sont insérées dans la base avec le pays correspondant au média Web qui a émis cette mention.

Les colonnes en base après insertion sont :
* **GlobalEventID**
* **MentionDate**
* **MentionIdentifier**
* **MentionDocTone**
* **CountryCode**

## Compilation
```
sbt assembly
```

## Lancement
Cette application prend les arguments suivants :

* format du fichier à traiter (que ce soit event ou mention). Par défaut, tous les fichiers sont traités. ex :
    * "2017*"" pour prendre tous les fichiers de 2017
    * "20170125*" pour prendre tous les fichiers du 25/01/2017
* le nom du schema où insérer les données


Lancement via spark-submit :

* Chargement des events
```
spark-submit --deploy-mode cluster --master yarn --class com.sparkProject.LoadEvents /path/to/spark-data-import-assembly-1.0.jar
```

* Chargement des mentions
```
spark-submit --deploy-mode cluster --master yarn --class com.sparkProject.LoadMentions /path/to/spark-data-import-assembly-1.0.jar
```

Lancement sur un cluster AWS EMR :
* Chargement des events
```
noglob aws emr add-steps --cluster-id j-XXXXXXXXXXXX --steps Type=spark,Name=LoadEvents,Args=--deploy-mode,cluster,--master,yarn,--class,com.sparkProject.LoadEvents,s3://gdelt-spark/spark-data-import-assembly-1.0.jar,2017*,ActionOnFailure=CONTINUE
```

* Chargement des mentions
```
noglob aws emr add-steps --cluster-id j-XXXXXXXXXXXX --steps Type=spark,Name=LoadMentions,Args=--deploy-mode,cluster,--master,yarn,--class,com.sparkProject.LoadMentions,s3://gdelt-spark/spark-data-import-assembly-1.0.jar,2017*,ActionOnFailure=CONTINUE
```
