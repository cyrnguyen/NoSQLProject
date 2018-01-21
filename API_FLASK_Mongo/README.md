# Requête de l'Api

1. Si nécessaire configurer dans le fichier application.py :  
L'adresse du server mongo  
Le nom de la base de données Mongo  
Le nom de la collection

* Requête sur l'API avec la method GET :
utiliser l'adresse du server de l'application flask et ajouter en fin d'url :  
`/result?start="VALEUR"&end="VALEUR"`  de la forme YYYYMMDD
Par exemple :  
http://flask-env.6tw4uhsaid.us-east-1.elasticbeanstalk.com/result?start=20100101&end=20101231

Le nom des champs retournés sont :  
Avg
Country  
Day  
Mention

En fonction du choix d'url `/result` ou `/result2`, le format du JSON retourné sera différent. Pour le premier le code pays sera retourné en 3 lettres `FRA` pour le second il sera retourné un code en 2 lettres `FR`.

`/result`:  
![alt text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png "result")

`/result2`:
![alt text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png "result2")
