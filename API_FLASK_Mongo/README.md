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


En fonction du choix d'url `/result` ou `/result2`, le format du JSON retourné sera différent. Pour le premier le code pays sera retourné en 3 lettres `FRA` pour le second il sera retourné un code en 2 lettres `FR`.

`/result`:  
![alt text](https://github.com/cnguyentelecom/NoSQLProject/blob/master/API_FLASK_Mongo/result_maxence_.png "result")

Le nom des champs retournés sont :  
Avg
Country  
Day  
Mention

`/result2`:
![alt text](https://github.com/cnguyentelecom/NoSQLProject/blob/master/API_FLASK_Mongo/result2_antoine.png "result2")

Ici un seul document JSON est retourné. Il contient la structure
Frequency:  
	Date:  
		Pays:Valeur  

Count:  
	Date:  
		Pays:Valeur  
